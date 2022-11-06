defmodule Db.Models.ControlArea do
  @moduledoc """
  Control area model
  """
  use Db.Models.BaseModel

  @insert_fields ~w/friendly_name/a
  @required_fields ~w//a
  @update_fields @insert_fields

  schema "control_areas" do
    field(:friendly_name, :string, default: "control_area")
    many_to_many(:zones, Db.Models.Zone, join_through: Db.Models.ZonesControlAreas, join_keys: [control_area_id: :id, zone_id: :id], on_replace: :delete)

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
