# WateringCan

Irrigation system control and UI

Interesting: https://github.com/nerves-project/nerves_system_x86_64/blob/main/priv/run-qemu.sh

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:

- `export MIX_TARGET=my_target` or prefix every command with
  `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
- Install dependencies with `mix deps.get`
- Create firmware with `mix firmware`
- Burn to an SD card with `mix burn`

## Learn more

- Official docs: https://hexdocs.pm/nerves/getting-started.html
- Official website: https://nerves-project.org/
- Forum: https://elixirforum.com/c/nerves-forum
- Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
- Source: https://github.com/nerves-project/nerves

## Watering Can Protocol Framing

Each message is framed with 2 marking the start of message and 3 marking the end of message:

```elixir
<<
  2::size(8),
  body_len_bytes::integer-little-unsigned-size(16),
  body::bytes-size(body_len_bytes),
  xor_chk::integer-little-unsigned-size(8),
  3::size(8)
>>
```

Generally:

```elixir
<<SOM, BODY_LEN, BODY, CHK, EOM, maybe-more>>
```

Where the xor_chk is the xored value of all body bytes; kept simple for simplicity's sake :)

## Soil Moisture Sensor Measurements

the SMS measurement is wrapped in a watering can protocol frame with the following frame body:

```elixir
<<
  battery_pct::integer-little-unsigned-size(8),
  moisture_pct::integer-little-unsigned-size(8)
>>
```

## Running in qemu

```bash
MIX_TARGET=x86_64 mix firmware.image scratch/x86_64.img
qemu-system-x86_64 \
    -drive file="scratch/x86_64.img",if=virtio,format=raw \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::10022-:22 \
    -serial stdio
```
