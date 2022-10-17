defmodule Db.Models.Uart do
  @moduledoc """
  Uart model
  """
  use Db.Models.BaseModel

  @insert_fields ~w/name speed data_bits stop_bits parity flow_control protocol friendly_name/a
  @required_fields ~w/name/a
  @update_fields @insert_fields

  @valid_data_bits [5, 6, 7, 8]
  @valid_stop_bits [1, 2]
  @valid_parity ~w/none even odd space mark ignore/a
  @valid_flow_control ~w/none hardware software/a
  @valid_protocol ~w/watering_can/a

  schema "zones" do
    field(:name, :string)
    field(:speed, :integer, default: 115_200)
    field(:data_bits, :integer, default: 8)
    field(:stop_bits, :integer, default: 1)
    field(:parity, Db.Types.Atom, default: :none)
    field(:flow_control, Db.Types.Atom, default: :none)
    field(:protocol, Db.Types.Atom, default: :watering_can)
    field(:friendly_name, :string, default: "uart")
    timestamps()
  end

  @doc false
  def create_changeset(params) when is_list(params), do: create_changeset(Map.new(params))

  def create_changeset(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, @insert_fields, empty_values: [])
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_inclusion(:data_bits, @valid_data_bits)
    |> Ecto.Changeset.validate_inclusion(:stop_bits, @valid_stop_bits)
    |> Ecto.Changeset.validate_inclusion(:parity, @valid_parity)
    |> Ecto.Changeset.validate_inclusion(:flow_control, @valid_flow_control)
    |> Ecto.Changeset.validate_inclusion(:protocol, @valid_protocol)
  end

  @doc false
  def update_changeset(model, params) when is_list(params), do: update_changeset(model, Map.new(params))

  def update_changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, @update_fields)
    |> Ecto.Changeset.validate_inclusion(:data_bits, @valid_data_bits)
    |> Ecto.Changeset.validate_inclusion(:stop_bits, @valid_stop_bits)
    |> Ecto.Changeset.validate_inclusion(:parity, @valid_parity)
    |> Ecto.Changeset.validate_inclusion(:flow_control, @valid_flow_control)
    |> Ecto.Changeset.validate_inclusion(:protocol, @valid_protocol)
  end
end
