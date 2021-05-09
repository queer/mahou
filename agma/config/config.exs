# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :agma, AgmaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "o46Y9nQPeuH+6pTrVWxbIcVIPHp7DlbVJziMjOg662aw7xEMsDuqh04UtmHjaVyd",
  render_errors: [view: AgmaWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Agma.PubSub,
  live_view: [signing_salt: "TLbs89UN"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, :adapter, Tesla.Adapter.Hackney

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
