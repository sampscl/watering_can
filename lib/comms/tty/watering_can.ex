defmodule Comms.Tty.WateringCan do
  @moduledoc """
  TTY interface for the watering can protocol, used as a linked GenServer. Will
  deliver un-framed messages individually to the owner pid

  See README.md for framing bit layout.
  """
  @doc "Worker managing watering can frames over a tty"
  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    @keys ~w/io_device framer_state owner_pid/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            io_device: File.io_device(),
            # framer_state is really a Comms.Uart.WateringCanFramer.State.t(),
            framer_state: term(),
            owner_pid: pid()
          }
  end

  ##############################
  # API
  ##############################

  @spec send_body(String.t(), binary()) :: :ok | {:error, any()}
  @doc """
  Wrap body in a frame and send it via a tty
  ## Parameters
  - `tty_name` The file path of the tty, e.g. "/dev/ttys0"
  - `body` Binary body of the frame to send
  ## Returns
  - `:ok` All is well
  - `{:error, reason}` Failed for reason
  """
  def send_body(tty_name, body), do: GenServer.call({:via, Registry, {WateringCan.Registry, {__MODULE__, tty_name}}}, {:send_body, body})

  @spec start_link(String.t()) :: GenServer.on_start()
  @doc """
  Start the genserver. It will accept output data from any pid and will send
  whole deframed messages to the calling pid when there is data available on
  the tty:

  ```
  {Comms.Tty.WateringCan, :input, binary_data}
  ```

  where `binary_data` has all framing removed.

  ## Parameters
  - `tty_name` The file path of the tty, e.g. "/dev/ttys0"
  ## Returns
  - See `GenServer.start_link/3`
  """
  def start_link(tty_name), do: GenServer.start_link(__MODULE__, {tty_name, self()}, name: {:via, Registry, {WateringCan.Registry, {__MODULE__, tty_name}}})

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init({tty_name, owner_pid}) do
    Logger.info("Starting")
    {:ok, io_device} = File.open(tty_name, [:raw, :read, :write, :binary])
    {:ok, framer_state} = Comms.Uart.WateringCanFramer.init(tty_name)
    # read in context of the new genserver pid
    send(self(), :begin_read)
    {:ok, %State{io_device: io_device, framer_state: framer_state, owner_pid: owner_pid}}
  end

  @impl GenServer
  def handle_call({:send_body, body}, _from, state) do
    {updated_state, result} = do_send_body(state, body)
    {:reply, result, updated_state}
  end

  @impl GenServer
  def handle_info(:begin_read, %State{io_device: io_device} = state) do
    genserver_pid = self()

    spawn_link(fn ->
      Logger.debug("reading #{inspect(io_device)}")

      case :file.read(io_device, 1) do
        {:error, reason} ->
          # No unlink, let it crash
          Logger.error("Read error: #{inspect(reason)}")

        :eof ->
          Logger.debug("eof")
          send(genserver_pid, :begin_read)
          Process.unlink(genserver_pid)

        data ->
          Logger.debug("have data")
          send(genserver_pid, {:process_data, data})
          send(genserver_pid, :begin_read)
          Process.unlink(genserver_pid)
      end
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:process_data, data}, state) do
    {:noreply, do_process_data(state, data)}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec do_process_data(State.t(), binary()) :: State.t()
  @doc false
  def do_process_data(%State{framer_state: framer_state, owner_pid: owner_pid} = state, data) do
    {_, body_list, updated_framer_state} = Comms.Uart.WateringCanFramer.remove_framing(data, framer_state)
    Enum.each(body_list, fn msg -> send(owner_pid, {__MODULE__, :input, msg}) end)
    %State{state | framer_state: updated_framer_state}
  end

  @spec do_send_body(State.t(), binary()) :: {State.t(), :ok | {:error, any()}}
  @doc false
  def do_send_body(state, body) do
    {:ok, framed_data, updated_framer_state} = Comms.Uart.WateringCanFramer.add_framing(body, state.framer_state)
    :ok = IO.write(state.io_device, framed_data)
    {%State{state | framer_state: updated_framer_state}, :ok}
  end
end
