import Config

# Add configuration that is only needed when running on the host here.

db_file =
  case config_env() do
    :test -> "priv/db/test_db.sqlite3"
    :integration -> "priv/db/integration_db.sqlite3"
    _ -> "priv/db/db.sqlite3"
  end

config :watering_can, Db.Repo,
  database: db_file,
  log: false
