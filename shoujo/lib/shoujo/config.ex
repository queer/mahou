defmodule Shoujo.Config do
  def c(k), do: Application.get_env :shoujo, k

  def singyeong_dsn, do: c :singyeong_dsn
end
