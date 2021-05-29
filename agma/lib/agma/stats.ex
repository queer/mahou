defmodule Agma.Stats do
  use GenServer
  alias Agma.Docker
  alias Agma.Docker.Labels
  require Logger

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  def init(_) do
    Logger.info "stats: #{length Docker.managed_container_ids()} managed containers at boot."
    tick()
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    # TODO: Track resource limit usage so that it can be queried against in singyeong
    cpus = :erlang.system_info :logical_processors
    cpu_util = :cpu_sup.util()
    cpu_arch =
      :system_architecture
      |> :erlang.system_info
      |> to_string
      |> case do
        "x86_64" <> _ -> "x86_64"
        arch -> arch
      end

    os_family =
      case :os.type() do
        {:unix, :linux} -> "linux"
        {:unix, :darwin} -> "macos"
        {:win32, _} -> "windows"
      end

    deployment_ports =
      Docker.managed_containers()
      |> Enum.map(fn container ->
        public_port =
          container.ports
          |> Enum.filter(&(&1.ip == "0.0.0.0"))
          |> case do
            [] -> nil
            ports -> hd ports
          end

        {container.labels[Labels.deployment()], public_port}
      end)
      |> Enum.reject(fn {_, port} -> port == nil end)
      |> Enum.map(fn {deploy, port} -> {deploy, port.public_port} end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    %{
      total_memory: mem_total,
      free_memory: mem_free,
    } = Map.new :memsup.get_system_memory_data()

    %{
      cpu_count: %{
        type: "integer",
        value: cpus,
      },
      cpu_util: %{
        type: "float",
        value: cpu_util,
      },
      cpu_arch: %{
        type: "string",
        value: cpu_arch,
      },
      mem_total: %{
        type: "integer",
        value: mem_total,
      },
      mem_free: %{
        type: "integer",
        value: mem_free,
      },
      container_names: %{
        type: "list",
        value: Docker.container_names(),
      },
      container_ids: %{
        type: "list",
        value: Docker.container_ids(),
      },
      running_container_names: %{
        type: "list",
        value: Docker.running_container_names(),
      },
      running_container_ids: %{
        type: "list",
        value: Docker.running_container_ids(),
      },
      managed_container_ids: %{
        type: "list",
        value: Docker.managed_container_ids(),
      },
      managed_container_names: %{
        type: "list",
        value: Docker.managed_container_names(),
      },
      container_count: %{
        type: "integer",
        value: Enum.count(Docker.managed_container_ids()),
      },
      deployments: %{
        type: "map",
        value: Docker.deployments(),
      },
      deployment_ports: %{
        type: "map",
        value: deployment_ports,
      },
      os_family: %{
        type: "string",
        value: os_family,
      }
    }
    |> Singyeong.Client.update_metadata

    tick()

    {:noreply, state}
  rescue
    e ->
      Logger.error "stats: encountered unexpected exception:\n#{Exception.format :error, e, __STACKTRACE__}"
      tick()
      {:noreply, state}
  end

  defp tick() do
    Process.send_after self(), :tick, 100
  end
end
