defmodule Mahou.Message.CreateContainer do
  use TypedStruct
  alias Mahou.Format.App

  typedstruct do
    field :apps, [App.t()]
  end
end
