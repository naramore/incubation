defmodule GraphqlSpec.Language.SchemaExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, OperationTypeDefinition}

  defstruct [directives: [], operations: []]
  @type t :: %__MODULE__{
    directives: [Directive.t] | nil,
    operations: [OperationTypeDefinition.t] | nil,
  }

  defimpl GraphqlSpec.Encoder do
    def encode(schema, _opts \\ []) do
      with directives = encode_directives(schema.directives),
           operations = encode_operations(schema.operations) do
        "extend schema #{directives}#{operations}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_operations(nil), do: ""
    defp encode_operations([]), do: ""
    defp encode_operations(operations) do
      operations = GraphqlSpec.Encoder.encode(operations, joiner: "\n")
      " {#{operations}}"
    end
  end
end
