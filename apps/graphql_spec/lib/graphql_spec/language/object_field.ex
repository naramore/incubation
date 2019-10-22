defmodule GraphqlSpec.Language.ObjectField do
  @moduledoc ~S"""
  ObjectField[Const] : Name : Value[?Const]

  ## Semantics

  * Let {name} be {Name} in {field}.
  * Let {value} be the result of evaluating {Value} in {field}.
  * Add a field to {inputObject} of name {name} containing value {value}.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#input-object-values).
  """
  use GraphqlSpec.Language

  defstruct [:name, :value]
  @type t :: %__MODULE__{
    name: Language.name,
    value: Language.value
  }

  defimpl GraphqlSpec.Encoder do
    def encode(object_field, _opts \\ []) do
      value = GraphqlSpec.Encoder.encode(object_field.value)
      "#{object_field.name}: #{value}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(%{value: nil}, _opts), do: empty()
    def inspect(object_field, opts) do
      concat([
        to_string(object_field.name),
        ":",
        to_doc(object_field.value, opts)
      ])
    end
  end
end
