defmodule Agma.Docker.Labels do
  @managed "mahou:agma:docker:container:managed"
  @namespace "mahou:agma:docker:container:namespace"
  @deployment "mahou:agma:docker:container:deployment"

  def managed, do: @managed
  def namespace, do: @namespace
  def deployment, do: @deployment
end
