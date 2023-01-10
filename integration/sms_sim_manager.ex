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
      @keys ~w/pid pty_path/a
      @enforce_keys @keys
      defstruct @keys

      @type t() :: %__MODULE__{
              pid: pid(),
              pty_path: String.t() | nil
            }
    end

    @keys ~w/sim_pids/a
    @enforce_keys @keys
    defstruct @keys

    @type sim_state_map_t() :: %{
            required(:pid) => SimState.t()
          }

    @type t() :: %__MODULE__{
            sim_pids: sim_state_map_t()
          }
  end

  ##############################
  # API
  ##############################

  @spec start_sims(String.t(), pos_integer()) :: :ok | {:error, any()}
  @doc """
  Start simulations
  ## Parameters
  - `sms_sim_path` The directory containing the watering_can_sms_simulator executable
  - `count` The number of instances to launch
  ## Returns
  - `:ok` All is well
  - `{:error, reason}` failed for reason
  """
  def start_sims(sms_sim_path, count), do: GenServer.call(__MODULE__, {:start_sims, sms_sim_path, count})

  def start_link(:ok), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init(:ok) do
    Logger.info("Starting")
    {:ok, %State{sim_pids: Map.new()}}
  end

  @impl GenServer
  def handle_call({:start_sims, sms_sim_path, count}, _from, state) do
    {updated_state, result} =
      if File.exists?(sms_sim_path) do
        do_start_sims(state, sms_sim_path, count)
      else
        {state, {:error, "watering can simulator file does not exist"}}
      end

    {:reply, result, updated_state}
  end

  @impl GenServer
  def handle_info({pid, :data, :out, str}, state) do
    Logger.debug("pid #{inspect(pid)} says: #{inspect(str)}")
    {:noreply, do_pid_data(state, pid, str)}
  end

  @impl GenServer
  def handle_info({pid, :data, :err, str}, state) do
    Logger.warning("pid #{inspect(pid)} complains: #{inspect(str)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({pid, :result, result}, %State{sim_pids: sim_pids} = state) do
    Logger.error("pid #{inspect(pid)} unexpectedly exited: #{inspect(result)}")
    {:noreply, %State{state | sim_pids: Map.delete(sim_pids, pid)}}
  end

  ##############################
  # Internal Calls
  ##############################

  @doc false
  @spec do_start_sims(State.t(), String.t(), non_neg_integer()) :: {State.t(), :ok | {:error, any()}}
  def do_start_sims(state, _sms_sim_path, 0), do: {state, :ok}

  def do_start_sims(%State{sim_pids: sim_pids} = state, sms_sim_path, count) do
    case Executus.execute(sms_sim_path, sync: false) do
      {:ok, pid} ->
        Logger.debug("Started sim #{count} with pid #{inspect(pid)}")
        do_start_sims(%State{state | sim_pids: Map.put(sim_pids, pid, %State.SimState{pid: pid, pty_path: nil})}, sms_sim_path, count - 1)

      error ->
        Logger.error("Failed to start sms sim from #{sms_sim_path}: #{inspect(error)}")
        {state, error}
    end
  end

  @spec do_pid_data(State.t(), pid(), binary()) :: State.t()
  @doc false
  def do_pid_data(%State{sim_pids: sim_pids} = state, pid, data) do
    with {:known_pid, {:ok, sim_state}} <- {:known_pid, Map.fetch(sim_pids, pid)},
         {:needs_pty_path, true} <- {:needs_pty_path, is_nil(sim_state.pty_path)},
         {:extract_pty_path, %{"pty_path" => pty_path}} <- {:extract_pty_path, Regex.named_captures(~r/(?<pty_path>^.+)\s*/, data)} do
      Logger.debug("pid #{inspect(pid)} pty_path: #{pty_path}")
      {:ok, _} = Device.SoilMoistureSensor.Sup.start_worker(%{type: :tty_framer, tty: pty_path})
      %State{state | sim_pids: Map.put(sim_pids, pid, %State.SimState{sim_state | pty_path: pty_path})}
    else
      {:known_pid, :error} ->
        Logger.error("Got message from unknown pid #{inspect(pid)}: #{inspect(data)}")
        state

      {:needs_pty_path, false} ->
        # this is okay, the sim is allowed to print newlines and stuff after the initial pty path
        state
    end
  end
end
