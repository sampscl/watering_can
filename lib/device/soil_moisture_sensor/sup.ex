defmodule Device.SoilMoistureSensor.Sup do
  @moduledoc """
  Supervisor for soil moisture sensor devices
  """
  @doc "Supervise soil moisture sensors"
  use DynamicSupervisor
  require Logger

  @spec start_worker(Device.SoilMoistureSensor.Worker.config_t()) :: DynamicSupervisor.on_start_child()
  def start_worker(sms), do: DynamicSupervisor.start_child(__MODULE__, Device.SoilMoistureSensor.Worker.child_spec(sms))

  @spec start_link(:ok) :: Supervisor.on_start()
  def start_link(:ok), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec init(:ok) :: {:ok, DynamicSupervisor.sup_flags()}
  def init(:ok) do
    Logger.info("Starting")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
