defmodule MahouTest do
  use ExUnit.Case
  doctest Mahou

  test "greets the world" do
    assert Mahou.hello() == :world
  end
end
