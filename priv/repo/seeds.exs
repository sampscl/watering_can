Application.load(:watering_can)
require Logger

for repo <- Application.fetch_env!(:watering_can, :ecto_repos) do
  Logger.info("Seeding")
  Ecto.Migrator.with_repo(repo, fn _repo ->
    :ok
  end)
end
