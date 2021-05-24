import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n"

config :shoujo,
  singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://shoujo:password@localhost:4567"
