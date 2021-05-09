# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :sajeon, SajeonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zdmQYPEKOmS9Cbv6oUuiq9kdzeWpW4Hf62/H7VC0H4wo7M1tOK6rhGZ1CE9m+Z19",
  render_errors: [view: SajeonWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Sajeon.PubSub,
  live_view: [signing_salt: "F1Y1Q4LT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
