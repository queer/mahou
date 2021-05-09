defmodule Mahou.Config do
  defmacro __using__(_) do
    quote do
      alias Mahou.Format.App
      alias Mahou.Format.App.Limits
    end
  end
end
