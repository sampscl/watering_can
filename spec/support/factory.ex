defmodule Spec.Support.Factory do
  @moduledoc false
  use ExMachina

  def frame_factory(%{body: body} = _attrs) do
    <<
      2::integer-little-unsigned-size(8),
      byte_size(body)::integer-little-unsigned-size(16)
    >> <>
      body <>
      <<
        Comms.Uart.WateringCanFramer.chk(body)::integer-little-unsigned-size(8),
        3::integer-little-unsigned-size(8)
      >>
  end

  def invalid_chk_frame_factory(%{body: body} = _attrs) do
    invalid_chk = 1 + Comms.Uart.WateringCanFramer.chk(body)

    <<
      2::integer-little-unsigned-size(8),
      byte_size(body)::integer-little-unsigned-size(16)
    >> <>
      body <>
      <<
        invalid_chk::integer-little-unsigned-size(8),
        3::integer-little-unsigned-size(8)
      >>
  end

  def sms_msg_factory(%{battery_pct: battery_pct, moisture_pct: moisture_pct} = _attrs) do
    <<
      battery_pct::integer-little-unsigned-size(8),
      moisture_pct::integer-little-unsigned-size(8)
    >>
  end

  def too_short_sms_msg_factory(%{battery_pct: battery_pct} = _attrs) do
    <<
      battery_pct::integer-little-unsigned-size(8)
    >>
  end

  def too_long_sms_msg_factory(%{battery_pct: battery_pct, moisture_pct: moisture_pct} = _attrs) do
    <<
      battery_pct::integer-little-unsigned-size(8),
      moisture_pct::integer-little-unsigned-size(32)
    >>
  end
end
