defmodule Pig.Control do
  use GenServer
  alias Pig.Crush
  alias Singyeong.{Client, Query}
  require Logger

  @tick_interval 100

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
    if deploys != [] do
      IO.inspect deploys, pretty: true, label: "deploys"
    end
    active_deploys =
      "agma"
      |> Query.new
      |> Client.query_metadata
      |> Enum.reduce(%{}, fn x, acc ->
        Map.merge acc, x, fn _k, v1, v2 -> v1 + v2 end
      end)

    for deploy <- deploys do
      k = Crush.format_deploy(deploy)
      Logger.info "control: checking #{k}"
      if deploy.scale != active_deploys[k] do
        Logger.warn "control: deploy #{k} scale: #{active_deploys[k]} != #{deploy.scale}"
      end
    end

    tick()
    {:noreply, :ok}
  rescue
    e ->
      IO.inspect e
      # TODO: Handle e
      tick()
      {:noreply, :ok}
  end
end
