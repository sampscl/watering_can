defmodule Device.Sup do
  @moduledoc """
  Supervisor for device tree
  """
  use Supervisor
  require Logger

  def start_link(:ok), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    Logger.info("Starting")
    Supervisor.init(children(), strategy: :one_for_one)
  end

  @doc false
  def children do
    [
      Device.Uart.Sup.child_spec(:ok)
    ]
  end
end
