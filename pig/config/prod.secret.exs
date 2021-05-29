use Mix.Config

secret_key_base =
  System.get_env("SECRET_KEY_BASE") || "eJZSnP96khJ3DmL34KkwBT4xDRT2p9h3"

config :pig, PigWeb.Endpoint,
  http: [
    port: 8080,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
# config :pig, PigWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
