defmodule Db.AllSpec do
  @moduledoc """
  All database specs are here, and run synchronously. This is a drawback of Ecto SQLite3.
  """
  use ESpec, async: false

  describe "zone" do
    before(do: :ok = Ecto.Adapters.SQL.Sandbox.checkout(Db.Repo))
    finally(do: :ok = Ecto.Adapters.SQL.Sandbox.checkin(Db.Repo))

    it "has a unique zone number" do
      {:ok, _} = Db.Models.Zone.create(num: 1)
      expect(Db.Models.Zone.create(num: 1)) |> to(be_error_result())
    end
  end

  describe "control area" do
    before(do: :ok = Ecto.Adapters.SQL.Sandbox.checkout(Db.Repo))
    finally(do: :ok = Ecto.Adapters.SQL.Sandbox.checkin(Db.Repo))

    it "aggregates zones and soil moisture sensors" do
      ca_result = Db.Models.ControlArea.create(friendly_name: "test ca")
      expect(ca_result) |> to(be_ok_result())
      zone_result = Db.Models.Zone.create(num: 1, friendly_name: "test zone")
      expect(zone_result) |> to(be_ok_result())
      sms_result = Db.Models.SoilMoistureSensor.create(friendly_name: "test sms")
      expect(sms_result) |> to(be_ok_result())

      {:ok, ca} = ca_result
      {:ok, zone} = zone_result
      {:ok, sms} = sms_result

      zca_result = Db.Models.ZonesControlAreas.create(zone_id: zone.id, control_area_id: ca.id)
      expect(zca_result) |> to(be_ok_result())

      zsms_result = Db.Models.ZonesSoilMoistureSensors.create(zone_id: zone.id, soil_moisture_sensor_id: sms.id)
      expect(zsms_result) |> to(be_ok_result())

      expect(Db.Models.ControlArea.preload(ca, :zones).zones) |> to(match_list([zone]))
      expect(Db.Models.Zone.preload(zone, :soil_moisture_sensors).soil_moisture_sensors) |> to(match_list([sms]))
    end
  end
end
