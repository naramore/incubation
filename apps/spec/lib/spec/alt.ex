defmodule Spec.Alt do
  @moduledoc false

  defstruct [:specs]
  @type t :: %__MODULE__{
    specs: [{atom, Spec.t}, ...]
  }

  @spec new([Spec.t]) :: t
  def new(named_specs) do
    spec = %__MODULE__{specs: named_specs}
    if Spec.Cat.unique_keys?(named_specs) do
      spec
    else
      raise %Spec.DuplicateNameError{spec: spec}
    end
  end

  defimpl Spec.RegexOperator do
    @moduledoc false

    import Spec.Conformable.Spec.List, only: [proper_list?: 1]
    alias Spec.{Conformable, ConformError, RegexOp}

    def conform(%@for{specs: specs}, spec_path, via, value_path, value)
      when is_list(value) and length(value) > 0 do
        Enum.reduce(specs, {:error, []}, fn
          _, {:ok, c, r} -> {:ok, c, r}
          {k, s}, {:error, pblms} ->
            if Spec.regex?(s) do
              case @protocol.conform(s, spec_path ++ [k], via, value_path, value) do
                {:ok, conformed, rest} -> {:ok, %{k => conformed}, rest}
                {:error, problems} -> {:error, pblms ++ problems}
              end
            else
              case Conformable.conform(s, spec_path ++ [k], via, RegexOp.uninit_path(value_path), value) do
                {:ok, conformed} -> {:ok, %{k => conformed}, []}
                {:error, problems} -> {:error, pblms ++ problems}
              end
            end
        end)
    end
    def conform(_spec, spec_path, via, value_path, value) when is_list(value) do
      {:error, [ConformError.new_problem(&proper_list?/1, spec_path, via, value_path, value)]}
    end
    def conform(_spec, spec_path, via, value_path, value) do
      {:error, [ConformError.new_problem(&is_list/1, spec_path, via, value_path, value)]}
    end
  end
end
