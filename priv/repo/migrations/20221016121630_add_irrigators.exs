defmodule Db.Repo.Migrations.AddIrrigators do
  use Ecto.Migration

  def change do
    create table(:irrigators) do
      add(:type, :string, size: 80)
      add(:zone_id, references(:zone, on_delete: :nilify_all), null: true)
      add(:friendly_name, :string, size: 80)
      timestamps()
    end
    create(index(:irrigators, [:type]))
  end
end
