import Config

config :pig,
  singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://pig:password@localhost:4567",
  crush_dsn: System.get_env("CRUSH_DSN") || "http://localhost:7654/"

config :pig, PigWeb.Endpoint,
  server: true,
  code_reloader: false
