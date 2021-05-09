defmodule WandTest do
  use ExUnit.Case
  doctest Wand

  test "greets the world" do
    assert Wand.hello() == :world
  end
end
