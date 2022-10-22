defmodule Device.Uart.WateringCanFramerSpec do
  @moduledoc false
  use ESpec

  alias Device.Uart.WateringCanFramer, as: Framer

  def start_of_msg, do: <<2::size(8)>>
  def end_of_msg, do: <<3::size(8)>>
  def partial_msg, do: start_of_msg()
  def buffer_of_garbage, do: <<0xFF::size(128)>>

  def valid_frame do
    body = <<0xDEADBEEF::integer-little-unsigned-size(32)>>

    framed =
      start_of_msg() <>
        <<byte_size(body)::integer-little-unsigned-size(16), body::bitstring, Framer.chk(body)::integer-little-unsigned-size(8)>> <>
        end_of_msg()

    {framed, body}
  end

  describe "chk" do
    it "computes correct checksums" do
      expect(Framer.chk(<<>>) |> to(eq(0)))
      expect(Framer.chk(<<0::size(8)>>) |> to(eq(0)))
      expect(Framer.chk(<<1::size(8)>>) |> to(eq(1)))
      expect(Framer.chk(<<1::size(8), 2::size(8)>>) |> to(eq(3)))
      expect(Framer.chk(<<1::size(8), 1::size(8)>>) |> to(eq(0)))
    end
  end

  describe "reduce_buf" do
    it "reduces and accumulates all data" do
      expect(Framer.reduce_buf(<<>>, []) |> to(eq({<<>>, []})))
      expect(Framer.reduce_buf(<<>>, ["foo"]) |> to(eq({<<>>, ["foo"]})))
    end

    it "rejects mis-framed data but maintains accumulation" do
      expect(Framer.reduce_buf(buffer_of_garbage(), []) |> to(eq({<<>>, []})))
      expect(Framer.reduce_buf(buffer_of_garbage(), ["foo"]) |> to(eq({<<>>, ["foo"]})))
    end

    it "identifies partial messages and maintains accumulation" do
      expect(Framer.reduce_buf(partial_msg(), []) |> to(eq({partial_msg(), []})))
      expect(Framer.reduce_buf(partial_msg(), ["foo"]) |> to(eq({partial_msg(), ["foo"]})))
    end

    it "rejects misframed data, identifies partial messages and maintains accumulation" do
      expect(Framer.reduce_buf(buffer_of_garbage() <> partial_msg(), []) |> to(eq({partial_msg(), []})))
      expect(Framer.reduce_buf(buffer_of_garbage() <> partial_msg(), ["foo"]) |> to(eq({partial_msg(), ["foo"]})))
    end

    it "deframes a valid message and maintains accumulation" do
      {frame, body} = valid_frame()
      expect(Framer.reduce_buf(frame, []) |> to(eq({<<>>, [body]})))
      expect(Framer.reduce_buf(frame, ["foo"]) |> to(eq({<<>>, ["foo", body]})))
    end

    it "deframes multiple valid messages and maintains accumulation" do
      {frame, body} = valid_frame()
      expect(Framer.reduce_buf(frame <> frame, []) |> to(eq({<<>>, [body, body]})))
      expect(Framer.reduce_buf(frame <> frame, ["foo"]) |> to(eq({<<>>, ["foo", body, body]})))
    end

    it "deframes a valid message, rejects misframed data, identifies partial messages and maintains accumulation" do
      {frame, body} = valid_frame()
      expect(Framer.reduce_buf(frame <> buffer_of_garbage() <> start_of_msg(), [])) |> to(eq({start_of_msg(), [body]}))
      expect(Framer.reduce_buf(frame <> buffer_of_garbage() <> start_of_msg(), ["foo"])) |> to(eq({start_of_msg(), ["foo", body]}))
    end
  end
end
