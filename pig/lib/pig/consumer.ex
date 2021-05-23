defmodule Pig.Consumer do
  use Singyeong.Consumer
  alias Mahou.Message
  alias Mahou.Message.{
    ChangeContainerStatus,
    CreateContainer,
  }
  alias Pig.{Crush, Deployer}
  require Logger

  def start_link do
    Consumer.start_link __MODULE__
  end

  def handle_event({:send, _nonce, event}) do
    process event
  end

  def handle_event({:broadcast, _nonce, event}) do
    process event
  end

  defp process(event) do
    event
    |> Message.decode
    |> inspect_ts
    |> Map.get(:payload)
    |> process_event
    :ok
  end

  defp inspect_ts(%Message{ts: ts} = m) do
    if abs(ts - :os.system_time(:millisecond)) > 1_000 do
      Logger.warn "wand: ts: clock drift > 1000ms"
    end
    m
  end

  def process_event(%CreateContainer{apps: apps}) do
    illegal_names = Enum.filter apps, &String.contains?(&1.name, ".")

    if Enum.count(illegal_names) > 0 do
      # TODO: Relay error to the client
      Logger.error "deploy: apps: illegal names: #{inspect illegal_names}"
      nil
    else
      Logger.info "deploy: apps:\n* #{apps |> Enum.map(&("#{&1.namespace}:#{&1.name} -> #{&1.image}")) |> Enum.join("\n* ")}"
      Logger.info "deploy: apps: #{Enum.count apps} total"

      for app <- apps do
        {:ok, _} = Crush.set Crush.format_deploy(app), app
      end
    end
  rescue
    e -> IO.inspect e, pretty: true, label: "err"
  end

  def process_event(%ChangeContainerStatus{name: name, namespace: ns, command: cmd} = msg) do
    Logger.info "status: app: #{ns}:#{name}: sending :#{cmd}"
    Deployer.undeploy msg
  end
end
