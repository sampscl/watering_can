# Used by "mix format"
[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,integration,spec}/**/*.{ex,exs}",
    "rootfs_overlay/etc/iex.exs"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 160
]
