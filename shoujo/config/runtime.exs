import Config

config :shoujo,
  singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://shoujo:password@localhost:4567"
