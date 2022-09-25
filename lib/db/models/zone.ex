defmodule Db.Models.Zone do
  @moduledoc """
  Zone model
  """
  use Db.Models.BaseModel

  @insert_fields ~w/num friendly_name/a
  @required_fields ~w/num/a
  @update_fields @insert_fields

  schema "zones" do
    field(:num, :integer)
    field(:friendly_name, :string, default: "")
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
