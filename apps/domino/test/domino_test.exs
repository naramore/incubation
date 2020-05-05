defmodule DominoTest do
  use ExUnit.Case
  doctest Domino

  test "greets the world" do
    assert Domino.hello() == :world
  end
end
