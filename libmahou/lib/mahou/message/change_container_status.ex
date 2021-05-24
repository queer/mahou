defmodule Mahou.Message.ChangeContainerStatus do
  use TypedStruct

  @type command() ::
    :start
    | :stop
    | :restart
    | :kill

  typedstruct do
    field :name, String.t()
    field :command, command()
  end
end
