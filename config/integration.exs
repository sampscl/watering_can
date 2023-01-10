# This file is processed in the named config_env() for all targets, before host.exs and target.exs
import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :watering_can, Db.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :logger,
  truncate: :infinity,
  backends: [:console]

config :logger, :console,
  format: "$date $time [$level] $metadata $message\n",
  metadata: [:pid, :file, :line, :mfa]
