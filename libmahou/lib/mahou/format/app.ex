defmodule Mahou.Format.App do
  use TypedStruct

  typedstruct do
    # The name of the application.
    field :name, String.t(), enforce: true
    # The namespace of the application. If `nil`, defaults to `default`.
    field :namespace, String.t() | nil
    # The Docker image to pull and run.
    field :image, String.t(), enforce: true
    # CPU / RAM limits to be enforced on the container.
    field :limits, __MODULE__.Limits.t(), enforce: true
    # Environment variables to be set on the container.
    field :env, %{required(String.t()) => String.t()}
    # The inner port of the container, ie the port that the application inside
    # the container runs on.
    field :inner_port, non_neg_integer() | nil
    # How many containers of this application to run. Must be at least 0.
    # I don't know why you'd want it to be zero, but you do you ig.
    field :scale, non_neg_integer(), enforce: true
    # The domain that should be forwarded to this application. Applies to HTTP
    # proxying only.
    # CURRENTLY UNSUPPORTED.
    field :domain, String.t() | nil
    # The path that should be forwarded to this application. Applies to HTTP
    # proxying only.
    # CURRENTLY UNSUPPORTED.
    field :path, String.t() | nil
    # The outer port of the container, ie. the port on the TCP proxy that this
    # application should have reserved. If multiple applications set the same
    # outer port, traffic will be load-balanced over all of them.
    field :outer_port, non_neg_integer() | nil
  end

  typedstruct module: Limits do
    field :cpu, non_neg_integer()
    field :ram, non_neg_integer()
  end
end
