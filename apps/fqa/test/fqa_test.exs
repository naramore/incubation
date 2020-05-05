defmodule FqaTest do
  use ExUnit.Case
  doctest Fqa

  test "greets the world" do
    assert Fqa.hello() == :world
  end
end
