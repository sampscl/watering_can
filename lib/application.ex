defmodule WateringCan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WateringCan.Supervisor]

    # telemetry
    :ok = :telemetry.attach("watering_can-db-init", [:ecto, :repo, :init], &Telemetry.Db.handle_init/4, %{})
    :ok = :telemetry.attach("watering_can-db-query", [:db, :repo, :query], &Telemetry.Db.handle_query/4, %{})

    Logger.info("Loading database #{Keyword.get(Application.get_env(:watering_can, Db.Repo, []), :database, "")}")
    Db.Release.migrate()
    Db.Release.seed()

    children =
      [
        # Children for all targets
        Db.Repo.child_spec([]),
        Web.Telemetry.child_spec([]),
        # Start the PubSub system
        Phoenix.PubSub.child_spec(name: Web.PubSub),
        # Start the Endpoint (http/https)
        Web.Endpoint.child_spec([])
      ] ++ children(target())

    Supervisor.start_link(children, opts)
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
