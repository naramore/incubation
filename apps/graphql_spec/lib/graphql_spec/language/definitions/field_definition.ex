defmodule GraphqlSpec.Language.FieldDefinition do
  @moduledoc """
  FieldsDefinition : { FieldDefinition+ }

  FieldDefinition : Description? Name ArgumentsDefinition? : Type Directives[Const]?

  GraphQL queries are hierarchical and composed, describing a tree of information.
  While Scalar types describe the leaf values of these hierarchical queries, Objects
  describe the intermediate levels.

  GraphQL Objects represent a list of named fields, each of which yield a value of
  a specific type. Object values should be serialized as ordered maps, where the
  queried field names (or aliases) are the keys and the result of evaluating
  the field is the value, ordered by the order in which they appear in the query.

  All fields defined within an Object type must not have a name which begins with
  {"__"} (two underscores), as this is used exclusively by GraphQL's
  introspection system.

  For example, a type `Person` could be described as:

  ```graphql example
  type Person {
    name: String
    age: Int
    picture: Url
  }
  ```

  Where `name` is a field that will yield a `String` value, and `age` is a field
  that will yield an `Int` value, and `picture` is a field that will yield a
  `Url` value.

  A query of an object value must select at least one field. This selection of
  fields will yield an ordered map containing exactly the subset of the object
  queried, which should be represented in the order in which they were queried.
  Only fields that are declared on the object type may validly be queried on
  that object.

  For example, selecting all the fields of `Person`:

  ```graphql example
  {
    name
    age
    picture
  }
  ```

  Would yield the object:

  ```json example
  {
    "name": "Mark Zuckerberg",
    "age": 30,
    "picture": "http://some.cdn/picture.jpg"
  }
  ```

  While selecting a subset of fields:

  ```graphql example
  {
    age
    name
  }
  ```

  Must only yield exactly that subset:

  ```json example
  {
    "age": 30,
    "name": "Mark Zuckerberg"
  }
  ```

  A field of an Object type may be a Scalar, Enum, another Object type,
  an Interface, or a Union. Additionally, it may be any wrapping type whose
  underlying base type is one of those five.

  For example, the `Person` type might include a `relationship`:

  ```graphql example
  type Person {
    name: String
    age: Int
    picture: Url
    relationship: Person
  }
  ```

  Valid queries must supply a nested field set for a field that returns
  an object, so this query is not valid:

  ```graphql counter-example
  {
    name
    relationship
  }
  ```

  However, this example is valid:

  ```graphql example
  {
    name
    relationship {
      name
    }
  }
  ```

  And will yield the subset of each object type queried:

  ```json example
  {
    "name": "Mark Zuckerberg",
    "relationship": {
      "name": "Priscilla Chan"
    }
  }
  ```

  **Field Ordering**

  When querying an Object, the resulting mapping of fields are conceptually
  ordered in the same order in which they were encountered during query execution,
  excluding fragments for which the type does not apply and fields or
  fragments that are skipped via `@skip` or `@include` directives. This ordering
  is correctly produced when using the {CollectFields()} algorithm.

  Response serialization formats capable of representing ordered maps should
  maintain this ordering. Serialization formats which can only represent unordered
  maps (such as JSON) should retain this order textually. That is, if two fields
  `{foo, bar}` were queried in that order, the resulting JSON serialization
  should contain `{"foo": "...", "bar": "..."}` in the same order.

  Producing a response where fields are represented in the same order in which
  they appear in the request improves human readability during debugging and
  enables more efficient parsing of responses if the order of properties can
  be anticipated.

  If a fragment is spread before other fields, the fields that fragment specifies
  occur in the response before the following fields.

  ```graphql example
  {
    foo
    ...Frag
    qux
  }

  fragment Frag on Query {
    bar
    baz
  }
  ```

  Produces the ordered result:

  ```json example
  {
    "foo": 1,
    "bar": 2,
    "baz": 3,
    "qux": 4
  }
  ```

  If a field is queried multiple times in a selection, it is ordered by the first
  time it is encountered. However fragments for which the type does not apply does
  not affect ordering.

  ```graphql example
  {
    foo
    ...Ignored
    ...Matching
    bar
  }

  fragment Ignored on UnknownType {
    qux
    baz
  }

  fragment Matching on Query {
    bar
    qux
    foo
  }
  ```

  Produces the ordered result:

  ```json example
  {
    "foo": 1,
    "bar": 2,
    "qux": 3
  }
  ```

  Also, if directives result in fields being excluded, they are not considered in
  the ordering of fields.

  ```graphql example
  {
    foo @skip(if: true)
    bar
    foo
  }
  ```

  Produces the ordered result:

  ```json example
  {
    "bar": 1,
    "foo": 2
  }
  ```

  **Result Coercion**

  Determining the result of coercing an object is the heart of the GraphQL
  executor, so this is covered in that section of the spec.

  **Input Coercion**

  Objects are never valid inputs.

  **Type Validation**

  Object types have the potential to be invalid if incorrectly defined. This set
  of rules must be adhered to by every Object type in a GraphQL schema.

  1. An Object type must define one or more fields.
  2. For each field of an Object type:
    1. The field must have a unique name within that Object type;
        no two fields may share the same name.
    2. The field must not have a name which begins with the
        characters {"__"} (two underscores).
    3. The field must return a type where {IsOutputType(fieldType)} returns {true}.
    4. For each argument of the field:
        1. The argument must not have a name which begins with the
          characters {"__"} (two underscores).
        2. The argument must accept a type where {IsInputType(argumentType)}
          returns {true}.
  4. An object type may declare that it implements one or more unique interfaces.
  5. An object type must be a super-set of all interfaces it implements:
    1. The object type must include a field of the same name for every field
        defined in an interface.
        1. The object field must be of a type which is equal to or a sub-type of
          the interface field (covariant).
          1. An object field type is a valid sub-type if it is equal to (the same
              type as) the interface field type.
          2. An object field type is a valid sub-type if it is an Object type and
              the interface field type is either an Interface type or a Union type
              and the object field type is a possible type of the interface field
              type.
          3. An object field type is a valid sub-type if it is a List type and
              the interface field type is also a List type and the list-item type
              of the object field type is a valid sub-type of the list-item type
              of the interface field type.
          4. An object field type is a valid sub-type if it is a Non-Null variant
              of a valid sub-type of the interface field type.
        2. The object field must include an argument of the same name for every
          argument defined in the interface field.
          1. The object field argument must accept the same type (invariant) as
              the interface field argument.
        3. The object field may include additional arguments not defined in the
          interface field, but any additional argument must not be required, e.g.
          must not be of a non-nullable type.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%203%20--%20Type%20System.md#objects).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, InputValueDefinition}

  defstruct [:description, :name, :type, arguments: [], directives: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    arguments: [InputValueDefinition.t] | nil,
    type: Language.type,
    directives: [Directive.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(field, _opts \\ []) do
      with description = encode_description(field.description),
           name = field.name,
           arguments = encode_arguments(field.arguments),
           type = GraphqlSpec.Encoder.encode(field.type),
           directives = encode_directives(field.directives) do
        "#{description}#{name}#{arguments}: #{type}#{directives}"
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
      arguments = GraphqlSpec.Encoder.encode(arguments, joiner: " ")
      "(#{arguments})"
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
    def inspect(%{type: nil}, _opts), do: empty()
    def inspect(field, opts) do
      concat([
        Utils.optional_to_doc(field.description, opts, suffix: " "),
        to_string(field.name),
        Utils.optional_to_doc(field.arguments, opts, left: "(", right: ")", separator: " "),
        ": ",
        to_string(field.type),
        Utils.optional_to_doc(field.directives, opts, separator: " ", prefix: " ")
      ])
    end
  end
end
