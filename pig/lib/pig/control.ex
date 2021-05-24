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
    active_deploys =
      "agma"
      |> Query.new
      |> Client.query_metadata
      |> Enum.flat_map(&(&1["metadata"]["managed_container_names"]))
      |> Enum.map(&String.split(&1, "..", parts: 3))
      |> Enum.group_by(&Enum.at(&1, 1))
      |> Map.new

    for deploy <- deploys, is_struct(deploy) do
      k = Crush.format_deploy deploy
      k_scale = k <> ":scale-until"
      ns_and_name = "#{deploy.namespace || "default"}.#{deploy.name}"
      current_scale = Enum.count(active_deploys[ns_and_name] || [])
      # Logger.info "control: checking #{ns_and_name}, scale=#{current_scale}, expected=#{deploy.scale}"

      cond do
        deploy.scale > current_scale ->
          case Crush.get_decode(k_scale) do
            {:ok, []} ->
              Logger.warn "control: deploy #{ns_and_name} scale: #{current_scale} != #{deploy.scale}"
              Crush.set k_scale, :os.system_time(:millisecond) + @scale_timeout
              for _ <- 0..(deploy.scale - current_scale - 1) do
                Deployer.deploy deploy
              end

            {:ok, {last_scale, _}} ->
              now = :os.system_time(:millisecond)
              if now > last_scale do
                Crush.del k_scale
              end

            _ -> nil
          end

        deploy.scale < current_scale ->
          case Crush.get_decode(k_scale) do
            {:ok, []} ->
              Logger.warn "control: deploy #{ns_and_name} scale: #{current_scale} != #{deploy.scale}"
              Crush.set k_scale, :os.system_time(:millisecond) + @scale_timeout
              active_deploys[ns_and_name]
              |> Enum.take(current_scale - deploy.scale)
              |> Enum.map(fn [mahou, ns_and_name, discrim] ->
                "#{mahou}..#{ns_and_name}..#{discrim}"
              end)
              |> Enum.each(fn full_name ->
                Deployer.undeploy full_name
              end)

            {:ok, {last_scale, _}} ->
              now = :os.system_time(:millisecond)
              if now > last_scale do
                Crush.del k_scale
              end

            _ -> nil
          end

        deploy.scale == current_scale ->
          case Crush.get_key(k_scale) do
            {:ok, []} -> nil
            {:ok, [_, _]} ->
              Logger.info "control: #{ns_and_name} scaled!"
              Crush.del k_scale

            _ -> nil
          end
      end
    end

    tick()
    {:noreply, :ok}
  rescue
    e ->
      Logger.error "control: encountered unexpected exception:\n#{Exception.format :error, e, __STACKTRACE__}"
      tick()
      {:noreply, :ok}
  end
end
