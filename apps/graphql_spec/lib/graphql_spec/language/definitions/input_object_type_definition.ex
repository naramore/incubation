defmodule GraphqlSpec.Language.InputObjectTypeDefinition do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, InputValueDefinition}

  defstruct [:description, :name, directives: [], input_fields: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    directives: [Directive.t] | nil,
    input_fields: [InputValueDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(object, _opts \\ []) do
      with description = encode_description(object.description),
           name = object.name,
           directives = encode_directives(object.directives),
           input_fields = encode_input_fields(object.input_fields) do
        "#{description}input #{name}#{directives}#{input_fields}"
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

    defp encode_input_fields(nil), do: ""
    defp encode_input_fields([]), do: ""
    defp encode_input_fields(input_fields) do
      input_fields = GraphqlSpec.Encoder.encode(input_fields, joiner: "\n")
      " {#{input_fields}}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(object, opts) do
      concat([
        Utils.optional_to_doc(object.description, opts, suffix: " "),
        "input ",
        to_string(object.name),
        Utils.optional_to_doc(object.directives, opts, separator: " ", prefix: " "),
        Utils.optional_to_doc(object.input_fields, opts, left: "{", right: "}", prefix: " ")
      ])
    end
  end
end
