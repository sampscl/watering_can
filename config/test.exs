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

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :watering_can, Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "uIc0I0RKNxvjf6WUQfUeWSOkITUpakHd3g+sn9bGE0cq8GH+5M/MKZ/Ye6VBVZpf",
  server: false

# In test we don't send emails.
config :watering_can, Web.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
