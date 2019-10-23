defmodule Spec.ZeroOrMore do
  @moduledoc false

  defstruct [
    spec: nil
  ]
  @type t :: %__MODULE__{
    spec: Spec.t
  }

  @spec new(Spec.t) :: t
  def new(spec) do
    %__MODULE__{spec: spec}
  end

  defimpl Spec.RegexOperator do
    @moduledoc false

    import Spec.Conformable.Spec.List, only: [proper_list?: 1]
    alias Spec.{ConformError, RegexOp}

    def conform(_spec, _spec_path, _via, _value_path, []) do
      {:ok, [], []}
    end
    def conform(%@for{spec: spec}, spec_path, via, value_path, value) when is_list(value) and length(value) > 0 do
      if Spec.regex?(spec) do
        conform_regex(spec, spec_path, via, value_path, value)
      else
        conform_non_regex(spec, spec_path, via, RegexOp.uninit_path(value_path), value)
      end
    end
    def conform(_spec, spec_path, via, value_path, value) when is_list(value) do
      {:error, [ConformError.new_problem(&proper_list?/1, spec_path, via, value_path, value)]}
    end
    def conform(_spec, spec_path, via, value_path, value) do
      {:error, [ConformError.new_problem(&is_list/1, spec_path, via, value_path, value)]}
    end

    @spec conform_regex(RegexOperator.t, [term], [Spec.Ref.t], [term], term, [term])
      :: {:ok, conformed :: term, rest :: term}
    defp conform_regex(spec, spec_path, via, value_path, rest, acc \\ [])
    defp conform_regex(_spec, _spec_path, _via, _value_path, [], acc) do
      {:ok, acc, []}
    end
    defp conform_regex(spec, spec_path, via, value_path, [_|_] = rest, acc) do
      case @protocol.conform(spec, spec_path, via, value_path, rest) do
        {:error, _problems} -> {:ok, acc, rest}
        {:ok, conformed, rest} ->
          conform_regex(spec, spec_path, via, RegexOp.inc_path(value_path), rest, acc ++ conformed)
      end
    end
    defp conform_regex(_spec, _spec_path, _via, _value_path, improper, acc) do
      {:ok, acc, improper}
    end

    @spec conform_non_regex(Spec.t, [term], [Spec.Ref.t], [term], term, non_neg_integer, [term])
      :: {:ok, conformed :: term} | {:error, [ConformError.Problem.t]}
    defp conform_non_regex(spec, spec_path, via, value_path, value, pos \\ 0, acc \\ [])
    defp conform_non_regex(_spec, _spec_path, _via, _value_path, [], _pos, acc) do
      {:ok, Enum.reverse(acc)}
    end
    defp conform_non_regex(spec, spec_path, via, value_path, [h|t], pos, acc) do
      case Spec.Conformable.conform(spec, spec_path, via, value_path ++ [pos], h) do
        {:error, _problems} -> {:ok, acc}
        {:ok, c} ->
          conform_non_regex(spec, spec_path, via, value_path, t, pos + 1, [c|acc])
      end
    end
  end
end