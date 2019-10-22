defmodule GraphqlSpec.Language.FragmentDefinition do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, NamedType, Selection}

  defstruct [:name, :type_condition, directives: [], selections: []]
  @type t :: %__MODULE__{
    name: Language.name,
    type_condition: NamedType.t,
    directives: [Directive.t] | nil,
    selections: [Selection.t]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(fragment, _opts \\ []) do
      with name = fragment.name,
           type = GraphqlSpec.Encoder.encode(fragment.type_condition),
           directives = encode_directives(fragment.directives),
           selections = GraphqlSpec.Encoder.encode(fragment.selections, joiner: "\n") do
        "fragment #{name} on #{type}#{directives} {#{selections}}"
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

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(%{type_condition: nil}, _opts), do: empty()
    def inspect(fragment, opts) do
      concat([
        "fragment ",
        to_string(fragment.name),
        " on ",
        to_doc(fragment.type_condition, opts),
        Utils.optional_to_doc(fragment.directives, opts, separator: " ", prefix: " "),
        container_doc(" {", fragment.selections, "}", opts, &to_doc/2, break: :flex)
      ])
    end
  end
end
