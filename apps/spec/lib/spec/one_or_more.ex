defmodule Spec.OneOrMore do
  @moduledoc false

  defstruct [:spec]
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
    alias Spec.{Conformable, ConformError, RegexOp}

    def conform(%@for{spec: spec}, spec_path, via, value_path, value) when is_list(value) and length(value) > 0 do
      case conform_first(spec, spec_path, via, value_path, value) do
        {:error, problems} -> {:error, problems}
        {:ok, ch, rest} ->
          zom_spec = Spec.ZeroOrMore.new(spec)
          case @protocol.conform(zom_spec, spec_path, via, RegexOp.inc_path(value_path), rest) do
            {:ok, ct, rest} -> {:ok, [ch|ct], rest}
            {:error, problems} ->
              {:error, adjust_problems(problems, length(value_path) - 1)}
          end
      end
    end
    def conform(_spec, spec_path, via, value_path, value) when is_list(value) do
      {:error, [ConformError.new_problem(&proper_list?/1, spec_path, via, value_path, value)]}
    end
    def conform(_spec, spec_path, via, value_path, value) do
      {:error, [ConformError.new_problem(&is_list/1, spec_path, via, value_path, value)]}
    end

    defp conform_first(spec, spec_path, via, value_path, [h|t] = value) do
      if Spec.regex?(spec) do
        @protocol.conform(spec, spec_path, via, value_path, value)
      else
        case Conformable.conform(spec, spec_path, via, value_path, h) do
          {:ok, conformed} -> {:ok, conformed, t}
          {:error, problems} -> {:error, problems}
        end
      end
    end

    @spec adjust_problems([ConformError.Problem.t], non_neg_integer) :: [ConformError.Problem.t]
    defp adjust_problems(problems, index) do
      update_in(
        problems,
        [Access.all(), :value_path, Access.at(index)],
        fn i -> i + 1 end
      )
    end
  end
end
