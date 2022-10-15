defmodule Mix.Tasks.Ecto.Seed do
  @moduledoc """
  Seed task
  """
  @shortdoc "Seeds the database, is idempotent"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Db.Release.seed()
  end
end
