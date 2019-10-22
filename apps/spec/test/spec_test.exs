defmodule SpecTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData
  doctest Spec

  describe "Spec.conform/2" do
    @tag skip: true
    property "returns" do
      check all spec <- SpecData.spec(),
                value <- term() do
        result = Spec.conform(spec, value)
        assert match?({:ok, _}, result) or match?({:error, _}, result)
      end
    end
  end

  describe "Spec.also/1" do
  end

  describe "Spec.list_of/2" do
  end

  describe "Spec.map_of/3" do
  end

  describe "Spec.merge/1" do
  end

  describe "Spec.nilable/1" do
  end

  describe "Spec.one_of/1" do
  end
end
