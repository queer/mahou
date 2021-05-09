defmodule Pig.Config do
  def c(k), do: Application.get_env :pig, k

  def singyeong_dsn, do: c :singyeong_dsn
  def crush_dsn, do: c :crush_dsn
end
