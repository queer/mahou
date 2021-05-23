defmodule Pig.Application do
  @moduledoc false

  use Application
  alias Pig.Config

  def start(_type, _args) do
    dsn = Config.singyeong_dsn()

    children = [
      {Finch, name: Pig.Crush.Finch},
      PigWeb.Telemetry,
      Pig.Control,
      {Phoenix.PubSub, name: Pig.PubSub},
      PigWeb.Endpoint,
    ] ++ Mahou.Singyeong.supervisor(dsn, Pig.Consumer)

    opts = [strategy: :one_for_one, name: Pig.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PigWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
