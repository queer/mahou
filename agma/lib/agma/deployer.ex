defmodule Agma.Deployer do
  alias Agma.Docker
  alias Mahou.Message.ChangeContainerStatus
  require Logger

  def deploy(apps) do
    Logger.info "deploy: apps:\n* #{apps |> Enum.map(&("#{&1.namespace}:#{&1.name} -> #{&1.image}")) |> Enum.join("\n* ")}"
    Logger.info "deploy: apps: #{Enum.count apps} total"

    for app <- apps do
      name = Docker.app_name app
      {:ok, res} = Docker.create app

      Logger.info "deploy: app: created #{name}"
      Logger.debug "deploy: app: #{name}: #{inspect res, pretty: true}"
    end

    for app <- apps do
      name = Docker.app_name app
      {:ok, _} = Docker.start name

      Logger.info "deploy: app: started #{name}"
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
