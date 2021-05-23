defmodule Agma.Docker.Labels do
  @managed "mahou:agma:docker:container:managed"
  @namespace "mahou:agma:docker:container:namespace"
  @deployment "mahou:agma:docker:container:deployment"
  @name_cache "mahou:agma:docker:container:name-cache"

  def managed, do: @managed
  def namespace, do: @namespace
  def deployment, do: @deployment
  def name_cache, do: @name_cache
end
