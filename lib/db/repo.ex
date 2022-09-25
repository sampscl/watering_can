defmodule Db.Repo do
  @moduledoc """
  Repo module
  """
  use Ecto.Repo,
    otp_app: :watering_can,
    adapter: Ecto.Adapters.SQLite3

  def init(_arg0, config) do
    {:ok, config}
  end
end
