defmodule ShoujoTest do
  use ExUnit.Case
  doctest Shoujo

  test "greets the world" do
    assert Shoujo.hello() == :world
  end
end
