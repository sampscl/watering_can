defmodule Db.Repo.Migrations.AddControlAreas do
  use Ecto.Migration

  def change do
    create table(:control_areas) do
      add(:friendly_name, :string, null: false, size: 128, default: "")
      timestamps()
    end

    create table(:zones_control_areas) do
      add(:zone_id, references(:zones, on_delete: :nilify_all), null: true)
      add(:control_area_id, references(:control_areas, on_delete: :nilify_all), null: true)
      timestamps()
    end
    create unique_index(:zones_control_areas, [:zone_id, :control_area_id], name: :zone_id_control_area_id)

    create table(:zones_soil_moisture_sensors) do
      add(:zone_id, references(:zones, on_delete: :nilify_all), null: true)
      add(:soil_moisture_sensor_id, references(:soil_moisture_sensors, on_delete: :nilify_all), null: true)
      timestamps()
    end
    create unique_index(:zones_soil_moisture_sensors, [:zone_id, :soil_moisture_sensor_id], name: :zone_id_soil_moisture_sensor_id)
  end
end
