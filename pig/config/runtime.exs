use Mix.Config

if Mix.env() == :prod do
  config :pig,
    singyeong_dsn: System.get_env("SINGYEONG_DSN")
end
