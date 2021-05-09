defmodule Pig.Consumer do
  use Singyeong.Consumer
  alias Mahou.Format.App
  alias Mahou.Format.App.Limits
  alias Mahou.Message
  alias Mahou.Message.{
    ChangeContainerStatus,
    CreateContainer,
  }
  alias Singyeong.{Client, Query}
  require Logger

  def start_link do
    Consumer.start_link __MODULE__
  end

  def handle_event({:send, _nonce, event}) do
    process event
  end

  def handle_event({:broadcast, _nonce, event}) do
    process event
  end

  defp process(event) do
    event
    |> Message.decode
    |> inspect_ts
    |> Map.get(:payload)
    |> process_event
    :ok
  end

  defp inspect_ts(%Message{ts: ts} = m) do
    if abs(ts - :os.system_time(:millisecond)) > 1_000 do
      Logger.warn "wand: ts: clock drift > 1000ms"
    end
    m
  end

  def process_event(%CreateContainer{apps: apps}) do
    Logger.info "deploy: apps:\n* #{apps |> Enum.map(&("#{&1.namespace}:#{&1.name} -> #{&1.image}")) |> Enum.join("\n* ")}"
    Logger.info "deploy: apps: #{Enum.count apps} total"

    for %App{limits: %Limits{cpu: _, ram: ram}} = app <- apps do
      # TODO: Ensure a machine exists that can process the request
      # TODO: Ensure no container name duping across machines?
      msg =
        %CreateContainer{
          apps: [app],
        }
        |> Message.create
        |> Message.encode(json: true)

      "agma"
      |> Query.new
      |> Query.with_op(:"$gte", "mem_free", ram * 1024 * 1024)
      |> Query.with_op(:"$lt", "container_count", 255)
      |> Query.with_selector(:"$min", "container_count")
      |> Client.proxy("/api/v1/create", :post, msg)
    end
  end

  def process_event(%ChangeContainerStatus{id: id, name: name, namespace: ns, command: cmd} = msg) do
    Logger.info "status: app: #{ns}:#{name}: sending :#{cmd}"

    ns = ns || "default"

    out =
      msg
      |> Message.create
      |> Message.encode(json: true)

    "agma"
    |> Query.new
    |> Query.with_logical_op(
      :"$or",
      %{
        "path" => "/running_container_ids",
        "op" => "$contains",
        "to" => %{"value" => id},
      }, %{
        "path" => "/running_container_names",
        "op" => "$contains",
        "to" => %{"value" => "/mahou-#{ns}_#{name}"},
      }
    )
    |> Client.proxy("/api/v1/status", :post, out)
  end
end
