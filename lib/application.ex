defmodule WateringCan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting")

    # telemetry
    handlers = [
      {[:ecto, :repo, :init], &Telemetry.Db.handle_init/4},
      {[:db, :repo, :query], &Telemetry.Db.handle_query/4},
      {[Device.Uart.WateringCanFramer, :add_framing], &Telemetry.Device.Uart.WateringCanFramer.handle_add_framing/4},
      {[Device.Uart.WateringCanFramer, :flush], &Telemetry.Device.Uart.WateringCanFramer.handle_flush/4},
      {[Device.Uart.WateringCanFramer, :frame_timeout], &Telemetry.Device.Uart.WateringCanFramer.handle_frame_timeout/4},
      {[Device.Uart.WateringCanFramer, :remove_framing, :start], &Telemetry.Device.Uart.WateringCanFramer.handle_remove_framing_start/4},
      {[Device.Uart.WateringCanFramer, :remove_framing, :stop], &Telemetry.Device.Uart.WateringCanFramer.handle_remove_framing_stop/4},
      {[Device.Uart.WateringCanFramer, :remove_framing, :exception], &Telemetry.Device.Uart.WateringCanFramer.handle_remove_framing_exception/4}
    ]

    :ok =
      Enum.reduce(handlers, :ok, fn {event_name, handler_function}, :ok ->
        :telemetry.attach(inspect(event_name), event_name, handler_function, %{})
      end)

    # Database startup and prep
    Logger.info("Loading database #{Keyword.get(Application.get_env(:watering_can, Db.Repo, []), :database, "")}")
    Db.Release.migrate()
    Db.Release.seed()

    # supervise the app
    children =
      [
        # Children for all targets
        Db.Repo.child_spec([]),
        Device.Sup.child_spec(:ok),
        Web.Telemetry.child_spec([]),
        # Start the PubSub system
        Phoenix.PubSub.child_spec(name: Web.PubSub),
        # Start the Endpoint (http/https)
        Web.Endpoint.child_spec([])
      ] ++ children(target())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.start_link(children, strategy: :one_for_one, name: WateringCan.Supervisor)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: WateringCan.Worker.start_link(arg)
      # {WateringCan.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: WateringCan.Worker.start_link(arg)
      # {WateringCan.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:watering_can, :target)
  end
end
