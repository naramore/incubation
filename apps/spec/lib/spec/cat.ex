defmodule Spec.DuplicateNameError do
  @moduledoc false

  defexception [:spec]
  @type t :: %__MODULE__{
    spec: Spec.t
  }

  @impl Exception
  def message(%__MODULE__{spec: spec}) do
    "Duplicate sub-spec names are not allowed in #{spec.__struct__}"
  end
end

defmodule Spec.Cat do
  @moduledoc false

  defstruct [:specs]
  @type t :: %__MODULE__{
    specs: [{atom, Spec.t}, ...]
  }

  @spec new([{atom, Spec.t}, ...]) :: t | no_return
  def new(named_specs) do
    spec = %__MODULE__{specs: named_specs}
    if unique_keys?(named_specs) do
      spec
    else
      raise %Spec.DuplicateNameError{spec: spec}
    end
  end

  @spec unique_keys?([{atom, Spec.t}]) :: boolean
  def unique_keys?(named_specs) do
    {keys, _} = Enum.unzip(named_specs)
    unique_keys = Enum.uniq(keys)
    length(keys) == length(unique_keys)
  end

  defimpl Spec.RegexOperator do
    @moduledoc false

    import Spec.Conformable.Spec.List, only: [proper_list?: 1]
    alias Spec.{Conformable, ConformError, RegexOp}

    def conform(%@for{specs: specs}, spec_path, via, value_path, []) do
      Enum.reduce(specs, {:ok, %{}, []}, fn
        _, {:error, pblms} -> {:error, pblms}
        {k, s}, {:ok, acc, r} ->
          if Spec.regex?(s) do
            case @protocol.conform(s, spec_path ++ [k], via, value_path, r) do
              {:ok, c, rest} -> {:ok, Map.put(acc, k, c), rest}
              {:error, problems} -> {:error, problems}
            end
          else
            {:error, [ConformError.new_problem(
              :insufficient_data, spec_path, via, RegexOp.uninit_path(value_path), []
            )]}
          end
      end)
    end
    def conform(%@for{specs: specs}, spec_path, via, value_path, [h|t] = value)
      when length(value) > 0 do
        Enum.reduce(specs, {:ok, %{}, value}, fn
          _, {:error, pblms} -> {:error, pblms}
          {k, s}, {:ok, acc, r} ->
            if Spec.regex?(s) do
              case @protocol.conform(s, spec_path ++ [k], via, value_path, r) do
                {:ok, c, rest} -> {:ok, Map.put(acc, k, c), rest}
                {:error, problems} -> {:error, problems}
              end
            else
              case Conformable.conform(s, spec_path ++ [k], via, RegexOp.uninit_path(value_path), h) do
                {:ok, c} -> {:ok, Map.put(acc, k, c), t}
                {:error, problems} -> {:error, problems}
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
