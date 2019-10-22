defmodule GraphqlSpec.Language.OperationTypeDefinition do
  @moduledoc """
    RootOperationTypeDefinition : OperationType : NamedType

    A schema defines the initial root operation type for each kind of operation it
    supports: query, mutation, and subscription; this determines the place in the
    type system where those operations begin.

    The `query` root operation type must be provided and must be an Object type.

    The `mutation` root operation type is optional; if it is not provided, the
    service does not support mutations. If it is provided, it must be an
    Object type.

    Similarly, the `subscription` root operation type is also optional; if it is not
    provided, the service does not support subscriptions. If it is provided, it must
    be an Object type.

    The fields on the `query` root operation type indicate what fields are available
    at the top level of a GraphQL query. For example, a basic GraphQL query like:

    ```graphql example
    query {
      myName
    }
    ```

    Is valid when the `query` root operation type has a field named "myName".

    ```graphql example
    type Query {
      myName: String
    }
    ```

    Similarly, the following mutation is valid if a `mutation` root operation type
    has a field named "setName". Note that the `query` and `mutation` root types
    must be different types.

    ```graphql example
    mutation {
      setName(name: "Zuck") {
        newName
      }
    }
    ```

    When using the type system definition language, a document must include at most
    one `schema` definition.

    In this example, a GraphQL schema is defined with both query and mutation
    root types:

    ```graphql example
    schema {
      query: MyQueryRootType
      mutation: MyMutationRootType
    }

    type MyQueryRootType {
      someField: String
    }

    type MyMutationRootType {
      setSomeField(to: String): String
    }
    ```

    ## Default Root Operation Type Names

    While any type can be the root operation type for a GraphQL operation, the type
    system definition language can omit the schema definition when the `query`,
    `mutation`, and `subscription` root types are named `Query`, `Mutation`, and
    `Subscription` respectively.

    Likewise, when representing a GraphQL schema using the type system definition
    language, a schema definition should be omitted if it only uses the default root
    operation type names.

    This example describes a valid complete GraphQL schema, despite not explicitly
    including a `schema` definition. The `Query` type is presumed to be the `query`
    root operation type of the schema.

    ```graphql example
    type Query {
      someField: String
    }
    ```

    ## Note

    Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#schema).
  """
  use GraphqlSpec.Language

  @type operation_type :: :query | :mutation | :subscription

  defstruct [:operation, :name]
  @type t :: %__MODULE__{
    operation: operation_type,
    name: Language.name
  }

  defimpl GraphqlSpec.Encoder do
    def encode(operation_type, _opts \\ []) do
      "#{operation_type.operation}: #{operation_type.name}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{operation: nil}, _opts), do: empty()
    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(operation_type, _opts) do
      concat([
        to_string(operation_type.operation),
        ": ",
        to_string(operation_type.name)
      ])
    end
  end
end
