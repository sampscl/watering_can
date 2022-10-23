defmodule Db.Models.ZonesControlAreas do
  @moduledoc """
  Association table between zones and control areas
  """
  use Db.Models.BaseModel

  @insert_fields ~w/zone_id control_area_id/a
  @required_fields ~w/zone_id control_area_id/a
  @update_fields @insert_fields

  schema "zones_control_areas" do
    belongs_to(:zone, Db.Models.Zone, foreign_key: :zone_id)
    belongs_to(:control_area, Db.Models.ControlArea, foreign_key: :control_area_id)
    timestamps()
  end

  @doc false
  def create_changeset(params) when is_list(params), do: create_changeset(Map.new(params))

  def create_changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, @insert_fields, empty_values: [])
    |> Ecto.Changeset.validate_required(@required_fields)
  end

  @doc false
  def update_changeset(model, params) when is_list(params), do: update_changeset(model, Map.new(params))

  def update_changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, @update_fields)
  end
end
