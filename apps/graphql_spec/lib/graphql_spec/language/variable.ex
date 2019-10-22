defmodule GraphqlSpec.Language.Variable do
  @moduledoc ~S"""
  Variable : $ Name

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#variables)
  """
  use GraphqlSpec.Language

  defstruct [:name]
  @type t :: %__MODULE__{
    name: Language.name
  }

  defimpl GraphqlSpec.Encoder do
    def encode(variable, _opts \\ []) do
      "$#{variable}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(variable, _opts) do
      concat([
        "$",
        to_string(variable.name)
      ])
    end
  end
end
