defmodule WateringCan.MixProject do
  use Mix.Project

  @app :watering_can
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :osd32mp1, :x86_64, :grisp2]

  @doc """
  Get the version of the app. This will do sorta-smart things when git is not
  present on the build machine (it's possible, especially in Docker containers!)
  by using the "version" environment variable.

  ## Returns
  - version `String.t`
  """
  def version do
    "git describe"
    |> System.shell(cd: Path.dirname(__ENV__.file))
    |> then(fn
      {version, 0} -> Regex.replace(~r/^[[:alpha:]]*/, String.trim(version), "")
      {_barf, _exit_code} -> System.get_env("version", "0.0.0-UNKNOWN")
    end)
    |> tap(&IO.puts("Version: #{&1}"))
  end

  def project do
    [
      app: @app,
      version: version(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      archives: [nerves_bootstrap: "~> 1.11"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [{@app, release()}],
      preferred_cli_env: [espec: :test, compliance: :test],
      preferred_cli_target: [run: :host, espec: :host],
      # this makes dialyzer include mix behaviors in the PLT so that
      # dialyxir doesn't complain about our mix tasks and unknown
      # mix module behaviors, thanks Stack Overflow: https://stackoverflow.com/questions/51208388/how-to-fix-dialyzer-callback-info-about-the-behaviour-is-not-available
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "ecto.seed"
      ],
      # espec: &espec/1,
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      compliance: [
        "compile",
        "dialyzer",
        "espec",
        "credo"
      ]
    ]
  end

  def espec(args) do
    Mix.Task.run("espec", args ++ ["--no-start"])
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "spec/support"]
  defp elixirc_paths(:integration), do: ["lib", "integration"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WateringCan.Application, []},
      extra_applications: [:sasl, :logger, :runtime_tools, :os_mon]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.7.16 or ~> 1.8.0", runtime: false},
      {:shoehorn, "~> 0.9"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.13.0", targets: @all_targets},
      {:nerves_pack, "~> 0.7.0", targets: @all_targets},
      {:nerves_ssh, "~> 0.4", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_rpi, "~> 1.19", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.19", runtime: false, targets: :rpi0},
      {:nerves_system_rpi2, "~> 1.19", runtime: false, targets: :rpi2},
      {:nerves_system_rpi3, "~> 1.19", runtime: false, targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.19", runtime: false, targets: :rpi3a},
      {:nerves_system_rpi4, "~> 1.19", runtime: false, targets: :rpi4},
      {:nerves_system_bbb, "~> 2.14", runtime: false, targets: :bbb},
      {:nerves_system_osd32mp1, "~> 0.10", runtime: false, targets: :osd32mp1},
      {:nerves_system_x86_64, "~> 1.19", runtime: false, targets: :x86_64},
      {:nerves_system_grisp2, "~> 0.3", runtime: false, targets: :grisp2},

      # core deps
      {:espec, "~> 1.9", only: [:test, :integration]},
      {:ex_machina, "~> 2.7", only: [:test, :integration]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ecto_sqlite3, "~> 0.8"},
      {:telemetry, "~> 1.2"},
      {:executus, "~> 0.6"},

      # web / phoenix
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.18"},
      {:floki, ">= 0.33.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},

      # peripheral deps
      {:nerves_uart, "~> 1.2"}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
