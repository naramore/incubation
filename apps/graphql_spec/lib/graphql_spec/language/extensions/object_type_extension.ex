defmodule GraphqlSpec.Language.ObjectTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, FieldDefinition}

  defstruct [:name, interfaces: [], directives: [], fields: []]
  @type t :: %__MODULE__{
    name: Language.name,
    interfaces: [Language.name] | nil,
    directives: [Directive.t] | nil,
    fields: [FieldDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(object, _opts \\ []) do
      with interfaces = encode_interfaces(object.interfaces),
           directives = encode_directives(object.directives),
           fields = encode_fields(object.fields) do
        "extend type #{object.name}#{interfaces}#{directives}#{fields}"
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

    defp encode_interfaces(nil), do: ""
    defp encode_interfaces([]), do: ""
    defp encode_interfaces(interfaces) do
      interfaces
      |> Enum.map(&to_string/1)
      |> Enum.join(" & ")
      |> (&" implements #{&1}").()
    end
  end
end
