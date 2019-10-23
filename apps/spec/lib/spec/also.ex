defmodule Spec.Also do
  @moduledoc false

  defstruct [specs: []]
  @type t :: %__MODULE__{
    specs: [Spec.t]
  }

  @spec new([Spec.t]) :: t
  def new(specs) do
    %__MODULE__{specs: specs}
  end

  defimpl Spec.Conformable do
    @moduledoc false

    def conform(%@for{specs: []}, _spec_path, _via, _value_path, value) do
      {:ok, value}
    end
    def conform(%@for{specs: [spec]}, spec_path, via, value_path, value) do
      @protocol.conform(spec, spec_path, via, value_path, value)
    end
    def conform(%@for{specs: specs}, spec_path, via, value_path, value) when is_list(specs) do
      Enum.reduce(specs, {:ok, value, []}, fn
        _, {:error, nil, pblms} -> {:error, nil, pblms}
        s, {:ok, c, []} ->
          case @protocol.conform(s, spec_path, via, value_path, c) do
            {:ok, conformed} -> {:ok, conformed, []}
            {:error, problems} -> {:error, nil, problems}
          end
      end)
    end
  end
end