defmodule GraphqlSpec.Language.NonNullType do
  @moduledoc ~S"""
  NonNullType :
    - NamedType !
    - ListType !

  ## Semantics

  Type : Type !

  * Let {nullableType} be the result of evaluating {Type}
  * Let {type} be a Non-Null type where {nullableType} is the contained type.
  * Return {type}

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#type-references).
  """
  use GraphqlSpec.Language

  defstruct [:type]
  @type t :: %__MODULE__{
    type: Language.NamedType.t | Language.ListType.t
  }

  defimpl GraphqlSpec.Encoder do
    def encode(non_null_type, _opts \\ []) do
      type = GraphqlSpec.Encoder.encode(non_null_type.type)
      "#{type}!"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{type: nil}, _opts), do: empty()
    def inspect(non_null_type, opts) do
      concat([
        to_doc(non_null_type.type, opts),
        "!"
      ])
    end
  end
end
