defmodule Agma.Stats do
  use GenServer
  alias Agma.Docker
  alias Mahou.Docs
  require Logger

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  def init(_) do
    Logger.info "[STATS] I'm mangling #{length Docker.managed_container_ids()} containers at boot."

    tick()

    docs = Docs.generate

    {:ok, %{docs: docs}}
  end

  def handle_info(:tick, state) do
    # TODO: Track resource limit usage so that it can be queried against in singyeong
    cpus = :erlang.system_info :logical_processors
    cpu_util = :cpu_sup.util()

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
    }
    |> Map.merge(%{
      Docs.docs_key() => state.docs,
    })
    |> Singyeong.Client.update_metadata

    tick()

    {:noreply, state}
  end

  defp tick() do
    Process.send_after self(), :tick, 100
  end
end
