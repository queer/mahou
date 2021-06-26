defmodule Pig.Control do
  use GenServer
  alias Pig.{Crush, Deployer}
  alias Singyeong.{Client, Query}
  require Logger

  @tick_interval 100
  @scale_timeout 5 * 60 * 1_000 # 5m

  def start_link(_), do: GenServer.start_link __MODULE__, :ok, name: __MODULE__

  def init(_) do
    tick()
    {:ok, :ok}
  end

  defp tick() do
    Process.send_after self(), :tick, @tick_interval
  end

  def handle_info(:tick, _) do
    deploys = Crush.deployments()
    metadata =
      "agma"
      |> Query.new
      |> Client.query_metadata
      |> case do
        # nil happens if we have a single agma node that just booted but hasn't
        # yet found its managed containers.
        nil -> []
        elem -> elem
      end

    active_deploys =
      metadata
      |> Enum.flat_map(&(&1["metadata"]["managed_container_names"] || []))
      |> Enum.map(&String.split(&1, "..", parts: 3))
      |> Enum.group_by(&Enum.at(&1, 1))
      |> Map.new

    deploy_versions =
      metadata
      |> Enum.flat_map(&(&1["metadata"]["containers_with_versions"]))
      |> Map.new

    for deploy <- deploys, is_struct(deploy) do
      current_scale = Enum.count(active_deploys[ns_and_name(deploy)] || [])
      # Logger.info "control: checking #{ns_and_name(deploy)}, scale=#{current_scale}, expected=#{deploy.scale}"

      # Try to deploy new images as needed
      target = Enum.find deploy_versions, fn {k, v} -> String.contains?(k, ns_and_name(deploy)) and v != deploy.image end
      case target do
        {name, image} ->
          # TODO: Debounce
          Logger.info "control: roll: undeploy #{name} (#{image} != #{deploy.image})"
          Deployer.undeploy name

        nil -> nil
      end

      # Actually scale
      last_scale_metadata =
        deploy
        |> scale_key
        |> Crush.get_decode
        |> case do
          {:ok, []} -> {:ok, false, nil}
          {:ok, {last_scale, _}} -> {:ok, true, last_scale}
          _ -> {:error, false, nil}
        end

      with {:scale, false} <- {:scale, deploy.scale == current_scale},
           {:metadata, {scale_check_status, false, _last_scale}} <- {:metadata, last_scale_metadata},
           {:status, :ok} <- {:status, scale_check_status} do
        Logger.info "control: scaling #{ns_and_name(deploy)}"
        scale_service active_deploys, deploy, current_scale
      else
        {:metadata, {:ok, true, last_scale}} ->
          # awaiting_scale? == true, cleanup if timeout
          now = :os.system_time :millisecond
          if now > last_scale do
            Logger.info "control: #{ns_and_name(deploy)}: cleanup timeout key"
            Crush.del scale_key(deploy)
          end

        {:scale, true} ->
          # Fully scaled, cleanup timeout key
          # Logger.info "control: #{ns_and_name(deploy)} scaled!"
          Crush.del scale_key(deploy)

        {:metadata, {_, _, _}} -> nil
        {:status, :error} -> nil
      end
    end

    tick()
    {:noreply, :ok}
  rescue
    HTTPoison.Error ->
      tick()
      {:noreply, :ok}

    e ->
      Logger.error "control: encountered unexpected exception:\n#{Exception.format :error, e, __STACKTRACE__}"
      tick()
      {:noreply, :ok}
  end

  defp scale_service(active_deploys, deploy, current_scale) do
    ns_and_name = ns_and_name deploy

    cond do
      deploy.scale > current_scale ->
        Logger.warn "control: deploy #{ns_and_name} scale: #{current_scale} != #{deploy.scale}"
        Crush.set scale_key(deploy), :os.system_time(:millisecond) + @scale_timeout
        for _ <- 0..(deploy.scale - current_scale - 1) do
          # Note: This blocks until the deploy is finished
          Deployer.deploy deploy
        end

      deploy.scale < current_scale ->
        Logger.warn "control: deploy #{ns_and_name} scale: #{current_scale} != #{deploy.scale}"
        Crush.set scale_key(deploy), :os.system_time(:millisecond) + @scale_timeout
        active_deploys[ns_and_name]
        |> Enum.take(current_scale - deploy.scale)
        |> Enum.map(fn [mahou, ns_and_name, discrim] ->
          "#{mahou}..#{ns_and_name}..#{discrim}"
        end)
        |> Enum.each(fn full_name ->
          Deployer.undeploy full_name
        end)
    end
  rescue
    _ in Jason.DecodeError ->
      # No remote, immediately attempt scaling again
      Crush.del scale_key(deploy)
      nil
  end

  defp deploy_key(deploy) do
    Crush.format_deploy deploy
  end

  defp scale_key(deploy) do
    deploy_key(deploy) <> ":scale-until"
  end

  defp ns_and_name(deploy) do
    "#{deploy.namespace || "default"}.#{deploy.name}"
  end
end
