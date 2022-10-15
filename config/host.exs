import Config

# Add configuration that is only needed when running on the host here.

config :watering_can, Db.Repo,
  database: "priv/db/db.sqlite3",
  log: false
