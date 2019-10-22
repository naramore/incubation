defmodule GraphqlSpec.Language.ObjectValue do
  @moduledoc ~S"""
  ObjectValue[Const] :
    - { }
    - { ObjectField[?Const]+ }

  Input object literal values are unordered lists of keyed input values wrapped in
  curly-braces `{ }`. The values of an object literal may be any input value
  literal or variable (ex. `{ name: "Hello world", score: 1.0 }`). We refer to
  literal representation of input objects as "object literals."

  **Input object fields are unordered**

  Input object fields may be provided in any syntactic order and maintain
  identical semantic meaning.

  These two queries are semantically identical:

  ```graphql example
  {
    nearestThing(location: { lon: 12.43, lat: -53.211 })
  }
  ```

  ```graphql example
  {
    nearestThing(location: { lat: -53.211, lon: 12.43 })
  }
  ```

  ## Semantics

  ObjectValue : { }

    * Return a new input object value with no fields.

  ObjectValue : { ObjectField+ }

    * Let {inputObject} be a new input object value with no fields.
    * For each {field} in {ObjectField+}
      * Let {name} be {Name} in {field}.
      * Let {value} be the result of evaluating {Value} in {field}.
      * Add a field to {inputObject} of name {name} containing value {value}.
    * Return {inputObject}


  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#input-object-values).
  """
  use GraphqlSpec.Language

  defstruct [fields: []]
  @type t :: %__MODULE__{
    fields: [Language.ObjectField.t]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(object_value, _opts \\ []) do
      fields = GraphqlSpec.Encoder.encode(object_value.fields, joiner: ", ")
      "{#{fields}}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(object_value, opts) do
      container_opts = [separator: ",", break: :flex]
      container_doc("{", object_value.fields, "}", opts, &to_doc/2, container_opts)
    end
  end
end
