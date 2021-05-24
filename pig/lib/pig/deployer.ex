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

  def undeploy(name) do
    msg =
      %ChangeContainerStatus{
        name: name,
        command: :stop,
      }
      |> Message.create
      |> Message.encode(json: true)

    Logger.info "Changing status of #{name}"

    "agma"
    |> Query.new
    |> Query.with_op(:"$contains", "managed_container_names", "#{name}")
    |> Client.proxy("/api/v1/status", :post, msg)
  end
end
