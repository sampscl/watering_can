defmodule Db.Types.Term do
  @moduledoc """
  Db type for elixir terms
  """
  use Ecto.Type

  def type, do: :term

  def blank?, do: false
  def cast(value), do: {:ok, value}
  def dump(value), do: {:ok, :erlang.term_to_binary(value)}
  def load(value), do: {:ok, :erlang.binary_to_term(value)}
  def embed_as(_type), do: :self
end
