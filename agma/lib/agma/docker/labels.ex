defmodule Agma.Docker.Labels do
  @managed "mahou:agma:docker:container:managed"
  @namespace "mahou:agma:docker:container:namespace"

  def managed, do: @managed
  def namespace, do: @namespace
end
