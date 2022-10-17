defmodule Device.Uart.Worker do
  @moduledoc """
  Worker for uarts
  """

  @doc "Worker managing a UART for communications with devices"
  use GenServer, restart: :transient
  require Logger

  ##############################
  # API
  ##############################

  ##############################
  # GenServer Callbacks
  ##############################

  defmodule State do
    @moduledoc false
    @keys ~w/uart uart_state/a
    @enforce_keys @keys
    defstruct @keys

    @type uart_state() :: :ok | {:error, File.posix()}

    @type t() :: %__MODULE__{
            uart: Db.Models.Uart.t(),
            uart_state: uart_state()
          }
  end

  @impl GenServer
  @spec init(Db.Models.Uart.t()) :: {:ok, State.t()}
  def init(uart) do
    Logger.info("Starting")
    send(self(), :open_uart)
    {:ok, %State{uart: uart, uart_state: {:error, :enoent}}}
  end

  @impl GenServer
  def handle_info(:open_uart, state) do
    {:noreply, do_open_uart(state)}
  end

  @impl GenServer
  def handle_info({:nerves_uart, _serial_port_id, _data} = msg, state) do
    {updated_state, response} = do_handle_uart_data(state, msg)
    {response, updated_state}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec do_open_uart(State.t()) :: State.t()
  def do_open_uart(state) do
    uart_state =
      Nerves.UART.open(self(), state.uart.name,
        active: true,
        speed: state.uart.speed,
        data_bits: state.uart.data_bits,
        stop_bits: state.uart.stop_bits,
        parity: state.uart.parity,
        flow_control: state.uart.flow_control,
        rx_framing_timeout: 0,
        framing: protocol_framer(state.uart)
      )

    if :ok == uart_state do
      Logger.info("UART configured: #{inspect(state.uart, pretty: true)}")
    else
      Logger.error("Failed to configure UART #{inspect(state.uart, pretty: true)}, error: #{inspect(uart_state)}")
      Process.send_after(self(), :open_uart, 5_000)
    end

    %{state | uart_state: uart_state}
  end

  @spec do_handle_uart_data(State.t(), {:nerves_uart, String.t() | pid(), binary()}) :: {State.t(), :noreply} | {State.t(), :stop, term(), State.t()}
  def do_handle_uart_data(state, _msg) do
    {state, :noreply}
  end

  @spec protocol_framer(Db.Models.Uart.t()) :: module() | {module(), any()}
  def protocol_framer(model)
  def protocol_framer(%{protocol: :watering_can, name: name} = _model), do: {Device.Uart.WateringCanFramer, name}
end
