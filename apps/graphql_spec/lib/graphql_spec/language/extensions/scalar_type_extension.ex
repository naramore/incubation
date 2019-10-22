defmodule GraphqlSpec.Language.ScalarTypeExtension do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:name, directives: []]
  @type t :: %__MODULE__{
    name: Language.name,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(scalar, _opts \\ []) do
      with directives = encode_directives(scalar.directives) do
        "extend scalar #{scalar.name}#{directives}"
      end
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end
  end
end
