defmodule Pig.Deployer do
  alias Mahou.Format.App
  alias Mahou.Format.App.Limits
  alias Mahou.Message
  alias Mahou.Message.{
    ChangeContainerStatus,
    CreateContainer,
  }
  alias Singyeong.{Client, Query}
  require Logger

  def deploy(%App{limits: %Limits{cpu: _, ram: ram}} = app) do
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

  def undeploy(%App{namespace: ns, name: name}) do
    undeploy %ChangeContainerStatus{name: name, namespace: ns}
  end

  def undeploy(%ChangeContainerStatus{id: id, name: name, namespace: ns} = msg) do
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
