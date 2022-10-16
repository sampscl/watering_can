defmodule Db.Models.Irrigator do
  @moduledoc """
  Irrigator model
  """
  use Db.Models.BaseModel

  @insert_fields ~w/type zone_id friendly_name/a
  @required_fields ~w/type/a
  @update_fields @insert_fields

  @valid_types ~w/drip pop_up/a

  schema "irrigators" do
    field(:type, Db.Types.Atom)
    field(:friendly_name, :string, default: "irrigator")
    belongs_to(:zone, Db.Models.Zone, foreign_key: :zone_id)
    timestamps()
  end

  @doc false
  def create_changeset(params) when is_list(params), do: create_changeset(Map.new(params))

  def create_changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, @insert_fields, empty_values: [])
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_inclusion(:type, @valid_types)
  end

  @doc false
  def update_changeset(model, params) when is_list(params), do: update_changeset(model, Map.new(params))

  def update_changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, @update_fields)
    |> Ecto.Changeset.validate_inclusion(:type, @valid_types)
  end
end
