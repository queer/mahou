defmodule Agma.Deployer do
  alias Agma.Docker
  alias Mahou.Message.ChangeContainerStatus
  require Logger

  def deploy(apps) do
    Logger.info "deploy: apps:\n* #{apps |> Enum.map(&("#{&1.namespace}:#{&1.name} -> #{&1.image}")) |> Enum.join("\n* ")}"
    Logger.info "deploy: apps: #{Enum.count apps} total"

    for app <- apps do
      name = Docker.app_name app
      case Docker.create(app) do
        {:ok, res} ->
          Logger.info "deploy: app: created #{name}"
          Logger.debug "deploy: app: #{name}: #{inspect res, pretty: true}"
          id = res["Id"]
          {:ok, _} = Docker.start id
          Logger.info "deploy: app: started #{name}"

        {:error, {:unexpected_status, 409, %{"message" => "Conflict. The container name " <> _}}} ->
          Logger.info "deploy: app: not recreating #{name}"
      end
    end
  end

  def change_status(%ChangeContainerStatus{
    id: _id, # TODO: Use someday?
    name: name,
    namespace: ns,
    command: command,
  }) do
    app = Docker.app_name name, ns
    Logger.info "status: app: #{app}: sending :#{command}"
    case command do
      :stop -> {:ok, _} = Docker.stop app
      :kill -> {:ok, _} = Docker.kill app
      _ -> raise "wtf is #{command} (HINT: not implemented)"
    end
  end
end
