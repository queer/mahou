use Mix.Config

config :agma, AgmaWeb.Endpoint,
  http: [port: 4040],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console,
  format: "$metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :agma,
  singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://agma:password@localhost:4567"
