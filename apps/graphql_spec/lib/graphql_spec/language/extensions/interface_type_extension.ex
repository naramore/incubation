defmodule GraphqlSpec.Language.InterfaceTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, FieldDefinition}

  defstruct [:name, directives: [], fields: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil,
    fields: [FieldDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(interface, _opts \\ []) do
      with directives = encode_directives(interface.directives),
           fields = encode_fields(interface.fields) do
        "extend interface #{interface.name}#{directives}#{fields}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_fields(nil), do: ""
    defp encode_fields([]), do: ""
    defp encode_fields(fields) do
      fields = GraphqlSpec.Encoder.encode(fields, joiner: "\n")
      " {#{fields}}"
    end
  end
end
