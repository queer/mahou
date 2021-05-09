defmodule Agma.Consumer do
  use Singyeong.Consumer
  alias Mahou.Message
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
      Logger.warn "pig: ts: clock drift > 1000ms"
    end
    m
  end

  defp process_event(_), do: :ok
end
