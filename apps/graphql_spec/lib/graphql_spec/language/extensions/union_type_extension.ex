defmodule GraphqlSpec.Language.UnionTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:name, directives: [], types: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil,
    types: [Language.name] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(union, _opts \\ []) do
      with directives = encode_directives(union.directives),
           types = encode_types(union.types) do
        "extend union #{union.name}#{directives}#{types}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_types(nil), do: ""
    defp encode_types([]), do: ""
    defp encode_types(types) do
      types
      |> Enum.map(&to_string/1)
      |> Enum.join(" | ")
      |> (&" = #{&1}").()
    end
  end
end
