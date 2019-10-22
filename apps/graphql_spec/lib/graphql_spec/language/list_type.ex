defmodule GraphqlSpec.Language.ListType do
  @moduledoc ~S"""
  ListType : [ Type ]

  ## Semantics

  Type : [ Type ]

  * Let {itemType} be the result of evaluating {Type}
  * Let {type} be a List type where {itemType} is the contained type.
  * Return {type}

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#type-references).
  """
  use GraphqlSpec.Language

  defstruct [:type]
  @type t :: %__MODULE__{
    type: Language.type
  }

  defimpl GraphqlSpec.Encoder do
    def encode(list_type, _opts \\ []) do
      type = GraphqlSpec.Encoder.encode(list_type.type)
      "[#{type}]"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{type: nil}, _opts), do: empty()
    def inspect(list_type, opts) do
      concat(["[", to_doc(list_type.type, opts), "]"])
    end
  end
end
