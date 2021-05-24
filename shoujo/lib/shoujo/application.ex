defmodule Shoujo.Application do
  @moduledoc false

  use Application
  alias Shoujo.Config

  @impl true
  def start(_type, _args) do
    dsn = Config.singyeong_dsn()

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Shoujo.ProxySupervisor},
      Shoujo.Control,
    ] ++ Mahou.Singyeong.supervisor(dsn, Shoujo.Consumer)

    opts = [strategy: :one_for_one, name: Shoujo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
