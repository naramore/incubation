defmodule GraphqlSpec.Language.InterfaceTypeDefinition do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, FieldDefinition}

  defstruct [:description, :name, directives: [], fields: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    directives: [Directive.t] | nil,
    fields: [FieldDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(interface, _opts \\ []) do
      with description = encode_description(interface.description),
           name = interface.name,
           directives = encode_directives(interface.directives),
           fields = encode_fields(interface.fields) do
        "#{description}interface #{name}#{directives}#{fields}"
      end
    end

    defp encode_description(nil), do: ""
    defp encode_description(description) do
      description = GraphqlSpec.Encoder.encode(description)
      "#{description} "
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

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}), do: empty()
    def inspect(interface, opts) do
      concat([
        Utils.optional_to_doc(interface.description, opts, suffix: " "),
        "interface ",
        to_string(interface.name),
        Utils.optional_to_doc(interface.directives, opts, separator: " ", prefix: " "),
        container_doc("{", interface.fields, "}", opts, &to_doc/2, break: :flex, prefix: " ")
      ])
    end
  end
end
