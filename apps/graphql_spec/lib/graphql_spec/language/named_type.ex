defmodule GraphqlSpec.Language.NamedType do
  @moduledoc ~S"""
  NamedType : Name

  ## Semantics

  Type : Name

  * Let {name} be the string value of {Name}
  * Let {type} be the type defined in the Schema named {name}
  * {type} must not be {null}
  * Return {type}

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#type-references).
  """
  use GraphqlSpec.Language

  defstruct [:name]
  @type t :: %__MODULE__{
    name: Language.name
  }

  defimpl GraphqlSpec.Encoder do
    def encode(named_type, _opts \\ []) do
      named_type.name
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(named_type, _opts) do
      to_string(named_type.name)
    end
  end
end
