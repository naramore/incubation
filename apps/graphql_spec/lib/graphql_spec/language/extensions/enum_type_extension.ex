defmodule GraphqlSpec.Language.EnumTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, EnumTypeDefinition}

  defstruct [:name, directives: [], values: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil,
    values: [EnumTypeDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(enum, _opts \\ []) do
      with directives = encode_directives(enum.directives),
           values = encode_values(enum.values) do
        "extend enum #{enum.name}#{directives}#{values}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_values(nil), do: ""
    defp encode_values([]), do: ""
    defp encode_values(values) do
      values = GraphqlSpec.Encoder.encode(values, joiner: "\n")
      " {#{values}}"
    end
  end
end
