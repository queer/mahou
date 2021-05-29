import Config

config :agma,
  singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://agma:password@localhost:4567"

config :agma, AgmaWeb.Endpoint,
  server: true,
  code_reloader: false
