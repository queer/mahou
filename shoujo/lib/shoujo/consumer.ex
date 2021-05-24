defmodule Shoujo.Consumer do
  use Singyeong.Consumer

  def start_link do
    Consumer.start_link __MODULE__
  end

  def handle_event(event) do
    IO.inspect event, label: "unhandled shoujo event"
  end
end
