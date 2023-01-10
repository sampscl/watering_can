defmodule Telemetry.Device.SoilMoistureSensor.Worker do
  @moduledoc """
  Telemetry hasndlers for the soil moisture sensor worker
  """

  require Logger

  @doc false
  def handle_sms_frame_start(_, _measurements, metadata, _config) do
    Logger.debug("", metadata: metadata)
  end

  def handle_sms_frame_stop(_, measurements, metadata, _config) do
    Logger.debug("", metadata: metadata, measurements: measurements)
  end

  def handle_sms_frame_exception(_, measurements, metadata, _config) do
    Logger.error("", measurements: measurements, metadata: metadata)
  end
end
