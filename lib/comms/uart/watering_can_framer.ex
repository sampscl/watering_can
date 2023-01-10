defmodule Comms.Uart.WateringCanFramer do
  @moduledoc """
  UART framing behaviour for the watering can protocol, used with Circuits.UART.

  See README.md for framing bit layout.

  ## Telemetry
  The following telemetry is produced, the events' measurements include %{utc_now: DateTime.t()}:

    * `[Comms.Uart.WateringCanFramer, :add_framing]` with metadata `%{framed: <<framed_data>>, name: uart_name}`
    * `[Comms.Uart.WateringCanFramer, :flush]` with metadata `%{direction: direction, name: uart_name}`
    * `[Comms.Uart.WateringCanFramer, :frame_timeout]` with metadata `%{rx_buf: <<buf>>, name: uart_name}`
    * a span: `[Comms.Uart.WateringCanFramer, :remove_framing]` with metadata `%{rx_buf: <<buf>>, name: uart_name, result: {:ok, deframed, new_state} | {:in_frame, deframed, new_state}}`
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

    :telemetry.execute([Comms.Uart.WateringCanFramer, :add_framing], %{utc_now: DateTime.utc_now()}, %{framed: framed, name: state.name})
    {:ok, framed, state}
  end

  @impl Nerves.UART.Framing
  def flush(direction, state) do
    :telemetry.execute([Comms.Uart.WateringCanFramer, :flush], %{utc_now: DateTime.utc_now()}, %{direction: direction, name: state.name})

    if direction in ~w/receive both/a do
      %State{state | rx_buf: <<>>}
    else
      state
    end
  end

  @impl Nerves.UART.Framing
  def frame_timeout(state) do
    :telemetry.execute([Comms.Uart.WateringCanFramer, :frame_timeout], %{utc_now: DateTime.utc_now()}, %{rx_buf: state.rx_buf, name: state.name})
    {:ok, [], %State{state | rx_buf: <<>>}}
  end

  @impl Nerves.UART.Framing
  def init(name), do: {:ok, %State{rx_buf: <<>>, name: name}}

  @impl Nerves.UART.Framing
  # @spec remove_framing(binary(), State.t()) :: {:ok | :in_frame, list(binary()), State.t()}
  def remove_framing(new_data, %State{} = state) do
    telem_result =
      :telemetry.span([Comms.Uart.WateringCanFramer, :remove_framing], %{new_data: new_data, rx_buf: state.rx_buf, name: state.name}, fn ->
        rx_buf = state.rx_buf <> new_data

        result =
          case reduce_buf(rx_buf, []) do
            {<<>>, deframed} ->
              {:ok, deframed, %State{state | rx_buf: <<>>}}

            {remainder, deframed} ->
              {:in_frame, deframed, %State{state | rx_buf: remainder}}
          end

        {result, %{rx_buf: rx_buf, name: state.name, result: result}}
      end)

    case telem_result do
      {:ok, msg_list, %State{} = _updated_state} = result when is_list(msg_list) -> result
      {:in_frame, msg_list, %State{} = _updated_state} = result when is_list(msg_list) -> result
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
