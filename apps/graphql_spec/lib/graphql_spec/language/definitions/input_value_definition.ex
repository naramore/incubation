defmodule GraphqlSpec.Language.InputValueDefinition do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{DefaultValue, Directive}

  defstruct [:description, :name, :type, :default_value, directives: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    type: Language.type,
    default_value: DefaultValue.t | nil,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(input_value, _opts \\ []) do
      with description = encode_description(input_value.description),
           name = input_value.name,
           type = GraphqlSpec.Encoder.encode(input_value.type),
           default_value = encode_default_value(input_value.default_value),
           directives = encode_directives(input_value.directives) do
        "#{description}#{name}: #{type}#{default_value}#{directives}"
      end
    end

    defp encode_description(nil), do: ""
    defp encode_description(description) do
      description = GraphqlSpec.Encoder.encode(description)
      "#{description} "
    end

    defp encode_default_value(nil), do: ""
    defp encode_default_value(default_value) do
      default_value = GraphqlSpec.Encoder.encode(default_value)
      " #{default_value}"
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end
  end
end
