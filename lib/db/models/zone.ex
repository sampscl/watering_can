defmodule Db.Models.Zone do
  @moduledoc """
  Zone model
  """
  use Db.Models.BaseModel

  @insert_fields ~w/num friendly_name configuration/a
  @required_fields ~w/num/a
  @update_fields @insert_fields

  schema "zones" do
    field(:num, :integer)
    field(:friendly_name, :string, default: "")
    field(:configuration, Db.Types.Term, default: %{})

    many_to_many(:soil_moisture_sensors, Db.Models.SoilMoistureSensor,
      join_through: Db.Models.ZonesSoilMoistureSensors,
      join_keys: [zone_id: :id, soil_moisture_sensor_id: :id],
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def create_changeset(params) when is_list(params), do: create_changeset(Map.new(params))

  def create_changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, @insert_fields, empty_values: [])
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.unique_constraint(:num)
  end

  @doc false
  def update_changeset(model, params) when is_list(params), do: update_changeset(model, Map.new(params))

  def update_changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, @update_fields)
    |> Ecto.Changeset.unique_constraint(:num)
  end
end
