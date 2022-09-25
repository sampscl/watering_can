defmodule Telemetry.Db do
  @moduledoc """
  Telemetry handlers for the database
  """
  use Utils.Logger, id: :db

  @doc false
  def handle_init(_, measurements, _metadata, _config) do
    Logger.debug(inspect(measurements), db: true)
  end

  @doc false
  def handle_query(_, measurements, metadata, _config) do
    log_items = %{
      query: metadata.query,
      source: metadata.source,
      total_time: "#{System.convert_time_unit(measurements.total_time, :native, :millisecond)}ms",
      result:
        case metadata.result do
          {:ok, _} -> "OK"
          _ -> "ERROR"
        end
    }

    log_debug(inspect(log_items))
  end
end
