defmodule Mahou.Format.App do
  use TypedStruct

  typedstruct do
    field :id, String.t() | nil
    field :name, String.t(), enforce: true
    field :namespace, String.t() | nil
    field :image, String.t(), enforce: true
    field :limits, __MODULE__.Limits.t(), enforce: true
    field :env, %{required(String.t()) => String.t()}
    field :inner_port, non_neg_integer() | nil
    field :scale, non_neg_integer(), enforce: true
  end

  typedstruct module: Limits do
    field :cpu, non_neg_integer()
    field :ram, non_neg_integer()
  end
end
