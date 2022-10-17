defmodule Device.Uart.WateringCanFramer do
  @moduledoc """
  Each message is framed like so, with 2 marking the start of message and 3 marking the end of message
  <<2::size(8), body_len_bytes::integer-little-unsigned-size(16), body::bytes(body_len_bytes), xor_chk::integer-little-unsigned-size(8), 3::size(8)>>

  Generally:
  <<SOM, BODY_LEN, BODY, CHK, EOM, maybe-more>>

  Where the xor_chk is the xored value of all body bytes; kept simple for simplicity's sake :)
  """
  @behaviour Nerves.UART.Framing

  defmodule State do
    @moduledoc false
    @keys ~w/rx_buf name/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            rx_buf: binary(),
            name: String.t()
          }
  end

  @impl Nerves.UART.Framing
  def add_framing(data, state) do
    body = if is_binary(data), do: data, else: :erlang.term_to_binary(data)

    framed = <<
      2::size(8),
      byte_size(body)::integer-little-unsigned-size(16),
      body::binary,
      chk(body)::integer-little-unsigned-size(8),
      3::size(8)
    >>

    {:ok, framed, state}
  end

  @impl Nerves.UART.Framing
  def flush(direction, state) when direction in ~w/receive both/a, do: %State{state | rx_buf: <<>>}
  def flush(_direction, state), do: state

  @impl Nerves.UART.Framing
  def frame_timeout(state), do: {:ok, [], %State{state | rx_buf: <<>>}}

  @impl Nerves.UART.Framing
  def init(name), do: {:ok, %State{rx_buf: <<>>, name: name}}

  @impl Nerves.UART.Framing
  def remove_framing(new_data, state) do
    case reduce_buf(state.rx_buf <> new_data) do
      {<<>>, deframed} -> {:ok, deframed, %State{state | rx_buf: <<>>}}
      {remainder, deframed} -> {:in_frame, deframed, %State{state | rx_buf: remainder}}
    end
  end

  @spec chk(bitstring()) :: integer()
  def chk(body) do
    f = fn
      _f, <<>>, acc -> acc
      f, <<next::integer-little-size(8), rest::bitstring>>, acc -> f.(f, rest, Bitwise.bxor(acc, next))
    end

    f.(f, body, 0)
  end

  @spec reduce_buf(binary(), list(binary())) :: {binary(), list(binary())}
  def reduce_buf(buf, acc \\ [])

  # all done
  def reduce_buf(<<>>, acc), do: {<<>>, acc}

  def reduce_buf(
        <<2::size(8), body_len_bytes::integer-little-unsigned-size(16), body::bytes-size(body_len_bytes), xor_chk::integer-little-unsigned-size(8), 3::size(8),
          remainder::binary>>,
        acc
      ) do
    # Have whole message. Check the checksum and if it matches include it, if no checksum match discard and move on
    if chk(body) == xor_chk, do: reduce_buf(remainder, acc ++ [body]), else: reduce_buf(remainder, acc)
  end

  def reduce_buf(<<2::size(8), _remainder::binary>> = buf, acc) do
    # Have SOM and some amount of data but not a whole message: we are in the middle of a frame so return the partial frame
    {buf, acc}
  end

  def reduce_buf(<<_garbo::size(8), remainder::binary>>, acc) do
    # missing start-of-message byte
    reduce_buf(remainder, acc)
  end
end
