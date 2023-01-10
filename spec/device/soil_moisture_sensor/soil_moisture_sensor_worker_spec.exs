defmodule Device.SoilMoistureSensor.WorkerSpec do
  @moduledoc false
  use ESpec, async: true

  import Spec.Support.Factory

  @empty_state %Device.SoilMoistureSensor.Worker.State{sms: %Db.Models.SoilMoistureSensor{}}
  alias Device.SoilMoistureSensor.Worker

  describe "do_handle_sms_message" do
    it "accepts valid sms frames" do
      {_, result} = Worker.do_handle_sms_message(@empty_state, build(:sms_msg, %{battery_pct: 50, moisture_pct: 25}))
      expect(result) |> to(eq({:ok, %{battery_pct: 50, moisture_pct: 25}}))
    end

    it "rejects too short frames" do
      {_, result} = Worker.do_handle_sms_message(@empty_state, build(:too_short_sms_msg, %{battery_pct: 50, moisture_pct: 25}))
      expect(result) |> to(eq({:error, "invalid frame"}))
    end

    it "rejects too long frames" do
      {_, result} = Worker.do_handle_sms_message(@empty_state, build(:too_long_sms_msg, %{battery_pct: 50, moisture_pct: 25}))
      expect(result) |> to(eq({:error, "invalid frame"}))
    end
  end
end
