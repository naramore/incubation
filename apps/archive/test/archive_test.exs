defmodule ArchiveTest do
  use ExUnit.Case
  doctest Archive

  test "greets the world" do
    assert Archive.hello() == :world
  end
end
