defmodule GraphqlSpec.Language.UnionTypeDefinition do
  @moduledoc ~S"""
  UnionTypeDefinition : Description? union Name Directives[Const]? UnionMemberTypes?

  UnionMemberTypes :
    - = `|`? NamedType
    - UnionMemberTypes | NamedType

  GraphQL Unions represent an object that could be one of a list of GraphQL
  Object types, but provides for no guaranteed fields between those types.
  They also differ from interfaces in that Object types declare what interfaces
  they implement, but are not aware of what unions contain them.

  With interfaces and objects, only those fields defined on the type can be
  queried directly; to query other fields on an interface, typed fragments
  must be used. This is the same as for unions, but unions do not define any
  fields, so **no** fields may be queried on this type without the use of
  type refining fragments or inline fragments.

  For example, we might define the following types:

  ```graphql example
  union SearchResult = Photo | Person

  type Person {
    name: String
    age: Int
  }

  type Photo {
    height: Int
    width: Int
  }

  type SearchQuery {
    firstSearchResult: SearchResult
  }
  ```

  When querying the `firstSearchResult` field of type `SearchQuery`, the
  query would ask for all fields inside of a fragment indicating the appropriate
  type. If the query wanted the name if the result was a Person, and the height if
  it was a photo, the following query is invalid, because the union itself
  defines no fields:

  ```graphql counter-example
  {
    firstSearchResult {
      name
      height
    }
  }
  ```

  Instead, the query would be:

  ```graphql example
  {
    firstSearchResult {
      ... on Person {
        name
      }
      ... on Photo {
        height
      }
    }
  }
  ```

  Union members may be defined with an optional leading `|` character to aid
  formatting when representing a longer list of possible types:

  ```graphql example
  union SearchResult =
    | Photo
    | Person
  ```

  ## Result Coercion

  The union type should have some way of determining which object a given result
  corresponds to. Once it has done so, the result coercion of the union is the
  same as the result coercion of the object.

  ## Input Coercion

  Unions are never valid inputs.

  ## Type Validation

  Union types have the potential to be invalid if incorrectly defined.

  1. A Union type must include one or more unique member types.
  2. The member types of a Union type must all be Object base types;
    Scalar, Interface and Union types must not be member types of a Union.
    Similarly, wrapping types must not be member types of a Union.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#unions).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:description, :name, directives: [], types: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    directives: [Directive.t] | nil,
    types: [Language.name] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(union_type, _opts \\ []) do
      with description = encode_description(union_type.description),
           name = union_type.name,
           directives = encode_directives(union_type.directives),
           types = encode_types(union_type.types) do
        "#{description}union #{name}#{directives}#{types}"
      end
    end

    defp encode_description(nil), do: ""
    defp encode_description(description) do
      description = GraphqlSpec.Encoder.encode(description)
      "#{description} "
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_types(nil), do: ""
    defp encode_types([]), do: ""
    defp encode_types(values) do
      values
      |> Enum.map(&GraphqlSpec.Encoder.encode/1)
      |> Enum.join(" | ")
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}), do: empty()
    def inspect(union, opts) do
      concat([
        Utils.optional_to_doc(union.description, opts, suffix: " "),
        "union ",
        to_string(union.name),
        Utils.optional_to_doc(union.directives, opts, prefix: " "),
        Utils.optional_to_doc(union.types, opts, prefix: " ", separator: " | ")
      ])
    end
  end
end
