defmodule Db.Repo.Migrations.AddSoilMoistureSensors do
  use Ecto.Migration

  def change do
    create table(:soil_moisture_sensors) do
      add(:friendly_name, :string, size: 80)
      add(:configuration, :binary, null: false)
    end
  end
end
