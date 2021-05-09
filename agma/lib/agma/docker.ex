defmodule Agma.Docker do
  use Tesla
  alias Agma.Docker.{Container, Labels}
  alias Agma.Utils
  alias Mahou.Format.App

  plug Tesla.Middleware.BaseUrl, "http+unix://%2Fvar%2Frun%2Fdocker.sock/v1.41"
  plug Tesla.Middleware.Headers, [{"content-type", "application/json"}]
  plug Tesla.Middleware.JSON

  #####################
  ## Raw API methods ##
  #####################

  @doc """
  List all containers on the system.
  """
  def containers do
    case get("/containers/json?all=1") do
      {:ok, %Tesla.Env{body: body}} ->
        containers =
          body
          |> Utils.snake()
          |> Enum.map(&Utils.atomify(&1, [:networks, :labels]))
          |> Enum.map(&Container.from/1)

        {:ok, containers}

      {:error, _} = e ->
        e
    end
  end

  @doc """
  Create a new
  """
  def create(%App{
    id: _,
    name: name,
    namespace: ns,
    image: image,
    limits: _,
    env: env,
    inner_port: inner_port,
  }) do
    # TODO: Error-check image names
    if not String.match?(name, ~r/^\/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$/) do
      {:error, :invalid_name}
    else

      # TODO: Iterate and find first available
      port = 6666

      labels =
        %{
          Labels.namespace() => ns || "default",
          Labels.managed() => "true",
        }

      host_config =
        %{
          "AutoRemove" => true,
        }

      host_config =
        if inner_port do
          ports =
            %{
              "#{inner_port}/tcp" => [%{
                "HostPort" => Integer.to_string(port)
              }],
              "#{inner_port}/udp" => [%{
                "HostPort" => Integer.to_string(port)
              }],
            }

          Map.put host_config, "PortBindings", ports
        else
          host_config
        end

      opts =
        %{
          "Image" => image,
          "Labels" => labels,
          "HostConfig" => host_config,
          "Env" => Enum.map((env || %{}), fn {k, v} -> "#{k}=#{v}" end),
        }

      # opts = if command, do: Map.put(opts, "Cmd", command), else: opts

      name = app_name name, ns
      case post("/containers/create?name=#{name}", opts) do
        {:ok, %Tesla.Env{status: 201, body: body}} ->
          {:ok, body}

        {:ok, %Tesla.Env{body: body, status: status}} ->
          {:error, {:unexpected_status, status, body}}

        {:error, _} = e -> e
      end
    end
  end

  def start(name_or_id) do
    container_state_request "start", name_or_id
  end

  def stop(name_or_id) do
    container_state_request "stop", name_or_id
  end

  def restart(name_or_id) do
    container_state_request "restart", name_or_id
  end

  def kill(name_or_id) do
    container_state_request "kill", name_or_id
  end

  def pause(name_or_id) do
    container_state_request "pause", name_or_id
  end

  def unpause(name_or_id) do
    container_state_request "unpause", name_or_id
  end

  defp container_state_request(kind, name_or_id) do
    case post("/containers/#{name_or_id}/#{kind}", nil) do
      {:ok, %Tesla.Env{status: 204}} ->
        {:ok, nil}

      {:ok, %Tesla.Env{status: 304}} ->
        {:ok, nil}

      {:ok, %Tesla.Env{body: body, status: status}} ->
        {:error, {:unexpected_status, status, body}}

      {:error, _} = e -> e
    end
  end

  #########################
  ## External helper API ##
  #########################

  def running_containers do
    {:ok, containers} = containers()
    Enum.filter containers, fn container -> container.state == "running" end
  end

  def running_container_names do
    Enum.flat_map running_containers(), &(&1.names)
  end

  def running_container_ids do
    Enum.map running_containers(), &(&1.id)
  end

  def container_names do
    {:ok, containers} = containers()
    Enum.flat_map containers, &(&1.names)
  end

  def container_ids do
    {:ok, containers} = containers()
    Enum.map containers, &(&1.id)
  end

  def managed_containers do
    {:ok, containers} = containers()
    Enum.filter containers, &(&1.labels[Labels.managed()] == "true")
  end

  def managed_container_names do
    Enum.flat_map managed_containers(), &(&1.names)
  end

  def managed_container_ids do
    Enum.map managed_containers(), &(&1.id)
  end

  def app_name(%App{name: name, namespace: ns}), do: app_name name, ns
  def app_name(name, ns), do: "mahou-#{ns || "default"}_#{name}"
end
