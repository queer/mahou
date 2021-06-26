defmodule Agma.Docker do
  use Tesla
  alias Agma.Docker.{Container, Labels}
  alias Agma.Utils
  alias Mahou.Format.App
  require Logger

  @base_url "http+unix://%2Fvar%2Frun%2Fdocker.sock/v1.41"
  @base_port 6666
  @port_range 666

  plug Tesla.Middleware.BaseUrl, @base_url
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
  Pull the specified image
  """
  def pull_image(image) do
    Logger.info "docker: pulling image: #{image}"

    case HTTPoison.request(:post, @base_url <> "/images/create?fromImage=#{image}", "") do
      {:ok, _} ->
        {:ok, :ok}

      {:error, _} = e -> e
    end

    # case post("/images/create?fromImage=#{image}", nil) do
    #   {:ok, %Tesla.Env{status: 200, body: body}} ->
    #     {:ok, body}

    #   {:ok, %Tesla.Env{body: body, status: status}} ->
    #     {:error, {:unexpected_status, status, body}}

    #   {:error, _} = e -> e
    # end
  end

  @doc """
  Create a new container
  """
  def create(%App{
    name: name,
    namespace: ns,
    image: image,
    limits: _,
    env: env,
    inner_port: inner_port,
  } = app) do
    # TODO: Error-check image names
    if not String.match?(name, ~r/^\/?[a-zA-Z0-9][a-zA-Z0-9_.-]+$/) do
      {:error, :invalid_name}
    else
      ns = ns || "default"

      used_ports =
        running_containers()
        |> Enum.flat_map(&(&1.ports))
        |> Enum.map(&(&1.public_port))
        |> MapSet.new

      port =
        Enum.find @base_port..(@base_port + @port_range), fn port ->
          not MapSet.member?(used_ports, port)
        end

      Logger.debug "docker: assigning port #{port}"
      container_name = app_name name, ns

      labels =
        %{
          Labels.deployment() => "mahou:deployment:#{ns}:#{name}",
          Labels.namespace() => ns,
          Labels.managed() => "true",
          Labels.name_cache() => container_name,
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

      case post("/containers/create?name=#{container_name}", opts) do
        {:ok, %Tesla.Env{status: 201, body: body}} ->
          {:ok, body}

        {:ok, %Tesla.Env{status: 404, body: %{"message" => "No such image:" <> _}}} ->
          case pull_image(image) do
            {:ok, _} -> create app
            {:error, {:unexpected_status, 404, _}} -> {:error, :image_not_found}
            {:error, _} = e -> IO.inspect e, limit: :infinity, printable_limit: :infinity, label: "OH FUCK DOCKER WHY"
          end

        {:ok, %Tesla.Env{body: body, status: status}} ->
          {:error, {:unexpected_status, status, body}}

        {:error, _} = e ->
          Logger.warn "ERROR RETURN"
          IO.inspect e, label: "Unexpected error"
          e
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
    Enum.map managed_containers(), &(&1.labels[Labels.name_cache()])
  end

  def managed_container_ids do
    Enum.map managed_containers(), &(&1.id)
  end

  def containers_with_versions do
    managed_containers() |> Enum.map(&{&1.labels[Labels.name_cache()], &1.image}) |> Map.new
  end

  def app_name(%App{name: name, namespace: ns}), do: app_name name, ns
  def app_name(name, ns), do: "mahou..#{ns || "default"}.#{name}..#{Ksuid.generate()}"

  def deployments do
    {:ok, containers} = containers()
    containers
    |> Enum.map(&(&1.labels[Labels.deployment()]))
    |> Enum.reject(&(&1 == nil))
    |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
  end
end
