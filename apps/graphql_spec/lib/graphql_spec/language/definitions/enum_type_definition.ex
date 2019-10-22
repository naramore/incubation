defmodule GraphqlSpec.Language.EnumTypeDefinition do
  @moduledoc ~S"""
  EnumTypeDefinition : Description? enum Name Directives[Const]? EnumValuesDefinition?

  GraphQL Enum types, like scalar types, also represent leaf values in a GraphQL
  type system. However Enum types describe the set of possible values.

  Enums are not references for a numeric value, but are unique values in their own
  right. They may serialize as a string: the name of the represented value.

  In this example, an Enum type called `Direction` is defined:

  ```graphql example
  enum Direction {
    NORTH
    EAST
    SOUTH
    WEST
  }
  ```

  ## Type Validation

  Enum types have the potential to be invalid if incorrectly defined.

  1. An Enum type must define one or more unique enum values.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#enums).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, EnumValueDefinition}

  defstruct [:description, :name, directives: [], values: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    directives: [Directive.t] | nil,
    values: [EnumValueDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(enum_type_definition, _opts \\ []) do
      with description = encode_description(enum_type_definition.description),
           name = enum_type_definition.name,
           directives = encode_directives(enum_type_definition.directives),
           values = encode_values(enum_type_definition.values) do
        "#{description}enum #{name}#{directives}#{values}"
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

    defp encode_values(nil), do: ""
    defp encode_values([]), do: ""
    defp encode_values(values) do
      values = GraphqlSpec.Encoder.encode(values, joiner: "\n")
      " {#{values}}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(enum, opts) do
      concat([
        Utils.optional_to_doc(enum.description, opts, suffix: " "),
        "enum ",
        to_string(enum.name),
        Utils.optional_to_doc(enum.directives, opts, separator: " ", prefix: " "),
        Utils.optional_to_doc(enum.values, opts, prefix: " ")
      ])
    end
  end
end
