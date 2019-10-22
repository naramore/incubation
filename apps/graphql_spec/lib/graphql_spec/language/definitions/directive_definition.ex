defmodule GraphqlSpec.Language.DirectiveDefinition do
  @moduledoc ~S"""
  DirectiveDefinition : Description? directive @ Name ArgumentsDefinition? on DirectiveLocations

  DirectiveLocations :
    - `|`? DirectiveLocation
    - DirectiveLocations | DirectiveLocation

  DirectiveLocation :
    - ExecutableDirectiveLocation
    - TypeSystemDirectiveLocation

  ExecutableDirectiveLocation : one of
    `QUERY`
    `MUTATION`
    `SUBSCRIPTION`
    `FIELD`
    `FRAGMENT_DEFINITION`
    `FRAGMENT_SPREAD`
    `INLINE_FRAGMENT`
    `VARIABLE_DEFINITION`

  TypeSystemDirectiveLocation : one of
    `SCHEMA`
    `SCALAR`
    `OBJECT`
    `FIELD_DEFINITION`
    `ARGUMENT_DEFINITION`
    `INTERFACE`
    `UNION`
    `ENUM`
    `ENUM_VALUE`
    `INPUT_OBJECT`
    `INPUT_FIELD_DEFINITION`

  A GraphQL schema describes directives which are used to annotate various parts
  of a GraphQL document as an indicator that they should be evaluated differently
  by a validator, executor, or client tool such as a code generator.

  GraphQL implementations should provide the `@skip` and `@include` directives.

  GraphQL implementations that support the type system definition language must
  provide the `@deprecated` directive if representing deprecated portions of
  the schema.

  Directives must only be used in the locations they are declared to belong in.
  In this example, a directive is defined which can be used to annotate a field:

  ```graphql example
  directive @example on FIELD

  fragment SomeFragment on SomeType {
    field @example
  }
  ```

  Directive locations may be defined with an optional leading `|` character to aid
  formatting when representing a longer list of possible locations:

  ```graphql example
  directive @example on
    | FIELD
    | FRAGMENT_SPREAD
    | INLINE_FRAGMENT
  ```

  Directives can also be used to annotate the type system definition language
  as well, which can be a useful tool for supplying additional metadata in order
  to generate GraphQL execution services, produce client generated runtime code,
  or many other useful extensions of the GraphQL semantics.

  In this example, the directive `@example` annotates field and argument definitions:

  ```graphql example
  directive @example on FIELD_DEFINITION | ARGUMENT_DEFINITION

  type SomeType {
    field(arg: Int @example): String @example
  }
  ```

  While defining a directive, it must not reference itself directly or indirectly:

  ```graphql counter-example
  directive @invalidExample(arg: String @invalidExample) on ARGUMENT_DEFINITION
  ```

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#directives).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Argument

  @type directive_location ::
    executable_directive_location |
    type_system_directive_location

  @type executable_directive_location ::
    :query |
    :mutation |
    :subscription |
    :field |
    :fragment_definition |
    :fragment_spread |
    :inline_fragment

  @type type_system_directive_location ::
    :schema |
    :scalar |
    :object |
    :field_definition |
    :argument_definition |
    :interface |
    :union |
    :enum |
    :enum_value |
    :input_object |
    :input_field_definition

  defstruct [:description, :name, arguments: [], locations: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    arguments: [Argument.t] | nil,
    locations: [directive_location]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(directive_definition, _opts \\ []) do
      with description = encode_description(directive_definition.description),
           name = directive_definition.name,
           arguments = encode_arguments(directive_definition.arguments),
           locations = encode_locations(directive_definition.locations) do
        "#{description}directive @#{name}#{arguments} on #{locations}"
      end
    end

    defp encode_description(nil), do: ""
    defp encode_description(description) do
      description = GraphqlSpec.Encoder.encode(description)
      "#{description} "
    end

    defp encode_arguments(nil), do: ""
    defp encode_arguments([]), do: ""
    defp encode_arguments(arguments) do
      arguments = GraphqlSpec.Encoder.encode(arguments, joiner: ", ")
      "(#{arguments})"
    end

    defp encode_locations(nil), do: ""
    defp encode_locations([]), do: ""
    defp encode_locations(locations) do
      locations
      |> Enum.map(&encode_location/1)
      |> Enum.join(" | ")
    end

    defp encode_location(location) do
      location
      |> to_string()
      |> String.upcase()
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(%{locations: []}, _opts), do: empty()
    def inspect(directive_definition, opts) do
      fun = fn loc, _opts -> loc |> to_string() |> String.upcase() end
      concat([
        Utils.optional_to_doc(directive_definition.description, opts, suffix: " "),
        space("directive", "@"),
        to_string(directive_definition.name),
        Utils.optional_to_doc(directive_definition.arguments, opts, left: "(", right: ")", separator: ","),
        " on ",
        Utils.optional_to_doc(directive_definition.locations, opts, separator: " | ", fun: fun)
      ])
    end
  end
end
