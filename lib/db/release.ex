defmodule Db.Release do
  @moduledoc """
  Functions for dealing with the database within a release (e.g. no Mix)
  """
  @app :watering_can

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()
    # this already does the ecto_repos thing...
    seeds_file = Path.join([to_string(:code.priv_dir(:watering_can)), "repo", "seeds.exs"])
    Code.eval_file(seeds_file)
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp load_app do
    Application.load(@app)
  end

  defp repos do
    load_app()
    Application.fetch_env!(@app, :ecto_repos)
  end
end
