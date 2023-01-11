defmodule WateringCan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @config_env Application.compile_env(:watering_can, :config_env)

  @impl true
  def start(_type, _args) do
    Logger.info("Starting")

    # telemetry
    handlers = [
      {[:ecto, :repo, :init], &Telemetry.Db.handle_init/4},
      {[:db, :repo, :query], &Telemetry.Db.handle_query/4},
      {[Comms.Uart.WateringCanFramer, :add_framing], &Telemetry.Comms.Uart.WateringCanFramer.handle_add_framing/4},
      {[Comms.Uart.WateringCanFramer, :flush], &Telemetry.Comms.Uart.WateringCanFramer.handle_flush/4},
      {[Comms.Uart.WateringCanFramer, :frame_timeout], &Telemetry.Comms.Uart.WateringCanFramer.handle_frame_timeout/4},
      {[Comms.Uart.WateringCanFramer, :remove_framing, :start], &Telemetry.Comms.Uart.WateringCanFramer.handle_remove_framing_start/4},
      {[Comms.Uart.WateringCanFramer, :remove_framing, :stop], &Telemetry.Comms.Uart.WateringCanFramer.handle_remove_framing_stop/4},
      {[Comms.Uart.WateringCanFramer, :remove_framing, :exception], &Telemetry.Comms.Uart.WateringCanFramer.handle_remove_framing_exception/4},
      {[Device.SoilMoistureSensor.Worker, :handle_sms_frame, :start], &Telemetry.Device.SoilMoistureSensor.Worker.handle_sms_frame_start/4},
      {[Device.SoilMoistureSensor.Worker, :handle_sms_frame, :stop], &Telemetry.Device.SoilMoistureSensor.Worker.handle_sms_frame_stop/4},
      {[Device.SoilMoistureSensor.Worker, :handle_sms_frame, :exception], &Telemetry.Device.SoilMoistureSensor.Worker.handle_sms_frame_exception/4}
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
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    children =
      [
        # Children for all targets
        Registry.child_spec(keys: :unique, name: WateringCan.Registry),
        Task.Supervisor.child_spec(name: WateringCan.Task.Supervisor),
        Db.Repo.child_spec([]),
        Device.Sup.child_spec(:ok),
        Web.Telemetry.child_spec([]),
        Phoenix.PubSub.child_spec(name: Web.PubSub),
        Web.Endpoint.child_spec([])
      ] ++
        target_children(target()) ++
        env_children(@config_env)

    result = Supervisor.start_link(children, strategy: :one_for_one, name: WateringCan.Supervisor)
    :ok = start_initial_tasks()
    result
  end

  # List all child processes to be supervised
  def target_children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: WateringCan.Worker.start_link(arg)
      # {WateringCan.Worker, arg},
    ]
  end

  def target_children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: WateringCan.Worker.start_link(arg)
      # {WateringCan.Worker, arg},
    ]
  end

  if :integration == @config_env do
    def env_children(:integration) do
      [
        # Children that only run in a certain configuration environment
        Integration.SmsSimManager.child_spec(:ok)
      ]
    end
  end

  def env_children(_env) do
    [
      # Children that only run in a certain configuration environment
    ]
  end

  def target(), do: Application.get_env(:watering_can, :target)

  def start_initial_tasks do
    Task.Supervisor.start_child(WateringCan.Task.Supervisor, fn ->
      Enum.each(Db.Models.SoilMoistureSensor.all(), &Device.SoilMoistureSensor.Sup.start_worker(&1))
    end)

    :ok
  end
end
