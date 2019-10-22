defmodule GraphqlSpec.Language.InlineFragment do
  @moduledoc ~S"""
  InlineFragment : ... TypeCondition? Directives? SelectionSet

  Fragments can be defined inline within a selection set. This is done to
  conditionally include fields based on their runtime type. This feature of
  standard fragment inclusion was demonstrated in the `query FragmentTyping`
  example. We could accomplish the same thing using inline fragments.

  ```graphql example
  query inlineFragmentTyping {
    profiles(handles: ["zuck", "cocacola"]) {
      handle
      ... on User {
        friends {
          count
        }
      }
      ... on Page {
        likers {
          count
        }
      }
    }
  }
  ```

  Inline fragments may also be used to apply a directive to a group of fields.
  If the TypeCondition is omitted, an inline fragment is considered to be of the
  same type as the enclosing context.

  ```graphql example
  query inlineFragmentNoType($expandedInfo: Boolean) {
    user(handle: "zuck") {
      id
      name
      ... @include(if: $expandedInfo) {
        firstName
        lastName
        birthday
      }
    }
  }
  ```

  ## Note

  Taken from the (GraphQL specification)[https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#inline-fragments].
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, NamedType, Selection}

  defstruct [:type_condition, directives: [], selections: []]
  @type t :: %__MODULE__{
    type_condition: NamedType.t | nil,
    directives: [Directive.t] | nil,
    selections: [Selection.t]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(inline_fragment, _opts \\ []) do
      with type_condition = encode_type_condition(inline_fragment.type_condition),
           directives = encode_directives(inline_fragment.directives),
           selections = GraphqlSpec.Encoder.encode(inline_fragment, joiner: "\n") do
        "...#{type_condition}#{directives} {#{selections}}"
      end
    end

    defp encode_type_condition(nil), do: ""
    defp encode_type_condition([]), do: ""
    defp encode_type_condition(type_condition) do
      type_condition = GraphqlSpec.Encoder.encode(type_condition)
      "on #{type_condition}"
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

    def inspect(inline_fragment, opts) do
      concat([
        "...",
        (if is_nil(inline_fragment.type_condition), do: empty(), else: concat(["on ", to_string(inline_fragment.type_condition)])),
        Utils.optional_to_doc(inline_fragment.directives, opts, separator: " ", prefix: " "),
        Utils.optional_to_doc(inline_fragment.selections, opts, left: "{", right: "}", prefix: " ")
      ])
    end
  end
end
