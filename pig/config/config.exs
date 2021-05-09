use Mix.Config

config :pig, PigWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NzlepdtYeWjdDftHKSzESzrhU0B4ADlLjCPXJXy44t2SkJaujDvse8io0ra4xgwI",
  render_errors: [view: PigWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Pig.PubSub,
  live_view: [signing_salt: "3l+bMvyq"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
