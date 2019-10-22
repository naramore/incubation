defmodule GraphqlSpec.Language.ScalarTypeDefinition do
  @moduledoc """
  ScalarTypeDefinition : Description? scalar Name Directives[Const]?

  Scalar types represent primitive leaf values in a GraphQL type system. GraphQL
  responses take the form of a hierarchical tree; the leaves on these trees are
  GraphQL scalars.

  All GraphQL scalars are representable as strings, though depending on the
  response format being used, there may be a more appropriate primitive for the
  given scalar type, and server should use those types when appropriate.

  GraphQL provides a number of built-in scalars, but type systems can add
  additional scalars with semantic meaning. For example, a GraphQL system could
  define a scalar called `Time` which, while serialized as a string, promises to
  conform to ISO-8601. When querying a field of type `Time`, you can then rely on
  the ability to parse the result with an ISO-8601 parser and use a
  client-specific primitive for time. Another example of a potentially useful
  custom scalar is `Url`, which serializes as a string, but is guaranteed by
  the server to be a valid URL.

  ```graphql example
  scalar Time
  scalar Url
  ```

  A server may omit any of the built-in scalars from its schema, for example if a
  schema does not refer to a floating-point number, then it may omit the
  `Float` type. However, if a schema includes a type with the name of one of the
  types described here, it must adhere to the behavior described. As an example,
  a server must not include a type called `Int` and use it to represent
  128-bit numbers, internationalization information, or anything other than what
  is defined in this document.

  When representing a GraphQL schema using the type system definition language,
  the built-in scalar types should be omitted for brevity.

  **Result Coercion**

  A GraphQL server, when preparing a field of a given scalar type, must uphold the
  contract the scalar type describes, either by coercing the value or producing a
  field error if a value cannot be coerced or if coercion may result in data loss.

  A GraphQL service may decide to allow coercing different internal types to the
  expected return type. For example when coercing a field of type `Int` a boolean
  `true` value may produce `1` or a string value `"123"` may be parsed as base-10
  `123`. However if internal type coercion cannot be reasonably performed without
  losing information, then it must raise a field error.

  Since this coercion behavior is not observable to clients of the GraphQL server,
  the precise rules of coercion are left to the implementation. The only
  requirement is that the server must yield values which adhere to the expected
  Scalar type.

  **Input Coercion**

  If a GraphQL server expects a scalar type as input to an argument, coercion
  is observable and the rules must be well defined. If an input value does not
  match a coercion rule, a query error must be raised.

  GraphQL has different constant literals to represent integer and floating-point
  input values, and coercion rules may apply differently depending on which type
  of input value is encountered. GraphQL may be parameterized by query variables,
  the values of which are often serialized when sent over a transport like HTTP. Since
  some common serializations (ex. JSON) do not discriminate between integer
  and floating-point values, they are interpreted as an integer input value if
  they have an empty fractional part (ex. `1.0`) and otherwise as floating-point
  input value.

  For all types below, with the exception of Non-Null, if the explicit value
  {null} is provided, then the result of input coercion is {null}.

  **Built-in Scalars**

  GraphQL provides a basic set of well-defined Scalar types. A GraphQL server
  should support all of these types, and a GraphQL server which provide a type by
  these names must adhere to the behavior described below.


  ### Int

  The Int scalar type represents a signed 32-bit numeric non-fractional value.
  Response formats that support a 32-bit integer or a number type should use
  that type to represent this scalar.

  **Result Coercion**

  Fields returning the type `Int` expect to encounter 32-bit integer
  internal values.

  GraphQL servers may coerce non-integer internal values to integers when
  reasonable without losing information, otherwise they must raise a field error.
  Examples of this may include returning `1` for the floating-point number `1.0`,
  or returning `123` for the string `"123"`. In scenarios where coercion may lose
  data, raising a field error is more appropriate. For example, a floating-point
  number `1.2` should raise a field error instead of being truncated to `1`.

  If the integer internal value represents a value less than -2<sup>31</sup> or
  greater than or equal to 2<sup>31</sup>, a field error should be raised.

  **Input Coercion**

  When expected as an input type, only integer input values are accepted. All
  other input values, including strings with numeric content, must raise a query
  error indicating an incorrect type. If the integer input value represents a
  value less than -2<sup>31</sup> or greater than or equal to 2<sup>31</sup>, a
  query error should be raised.

  Note: Numeric integer values larger than 32-bit should either use String or a
  custom-defined Scalar type, as not all platforms and transports support
  encoding integer numbers larger than 32-bit.


  ### Float

  The Float scalar type represents signed double-precision fractional values
  as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point).
  Response formats that support an appropriate double-precision number type
  should use that type to represent this scalar.

  **Result Coercion**

  Fields returning the type `Float` expect to encounter double-precision
  floating-point internal values.

  GraphQL servers may coerce non-floating-point internal values to `Float` when
  reasonable without losing information, otherwise they must raise a field error.
  Examples of this may include returning `1.0` for the integer number `1`, or
  `123.0` for the string `"123"`.

  **Input Coercion**

  When expected as an input type, both integer and float input values are
  accepted. Integer input values are coerced to Float by adding an empty
  fractional part, for example `1.0` for the integer input value `1`. All
  other input values, including strings with numeric content, must raise a query
  error indicating an incorrect type. If the integer input value represents a
  value not representable by IEEE 754, a query error should be raised.


  ### String

  The String scalar type represents textual data, represented as UTF-8 character
  sequences. The String type is most often used by GraphQL to represent free-form
  human-readable text. All response formats must support string representations,
  and that representation must be used here.

  **Result Coercion**

  Fields returning the type `String` expect to encounter UTF-8 string internal values.

  GraphQL servers may coerce non-string raw values to `String` when reasonable
  without losing information, otherwise they must raise a field error. Examples of
  this may include returning the string `"true"` for a boolean true value, or the
  string `"1"` for the integer `1`.

  **Input Coercion**

  When expected as an input type, only valid UTF-8 string input values are
  accepted. All other input values must raise a query error indicating an
  incorrect type.


  ### Boolean

  The Boolean scalar type represents `true` or `false`. Response formats should
  use a built-in boolean type if supported; otherwise, they should use their
  representation of the integers `1` and `0`.

  **Result Coercion**

  Fields returning the type `Boolean` expect to encounter boolean internal values.

  GraphQL servers may coerce non-boolean raw values to `Boolean` when reasonable
  without losing information, otherwise they must raise a field error. Examples of
  this may include returning `true` for non-zero numbers.

  **Input Coercion**

  When expected as an input type, only boolean input values are accepted. All
  other input values must raise a query error indicating an incorrect type.


  ### ID

  The ID scalar type represents a unique identifier, often used to refetch an
  object or as the key for a cache. The ID type is serialized in the same way as
  a `String`; however, it is not intended to be human-readable. While it is
  often numeric, it should always serialize as a `String`.

  **Result Coercion**

  GraphQL is agnostic to ID format, and serializes to string to ensure consistency
  across many formats ID could represent, from small auto-increment numbers, to
  large 128-bit random numbers, to base64 encoded values, or string values of a
  format like [GUID](https://en.wikipedia.org/wiki/Globally_unique_identifier).

  GraphQL servers should coerce as appropriate given the ID formats they expect.
  When coercion is not possible they must raise a field error.

  **Input Coercion**

  When expected as an input type, any string (such as `"4"`) or integer (such as
  `4` or `-4`) input value should be coerced to ID as appropriate for the ID
  formats a given GraphQL server expects. Any other input value, including float
  input values (such as `4.0`), must raise a query error indicating an incorrect
  type.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#scalars).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Directive

  defstruct [:description, :name, directives: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(scalar_type, _opts \\ []) do
      with description = encode_description(scalar_type.description),
           name = scalar_type.name,
           directives = encode_directives(scalar_type.directives) do
        "#{description}scalar #{name}#{directives}"
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

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(scalar, opts) do
      concat([
        Utils.optional_to_doc(scalar.description, opts),
        "scalar ",
        to_string(scalar.name),
        Utils.optional_to_doc(scalar.directives, opts, separator: " ", prefix: " ")
      ])
    end
  end
end
