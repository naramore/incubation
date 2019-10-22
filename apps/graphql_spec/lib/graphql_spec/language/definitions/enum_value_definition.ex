defmodule GraphqlSpec.Language.EnumValueDefinition do
  @moduledoc ~S"""
  EnumValuesDefinition : { EnumValueDefinition+ }

  EnumValueDefinition : Description? EnumValue Directives[Const]?

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

  ## Result Coercion

  GraphQL servers must return one of the defined set of possible values. If a
  reasonable coercion is not possible they must raise a field error.

  ## Input Coercion

  GraphQL has a constant literal to represent enum input values. GraphQL string
  literals must not be accepted as an enum input and instead raise a query error.

  Query variable transport serializations which have a different representation
  for non-string symbolic values (for example, [EDN](https://github.com/edn-format/edn))
  should only allow such values as enum input values. Otherwise, for most
  transport serializations that do not, strings may be interpreted as the enum
  input value with the same name.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#enums).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:description, :value, directives: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    value: Language.name,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(enum_value_definition, _opts \\ []) do
      with description = encode_description(enum_value_definition.description),
           value = enum_value_definition.value,
           directives = encode_directives(enum_value_definition.directives) do
        "#{description}#{value}#{directives}"
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
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{value: nil}, _opts), do: empty()
    def inspect(enum_value_definition, opts) do
      concat([
        Utils.optional_to_doc(enum_value_definition.description, opts, suffix: " "),
        to_string(enum_value_definition.value),
        Utils.optional_to_doc(enum_value_definition.directives, opts, separator: " ", prefix: " "),
      ])
    end
  end
end
