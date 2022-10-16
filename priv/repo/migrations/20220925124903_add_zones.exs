defmodule Db.Repo.Migrations.AddZones do
  use Ecto.Migration

  def change do
    create table(:zones) do
      add(:num, :integer, null: false)
      add(:friendly_name, :string, null: false, size: 128, default: "")
      add(:configuration, :binary, null: false)
      timestamps()
    end
    create(unique_index(:zones, [:num]))
  end
end
