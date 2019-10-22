defmodule GraphqlSpec.Language.Argument do
  @moduledoc ~S"""
  Arguments[Const] : ( Argument[?Const]+ )

  Argument[Const] : Name : Value[?Const]

  Fields are conceptually functions which return values, and occasionally accept
  arguments which alter their behavior. These arguments often map directly to
  function arguments within a GraphQL server's implementation.

  In this example, we want to query a specific user (requested via the `id`
  argument) and their profile picture of a specific `size`:

  ```graphql example
  {
    user(id: 4) {
      id
      name
      profilePic(size: 100)
    }
  }
  ```

  Many arguments can exist for a given field:

  ```graphql example
  {
    user(id: 4) {
      id
      name
      profilePic(width: 100, height: 50)
    }
  }
  ```

  **Arguments are unordered**

  Arguments may be provided in any syntactic order and maintain identical
  semantic meaning.

  These two queries are semantically identical:

  ```graphql example
  {
    picture(width: 200, height: 100)
  }
  ```

  ```graphql example
  {
    picture(height: 100, width: 200)
  }
  ```

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#arguments).
  """
  use GraphqlSpec.Language

  defstruct [:name, :value]
  @type t :: %__MODULE__{
    name: Language.name,
    value: Language.value
  }

  defimpl GraphqlSpec.Encoder do
    def encode(argument, _opts \\ []) do
      encoded_value = GraphqlSpec.Encoder.encode(argument.value)
      "#{argument.name}: #{encoded_value}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(%{value: nil}, _opts), do: empty()
    def inspect(argument, opts) do
      concat([to_string(argument.name), ":", to_doc(argument.value, opts)])
    end
  end
end
