defmodule Db.AllSpec do
  @moduledoc """
  All database specs are here, and run synchronously. This is a drawback of Ecto SQLite3.
  """
  use ESpec, async: false

  before(do: :ok = Ecto.Adapters.SQL.Sandbox.checkout(Db.Repo))
  finally(do: :ok = Ecto.Adapters.SQL.Sandbox.checkin(Db.Repo))

  describe "zone" do
    it "has a unique zone number" do
      {:ok, _} = Db.Models.Zone.create(num: 1)
      expect(Db.Models.Zone.create(num: 1)) |> to(be_error_result())
    end
  end
end
