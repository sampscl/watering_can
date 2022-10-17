defmodule Device.Uart.Sup do
  @moduledoc """
  Supervisor for uart devices
  """
  use DynamicSupervisor
  require Logger

  @spec start_worker(Db.Models.Uart.t()) :: DynamicSupervisor.on_start_child()
  def start_worker(uart), do: DynamicSupervisor.start_child(__MODULE__, Device.Uart.Worker.child_spec(uart))

  @spec start_link(:ok) :: Supervisor.on_start()
  def start_link(:ok), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec init(:ok) :: {:ok, DynamicSupervisor.sup_flags()}
  def init(:ok) do
    Logger.info("Starting")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
