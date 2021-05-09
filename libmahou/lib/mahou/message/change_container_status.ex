defmodule Mahou.Message.ChangeContainerStatus do
  use TypedStruct

  @type command() ::
    :start
    | :stop
    | :restart
    | :kill

  typedstruct do
    field :id, String.t() | nil
    field :name, String.t() | nil
    field :namespace, String.t() | nil
    field :command, command()
  end
end
