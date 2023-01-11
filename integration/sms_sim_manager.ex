defmodule Integration.SmsSimManager do
  @moduledoc """
  Manager for simulated soil moisture sensors
  """

  @doc "Manager for simulated soil moisture sensors"
  use GenServer, restart: :transient
  require Logger

  defmodule State do
    @moduledoc false

    defmodule SimState do
      @moduledoc false
      @keys ~w/pid framer_state owner_pid/a
      @enforce_keys @keys
      defstruct @keys

      @type t() :: %__MODULE__{
              pid: pid() | nil,
              framer_state: term(),
              owner_pid: pid() | nil
            }
    end

    @keys ~w/sims/a
    @enforce_keys @keys
    defstruct @keys

    @type sim_state_map_t() :: %{
            required(:pid) => SimState.t()
          }

    @type t() :: %__MODULE__{
            sims: sim_state_map_t()
          }
  end

  ##############################
  # API
  ##############################

  @spec start_sim(String.t()) :: :ok | {:error, any()}
  @doc """
  Start a simulation (this genserver can manage multiple); will deliver
  deframed messages individually to the caller pid via `{Integration.SmsSimManager, :input, msg}`
  ## Parameters
  - `sms_sim_path` The directory containing the watering_can_sms_simulator executable
  ## Returns
  - `:ok` All is well
  - `{:error, reason}` failed for reason
  """
  def start_sim(sms_sim_path), do: GenServer.call(__MODULE__, {:start_sim, sms_sim_path, self()})

  def start_link(:ok), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init(:ok) do
    Logger.info("Starting")
    {:ok, %State{sims: Map.new()}}
  end

  @impl GenServer
  def handle_call({:start_sim, sms_sim_path, owner_pid}, _from, state) do
    {updated_state, result} = do_start_sim(state, sms_sim_path, owner_pid)
    {:reply, result, updated_state}
  end

  @impl GenServer
  def handle_info({pid, :data, :out, data}, state) do
    Logger.debug("pid #{inspect(pid)} says: #{inspect(data)}")
    {:noreply, do_pid_data(state, pid, data)}
  end

  @impl GenServer
  def handle_info({pid, :data, :err, str}, state) do
    Logger.warning("pid #{inspect(pid)} complains: #{inspect(str)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({pid, :result, result}, %State{sims: sims} = state) do
    Logger.error("sim pid #{inspect(pid)} unexpectedly exited: #{inspect(result)}")
    {:noreply, %State{state | sims: Map.delete(sims, pid)}}
  end

  ##############################
  # Internal Calls
  ##############################

  @doc false
  @spec do_start_sim(State.t(), String.t(), pid()) :: {State.t(), :ok | {:error, any()}}
  def do_start_sim(%State{sims: sims} = state, sms_sim_path, owner_pid) do
    case Executus.execute(sms_sim_path, sync: false) do
      {:ok, pid} ->
        Logger.info("Started sim #{inspect(pid)} to owner #{inspect(owner_pid)}")

        {:ok, framer_state} = Comms.Uart.WateringCanFramer.init("#{inspect(pid)}-#{inspect(owner_pid)}")

        sim_state = %State.SimState{
          pid: pid,
          owner_pid: owner_pid,
          framer_state: framer_state
        }

        updated_sims = Map.put(sims, pid, sim_state)
        updated_state = %State{state | sims: updated_sims}
        {updated_state, :ok}

      error ->
        Logger.error("Failed to start sms sim from #{sms_sim_path}: #{inspect(error)}")
        {state, error}
    end
  end

  @doc false
  @spec do_pid_data(State.t(), pid(), binary()) :: State.t()
  def do_pid_data(%State{sims: sims} = state, pid, data) do
    case Map.fetch(sims, pid) do
      {:ok, sim_state} ->
        {_, body_list, updated_framer_state} = Comms.Uart.WateringCanFramer.remove_framing(data, sim_state.framer_state)
        Enum.each(body_list, fn msg -> send(sim_state.owner_pid, {__MODULE__, :input, msg}) end)
        updated_sim_state = %State.SimState{sim_state | framer_state: updated_framer_state}
        updated_sims = Map.put(sims, pid, updated_sim_state)
        %State{state | sims: updated_sims}

      :error ->
        Logger.error("data from unknown pid")
        state
    end
  end
end
