defmodule Spec.RefTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData
  import Spec.Ref, only: [sref: 2]
  doctest Spec.Ref

  describe "Spec.Ref.resolve/1" do
    setup do
      _ = SpecRef.any()
      {:ok, %{}}
    end

    test "fun does not exist -> error" do
      ref = sref(SpecRef, :not_there)
      assert match? {:error, [{_, nil}]}, Spec.Ref.resolve(ref)
    end

    [:one_arity, :two_arity, :three_arity, :four_arity]
    |> Enum.with_index(1)
    |> Enum.map(fn {fun, i} ->
      @fun fun
      test "fun wrong arity [#{i}] -> error" do
        ref = sref(SpecRef, @fun)
        assert match? {:error, [{_, nil}]}, Spec.Ref.resolve(ref)
      end
    end)

    [:raise!, :throw!, :exit_normal!, :exit_abnormal!]
    |> Enum.map(fn fun ->
      @fun fun
      test "fun raises/exits/throws [#{fun}] -> error" do
        ref = sref(SpecRef, @fun)
        assert match? {:error, [{nil, _}]}, Spec.Ref.resolve(ref)
      end
    end)

    test "fun returns spec successfully!" do
      ref = sref(SpecRef, :any)
      assert match? {:ok, _}, Spec.Ref.resolve(ref)
    end
  end

  describe "Spec.Conformable.Spec.Ref.conform/5" do
    @tag skip: true
    property "#SRef<*spec*> == *spec*" do
      check all data <- SpecRef.clj_spec_gen() do
        ref = sref(SpecRef, :clj_spec)
        assert Spec.conform(ref, data) == Spec.conform(SpecRef.clj_spec(), data)
      end
    end
  end

  describe "Spec.RegexOperator.Spec.Ref.conform/5" do
    @tag skip: true
    property "#SRef<*regex-op*> == *regex-op* when called from a regex-op" do
      check all data <- SpecRef.clj_regexop_gen() do
        ref = sref(SpecRef, :clj_regexop)
        assert Spec.conform(ref, data) == Spec.conform(SpecRef.clj_regexop(), data)
      end
    end
  end
end
