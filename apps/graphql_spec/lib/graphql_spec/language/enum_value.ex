defmodule GraphqlSpec.Language.EnumValue do
  use GraphqlSpec.Language

  defstruct [:value]
  @type t :: %__MODULE__{
    value: Language.name
  }

  defimpl GraphqlSpec.Encoder do
    def encode(enum, _opts \\ []) do
      enum
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{value: nil}, _opts), do: empty()
    def inspect(enum_value, _opts) do
      to_string(enum_value.value)
    end
  end
end
