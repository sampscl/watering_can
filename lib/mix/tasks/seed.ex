defmodule Mix.Tasks.Ecto.Seed do
  @moduledoc """
  Seed task
  """
  @shortdoc "Seeds the database, is idempotent"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Code.eval_file("priv/repo/seeds.exs")
  end
end
