defmodule Shoujo.Control do
  use GenServer
  alias Shoujo.Proxy
  alias Singyeong.{Client, Query}
  require Logger

  @tick_interval 1_000

  def start_link(_), do: GenServer.start_link __MODULE__, nil

  def init(_) do
    :ets.new :ports, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true]
    Logger.info "control: starting tick loop"
    tick()
    {:ok, nil}
  end

  def handle_info(:tick, previous_mappings) do
    deploys =
      "pig"
      |> Query.new
      |> Client.proxy("/api/deploys", :get)
      |> Enum.map(&{"mahou:deployment:#{&1["namespace"] || "default"}:#{&1["name"]}", {&1["outer_port"], &1["domain"], &1["path"]}})
      |> Map.new

    ports =
      "pig"
      |> Query.new
      |> Client.proxy("/api/ports", :get)

    port_mappings =
      deploys
      |> Map.keys
      |> Enum.map(fn key ->
        {port, domain, path} = deploys[key]
        {port, {ports[key], domain, path}}
      end)
      |> Enum.group_by(fn {port, _} -> port end, fn {_port, rest} -> rest end)

    all_ports = port_mappings |> Enum.map(&elem(&1, 0)) |> MapSet.new

    :ports
    |> :ets.tab2list
    |> Enum.map(&elem(&1, 0))
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn port ->
      unless MapSet.member?(all_ports, port) do
        pid =
          port
          |> Proxy.proxy_genserver_name
          |> Process.whereis

        if pid do
          GenServer.call pid, :stop
          DynamicSupervisor.terminate_child Shoujo.ProxySupervisor, pid
          Logger.info "control: proxy: terminated on port #{port}"
        end
      end
    end)

    Shoujo.ProxySupervisor
    |> DynamicSupervisor.which_children
    |> Enum.map(fn {_, pid, _, _} ->
      {:registered_name, name} = Process.info pid, :registered_name
      "shoujo-proxy-" <> port = Atom.to_string name
      port = String.to_integer port
      unless MapSet.member?(all_ports, port) do
        GenServer.call pid, :stop
        DynamicSupervisor.terminate_child Shoujo.ProxySupervisor, pid
        Logger.info "control: proxy: terminated on port #{port}"
      end
    end)

    Enum.each port_mappings, &:ets.insert(:ports, &1)

    port_mappings
    |> Map.keys
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn port ->
      port
      |> Proxy.proxy_genserver_name
      |> Process.whereis
      |> unless do
        DynamicSupervisor.start_child Shoujo.ProxySupervisor, {Proxy, port}
        Logger.info "control: created new proxy: port=#{port}"
      end
    end)

    tick()
    {:noreply, port_mappings}
  rescue
    e ->
      Logger.error "control: encountered unexpected exception:\n#{Exception.format :error, e, __STACKTRACE__}"
      tick()
      {:noreply, previous_mappings}
  end

  defp tick() do
    Process.send_after self(), :tick, @tick_interval
  end
end
