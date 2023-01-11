defmodule Device.SoilMoistureSensor.Worker do
  @moduledoc """
  Soil moisture sensor genserver: accepts de-framed measurements
  from soil moisture sensors
  """
  @doc "Worker managing a soil moisture sensor"
  use GenServer, restart: :transient
  require Logger

  @config_env Application.compile_env(:watering_can, :config_env)

  @typedoc """
  Measurement from a soil moisture sensor
  """
  @type sms_measurement() :: %{
          required(:battery_pct) => non_neg_integer(),
          required(:moisture_pct) => non_neg_integer()
        }

  @typedoc """
  Result from processing moisture sensor message
  """
  @type uart_config() :: %{
          required(:type) => Comms.Uart.WateringCanFramer,
          required(:uart_name) => String.t()
        }
  @type raw_framer_config() :: %{
          required(:type) => :raw_framer,
          required(:ordinal) => number()
        }

  @type subprocess_config() :: %{
          required(:type) => :subprocess_framer
        }

  @typedoc """
  The type stored in the soil moisture sensor db model's config member
  """
  @type config_t() :: uart_config() | raw_framer_config() | subprocess_config()
  defmodule State do
    @moduledoc false
    @keys ~w/sms/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            sms: Device.SoilMoistureSensor.Worker.config_t()
          }
  end

  ##############################
  # API
  ##############################

  @doc """
  Start and link the process
  ## Parameters
  - `sms` The soil moisture sensor configuration
  ## Returns
  - `GenServer.on_start()`
  """
  @spec start_link(config_t()) :: GenServer.on_start()
  def start_link(sms), do: GenServer.start_link(__MODULE__, sms, name: {:via, Registry, {WateringCan.Registry, {__MODULE__, sms}}})

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  @spec init(config_t()) :: {:ok, State.t()}
  def init(sms) do
    Logger.info("Starting", sms: sms)
    {:ok, start_sms(%State{sms: sms})}
  end

  @impl GenServer
  def handle_info({:nerves_uart, _serial_port_id, data} = _msg, state) do
    # nerves uart will de-frame mesesages before delivering them:
    {updated_state, _result} = do_handle_sms_message(state, data)
    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_info({Integration.SmsSimManager, :input, data}, state) do
    # sim manager will de-frame mesesages before delivering them:
    {updated_state, _result} = do_handle_sms_message(state, data)
    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_call({:raw_framer, data} = _msg, _from, state) do
    # raw framer will de-frame mesesages before delivering them:
    {updated_state, _result} = do_handle_sms_message(state, data)
    {:reply, :ok, updated_state}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec start_sms(State.t()) :: State.t()
  @doc false
  def start_sms(state)

  def start_sms(%{sms: _sms = %{type: _framer = :raw_framer}} = state) do
    state
  end

  if :integration == @config_env do
    def start_sms(%{sms: _sms = %{type: :subprocess_framer}} = state) do
      :ok = Integration.SmsSimManager.start_sim(Application.get_env(:watering_can, :sms_simulator, nil))
      state
    end
  end

  def start_sms(%{sms: _sms = %{type: framer = Comms.Uart.WateringCanFramer, uart_name: uart_name}} = state) do
    {:ok, uart} = Db.Models.Uart.first(name: uart_name)

    # nerves uart will de-frame mesesages before delivering them:
    :ok =
      Nerves.UART.open(self(), uart_name,
        active: true,
        speed: uart.speed,
        data_bits: uart.data_bits,
        stop_bits: uart.stop_bits,
        parity: uart.parity,
        flow_control: uart.flow_control,
        rx_framing_timeout: 0,
        framing: framer
      )

    state
  end

  @spec do_handle_sms_message(State.t(), binary()) :: {State.t(), {:ok, sms_measurement()}} | {State.t(), {:error, any()}}
  @doc false
  def do_handle_sms_message(state, data) do
    :telemetry.span([__MODULE__, :handle_sms_frame], %{state: state, data: data}, fn ->
      case data do
        <<battery_pct::integer-little-unsigned-size(8), moisture_pct::integer-little-unsigned-size(8)>> ->
          # TODO: process the measurement
          Logger.info("valid sms reading: #{moisture_pct}%, battery: #{battery_pct}%")
          measurement = %{battery_pct: battery_pct, moisture_pct: moisture_pct}
          {{state, {:ok, measurement}}, %{measurement: measurement}}

        invalid_frame ->
          Logger.warning("invalid sms frame: #{inspect(invalid_frame, pretty: true, limit: :infinity)}")
          {{state, {:error, "invalid frame"}}, %{invalid_frame: invalid_frame}}
      end
    end)
  end
end
