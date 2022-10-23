import Config

# Add configuration that is only needed when running on the host here.

db_file = if :test == config_env(), do: "priv/db/test_db.sqlite3", else: "priv/db/db.sqlite3"

config :watering_can, Db.Repo,
  database: db_file,
  log: false
