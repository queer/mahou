defmodule AgmaWeb.ContainerController do
  use AgmaWeb, :controller
  use Mahou.Docs
  alias Agma.Deployer
  alias Mahou.Message
  alias Mahou.Message.{ChangeContainerStatus, CreateContainer}

  @doc """
  Creates a container
  """
  @input CreateContainer
  @output nil
  def create(conn, _) do
    {:ok, body, conn} = read_body conn
    # TODO: lol check ts
    %Message{payload: %CreateContainer{apps: apps}} = Message.decode body, json: true

    # TODO: lol error checking
    Deployer.deploy apps

    json conn, %{}
  end

  @doc """
  Changes the status of the container, ex. stop, kill, freeze, etc.
  """
  @input ChangeContainerStatus
  @output nil
  def change_status(conn, _) do
    {:ok, body, conn} = read_body conn
    # TODO: lol check ts
    %Message{payload: %ChangeContainerStatus{} = msg} = Message.decode body, json: true

    # TODO: lol real retval checking
    Deployer.change_status msg

    json conn, %{}
  end
end
