defmodule Telemetry.Comms.Uart.WateringCanFramer do
  @moduledoc """
  Telemetry handlers for the watering can uart device framer
  """
  require Logger

  @doc false
  def handle_add_framing(_, _measurements, metadata, _config) do
    Logger.debug(inspect(metadata, pretty: true, limit: :infinity))
  end

  @doc false
  def handle_flush(_, _measurements, metadata, _config) do
    Logger.debug(inspect(metadata, pretty: true, limit: :infinity))
  end

  @doc false
  def handle_frame_timeout(_, _measurements, metadata, _config) do
    Logger.debug(inspect(metadata, pretty: true, limit: :infinity))
  end

  @doc false
  def handle_remove_framing_start(_, _measurements, metadata, _config) do
    Logger.debug(inspect(metadata, pretty: true, limit: :infinity))
  end

  @doc false
  def handle_remove_framing_stop(_, measurements, metadata, _config) do
    to_log = %{measurements: Map.put(measurements, :duration_ms, System.convert_time_unit(measurements.duration, :native, :millisecond)), metadata: metadata}
    Logger.debug(inspect(to_log, pretty: true, limit: :infinity))
  end

  @doc false
  def handle_remove_framing_exception(_, measurements, metadata, _config) do
    to_log = %{measurements: Map.put(measurements, :duration_ms, System.convert_time_unit(measurements.duration, :native, :millisecond)), metadata: metadata}
    Logger.debug(inspect(to_log, pretty: true, limit: :infinity))
  end
end
