defmodule Device.Uart.WateringCanFramerSpec do
  @moduledoc false
  use ESpec

  alias Device.Uart.WateringCanFramer, as: Framer

  def valid_frame do
    body = <<0xDEADBEEF::integer-little-unsigned-size(32)>>

    framed = <<
      2::size(8),
      byte_size(body)::integer-little-unsigned-size(16),
      body::bitstring,
      Framer.chk(body)::integer-little-unsigned-size(8),
      3::size(8)
    >>

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
      expect(Framer.reduce_buf(<<0xFF::size(128)>>, []) |> to(eq({<<>>, []})))
      expect(Framer.reduce_buf(<<0xFF::size(128)>>, ["foo"]) |> to(eq({<<>>, ["foo"]})))
    end

    it "identifies partial messages and maintains accumulation" do
      expect(Framer.reduce_buf(<<2::size(8)>>, []) |> to(eq({<<2::size(8)>>, []})))
      expect(Framer.reduce_buf(<<2::size(8)>>, ["foo"]) |> to(eq({<<2::size(8)>>, ["foo"]})))
    end

    it "rejects misframed data, identifies partial messages and maintains accumulation" do
      expect(Framer.reduce_buf(<<0xFF::size(128), 2::size(8)>>, []) |> to(eq({<<2::size(8)>>, []})))
      expect(Framer.reduce_buf(<<0xFF::size(128), 2::size(8)>>, ["foo"]) |> to(eq({<<2::size(8)>>, ["foo"]})))
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
      expect(Framer.reduce_buf(frame <> <<0xFF::size(128), 2::size(8)>>, []) |> to(eq({<<2::size(8)>>, [body]})))
      expect(Framer.reduce_buf(frame <> <<0xFF::size(128), 2::size(8)>>, ["foo"]) |> to(eq({<<2::size(8)>>, ["foo", body]})))
    end
  end
end
