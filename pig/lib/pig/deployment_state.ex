defmodule Pig.DeploymentState do
  use TypedStruct
  alias Mahou.Format.App

  typedstruct do
    field :image, String.t()
    field :name, String.t()
    field :namespace, String.t()
    field :scale, non_neg_integer(), default: 1
    field :raw, App
  end

  def from(%App{image: image, name: name, namespace: ns} = app) do
    %__MODULE__{
      image: image,
      name: name,
      namespace: ns || "default",
      raw: app,
    }
  end
end
