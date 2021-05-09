use Mix.Config

{base_flags, _argv} = OptionParser.parse_head! System.argv(), [aliases: [d: :debug], switches: [debug: :boolean]]

config :logger, level: :info
config :logger, :console, format: "[$level] $message\n"

if Mix.env() == :prod do
  config :wand,
    singyeong_dsn: System.get_env("SINGYEONG_DSN")
else
  config :wand,
    singyeong_dsn: System.get_env("SINGYEONG_DSN") || "singyeong://wand:password@localhost:4567"
end
