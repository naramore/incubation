defmodule GraphqlSpec.Language.OperationDefinition do
  @moduledoc """
  OperationDefinition :
    - OperationType Name? VariableDefinitions? Directives? SelectionSet
    - SelectionSet

  OperationType : one of `query` `mutation` `subscription`

  There are three types of operations that GraphQL models:

    * query - a read-only fetch.
    * mutation - a write followed by a fetch.
    * subscription - a long-lived request that fetches data in response to source
      events.

  Each operation is represented by an optional operation name and a selection set.

  For example, this mutation operation might "like" a story and then retrieve the
  new number of likes:

  ```graphql example
  mutation {
    likeStory(storyID: 12345) {
      story {
        likeCount
      }
    }
  }
  ```

  **Query shorthand**

  If a document contains only one query operation, and that query defines no
  variables and contains no directives, that operation may be represented in a
  short-hand form which omits the query keyword and query name.

  For example, this unnamed query operation is written via query shorthand.

  ```graphql example
  {
    field
  }
  ```

  Note: many examples below will use the query short-hand syntax.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#operations).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, OperationTypeDefinition, Selection, VariableDefinition}

  defstruct [:operation, :name, variables: [], directives: [], selections: []]
  @type t :: %__MODULE__{
    operation: OperationTypeDefinition.operation_type,
    name: Language.name | nil,
    variables: [VariableDefinition.t] | nil,
    directives: [Directive.t] | nil,
    selections: [Selection.t]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(operation, opts \\ [])
    def encode(%{operation: nil} = op, _opts) do
      "{#{GraphqlSpec.Encoder.encode(op.selections, joiner: "\n")}}"
    end
    def encode(op, _opts) do
      with name = encode_name(op.name),
           variables = encode_variables(op.variables),
           directives = encode_directives(op.directives),
           selections = GraphqlSpec.Encoder.encode(op.selections, joiner: "\n") do
        "#{op.operation}#{name}#{variables}#{directives} {#{selections}}"
      end
    end

    def encode_name(nil), do: ""
    def encode_name(name), do: " #{name}"

    defp encode_variables(nil), do: ""
    defp encode_variables([]), do: ""
    defp encode_variables(variables) do
      variables = GraphqlSpec.Encoder.encode(variables, joiner: " ")
      " (#{variables})"
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{operation: nil}), do: empty()
    def inspect(operation, opts) do
      concat([
        to_string(operation.operation),
        (if is_nil(operation.name), do: empty(), else: to_string(operation.name)),
        Utils.optional_to_doc(operation.variables, opts, left: "(", right: ")"),
        Utils.optional_to_doc(operation.directives, opts, separator: " "),
        container_doc("{", operation.selections, "}", opts, &to_doc/2, break: :flex)
      ])
    end
  end
end
