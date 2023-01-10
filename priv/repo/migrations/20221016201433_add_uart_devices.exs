defmodule Db.Repo.Migrations.AddUartDevices do
  use Ecto.Migration

  def change do
    create table(:uart) do
      add(:name, :string, size: 128, null: false)
      add(:speed, :integer)
      add(:data_bits, :integer)
      add(:stop_bits, :integer)
      add(:parity, :string, size: 80)
      add(:flow_control, :string, size: 80)
      add(:protocol, :string, size: 80)
      add(:friendly_name, :string, null: false, size: 128, default: "")
      timestamps()
    end
    create(unique_index(:uart, [:name]))
    end
end
