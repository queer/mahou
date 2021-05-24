defmodule Shoujo.Proxy do
  use GenServer
  require Logger

  def start_link(port) do
    GenServer.start_link __MODULE__, port, name: proxy_genserver_name(port)
  end

  def init(port) do
    {:ok, pid} = :ranch.start_listener(
      proxy_name(port),
      :ranch_tcp, [port: port],
      Shoujo.ProxyProtocol, [port: port]
    )

    {:ok, %{port: port}}
  end

  def handle_call(:stop,  _, state) do
    terminate nil, state
    {:reply, :ok, state}
  end

  def terminate(_, state) do
    Logger.info "proxy: port=#{state.port}: terminating proxy"
    :ranch.stop_listener proxy_name(state.port)
  end

  def proxy_genserver_name(port) do
    :"shoujo-proxy-#{port}"
  end

  def proxy_name(port) do
    :"shoujo-ranch-proxy-#{port}"
  end
end
