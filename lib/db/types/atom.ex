defmodule Db.Types.Atom do
  @moduledoc """
  Db type for elixir atoms
  """
  use Ecto.Type

  def type, do: :atom

  def blank?, do: false
  def cast(value), do: {:ok, value}
  def dump(value), do: {:ok, Atom.to_string(value)}
  def load(value), do: {:ok, String.to_atom(value)}
  def embed_as(_type), do: :self
end
