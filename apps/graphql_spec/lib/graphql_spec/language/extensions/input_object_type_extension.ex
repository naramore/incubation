defmodule GraphqlSpec.Language.InputObjectTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, InputValueDefinition}

  defstruct [:name, directives: [], input_fields: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil,
    input_fields: [InputValueDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(input_object, _opts \\ []) do
      with directives = encode_directives(input_object.directives),
           input_fields = encode_input_fields(input_object.input_fields) do
        "extend input #{input_object.name}#{directives}#{input_fields}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_input_fields(nil), do: ""
    defp encode_input_fields([]), do: ""
    defp encode_input_fields(input_fields) do
      input_fields = GraphqlSpec.Encoder.encode(input_fields, joiner: "\n")
      " {#{input_fields}}"
    end
  end
end
