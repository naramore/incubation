defmodule GraphqlSpec.Language.FragmentSpread do
  @moduledoc """
  FragmentSpread : ... FragmentName Directives?

  FragmentDefinition : fragment FragmentName TypeCondition Directives? SelectionSet

  FragmentName : Name but not `on`

  Fragments are the primary unit of composition in GraphQL.

  Fragments allow for the reuse of common repeated selections of fields, reducing
  duplicated text in the document. Inline Fragments can be used directly within a
  selection to condition upon a type condition when querying against an interface
  or union.

  For example, if we wanted to fetch some common information about mutual friends
  as well as friends of some user:

  ```graphql example
  query noFragments {
    user(id: 4) {
      friends(first: 10) {
        id
        name
        profilePic(size: 50)
      }
      mutualFriends(first: 10) {
        id
        name
        profilePic(size: 50)
      }
    }
  }
  ```

  The repeated fields could be extracted into a fragment and composed by
  a parent fragment or query.

  ```graphql example
  query withFragments {
    user(id: 4) {
      friends(first: 10) {
        ...friendFields
      }
      mutualFriends(first: 10) {
        ...friendFields
      }
    }
  }

  fragment friendFields on User {
    id
    name
    profilePic(size: 50)
  }
  ```

  Fragments are consumed by using the spread operator (`...`). All fields selected
  by the fragment will be added to the query field selection at the same level
  as the fragment invocation. This happens through multiple levels of fragment
  spreads.

  For example:

  ```graphql example
  query withNestedFragments {
    user(id: 4) {
      friends(first: 10) {
        ...friendFields
      }
      mutualFriends(first: 10) {
        ...friendFields
      }
    }
  }

  fragment friendFields on User {
    id
    name
    ...standardProfilePic
  }

  fragment standardProfilePic on User {
    profilePic(size: 50)
  }
  ```

  The queries `noFragments`, `withFragments`, and `withNestedFragments` all
  produce the same response object.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#fragments).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:name, directives: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(fragment_spread, _opts \\ []) do
      directives = encode_directives(fragment_spread.directives)
      "...#{fragment_spread.name}#{directives}"
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      " #{GraphqlSpec.Encoder.encode(directives, joiner: " ")}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(fragment_spread, opts) do
      concat([
        "...",
        to_string(fragment_spread.name),
        Utils.optional_to_doc(fragment_spread.directives, opts, separator: " ", prefix: " ")
      ])
    end
  end
end
