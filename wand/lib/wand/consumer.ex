defmodule Wand.Consumer do
  use Singyeong.Consumer

  def start_link do
    Consumer.start_link __MODULE__
  end
end
