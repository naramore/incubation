defmodule GraphqlSpec.Language.DefaultValue do
  @moduledoc ~S"""
  DefaultValue : = Value[Const]

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#variables)
  """
  use GraphqlSpec.Language

  defstruct [:default]
  @type t :: %__MODULE__{
    default: Language.value
  }

  defimpl GraphqlSpec.Encoder do
    def encode(default_value, _opts \\ []) do
      default = GraphqlSpec.Encoder.encode(default_value.default)
      "= #{default}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{default: nil}, _opts), do: empty()
    def inspect(default_value, opts) do
      concat(["=", to_doc(default_value.default, opts)])
    end
  end
end
