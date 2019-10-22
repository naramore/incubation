defmodule GraphqlSpec.Language.SchemaDefinition do
  @moduledoc ~S"""
  SchemaDefinition : schema Directives[Const]? { RootOperationTypeDefinition+ }

  A GraphQL service's collective type system capabilities are referred to as that
  service's "schema". A schema is defined in terms of the types and directives it
  supports as well as the root operation types for each kind of operation:
  query, mutation, and subscription; this determines the place in the type system
  where those operations begin.

  A GraphQL schema must itself be internally valid. This section describes
  the rules for this validation process where relevant.

  All types within a GraphQL schema must have unique names. No two provided types
  may have the same name. No provided type may have a name which conflicts with
  any built in types (including Scalar and Introspection types).

  All directives within a GraphQL schema must have unique names.

  All types and directives defined within a schema must not have a name which
  begins with {"__"} (two underscores), as this is used exclusively by GraphQL's
  introspection system.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#schema).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, OperationTypeDefinition}

  defstruct [directives: [], operations: []]
  @type t :: %__MODULE__{
    directives: [Directive.t] | nil,
    operations: [OperationTypeDefinition.t],
  }

  defimpl GraphqlSpec.Encoder do
    def encode(schema, _opts \\ []) do
      with directives = encode_directives(schema.directives),
           operations = GraphqlSpec.Encoder.encode(schema.operations, joiner: "\n") do
        "schema#{directives} {#{operations}}"
      end
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

    def inspect(schema, opts \\ []) do
      concat([
        "schema",
        Utils.optional_to_doc(schema.directives, opts, separator: " "),
        container_doc(" {", schema.operations, "}", opts, &to_doc/2, break: :flex)
      ])
    end
  end
end
