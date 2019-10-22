defmodule GraphqlSpecDataTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest GraphqlSpecData

  @spec inspect_all(term, keyword) :: String.t
  def inspect_all(data, opts \\ []) do
    opts = Keyword.merge([limit: :infinity, printable_limit: :infinity], opts)
    inspect(data, opts)
  end

  @spec stringify_codepoint(non_neg_integer) :: {non_neg_integer, String.t | nil}
  def stringify_codepoint(code_point) do
    try do
      {code_point, to_string(code_point)}
    rescue
      _ -> {code_point, nil}
    end
  end

  @tag :skip
  test "iex unprintable codepoints are b/t 0xD800..0xFFFF" do
    ranges =
      0x0000..0xFFFF
      |> Enum.map(&stringify_codepoint/1)
      |> Enum.filter(fn {_, v} -> is_nil(v) end)
      |> Keyword.keys()
      |> Enum.sort()
      |> Enum.reduce([], fn
        i, [{j, k}|t] when i == k + 1 -> [{j, i}|t]
        i, acc -> [{i, i}|acc]
      end)

    assert ranges == [{0xD800, 0xFFFF}]
  end

  describe "GraphqlSpecData.non_null_type/1" do
    test "should not contain a non null type" do
      check all type <- GraphqlSpecData.non_null_type(), max_runs: 1000 do
        inspected_type = inspect_all(type)
        refute String.contains?(inspected_type, "!!")
      end
    end
  end
end
