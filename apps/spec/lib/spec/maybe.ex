defmodule Spec.Maybe do
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
    alias Spec.{Conformable, ConformError}

    def conform(_spec, _spec_path, _via, _value_path, []) do
      {:ok, [], []}
    end
    def conform(%@for{spec: spec}, spec_path, via, value_path, [h|t] = value)
      when is_list(value) and length(value) > 0 do
        if Spec.regex?(spec) do
          @protocol.conform(spec, spec_path, via, value_path, value)
        else
          case Conformable.conform(spec, spec_path, via, value_path, h) do
            {:ok, conformable} -> {:ok, conformable, t}
            {:error, problems} -> {:error, problems}
          end
        end
    end
    def conform(_spec, spec_path, via, value_path, value) when is_list(value) do
      {:error, [ConformError.new_problem(&proper_list?/1, spec_path, via, value_path, value)]}
    end
    def conform(_spec, spec_path, via, value_path, value) do
      {:error, [ConformError.new_problem(&is_list/1, spec_path, via, value_path, value)]}
    end
  end
end
