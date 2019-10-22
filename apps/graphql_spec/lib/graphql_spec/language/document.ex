defmodule GraphqlSpec.Language.Document do
  @moduledoc ~S"""
  Document : Definition+

  Definition :
    - ExecutableDefinition
    - TypeSystemDefinition
    - TypeSystemExtension

  ExecutableDefinition :
    - OperationDefinition
    - FragmentDefinition

  A GraphQL Document describes a complete file or request string operated on
  by a GraphQL service or client. A document contains multiple definitions, either
  executable or representative of a GraphQL type system.

  Documents are only executable by a GraphQL service if they contain an
  {OperationDefinition} and otherwise only contain {ExecutableDefinition}.
  However documents which do not contain {OperationDefinition} or do contain
  {TypeSystemDefinition} or {TypeSystemExtension} may still be parsed
  and validated to allow client tools to represent many GraphQL uses which may
  appear across many individual files.

  If a Document contains only one operation, that operation may be unnamed or
  represented in the shorthand form, which omits both the query keyword and
  operation name. Otherwise, if a GraphQL Document contains multiple
  operations, each operation must be named. When submitting a Document with
  multiple operations to a GraphQL service, the name of the desired operation to
  be executed must also be provided.

  GraphQL services which only seek to provide GraphQL query execution may choose
  to only include {ExecutableDefinition} and omit the {TypeSystemDefinition} and
  {TypeSystemExtension} rules from {Definition}.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#document).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Definition

  defstruct [definitions: []]
  @type t :: %__MODULE__{
    definitions: [Definition.t]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(document, _opts \\ []) do
      GraphqlSpec.Encoder.encode(document.definitions, joiner: "\n")
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(document, opts) do
      document.definitions
      |> Enum.map(&to_doc(&1, opts))
      |> concat()
    end
  end

  defimpl GraphqlSpec.Validation do
    def validate(_document, _schema) do
      {:error, :not_implemented}
    end
  end
end
