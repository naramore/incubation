defmodule GraphqlSpec.Language.ListValue do
  @moduledoc ~S"""
  ListValue[Const] :
    - [ ]
    - [ Value[?Const]+ ]

  Lists are ordered sequences of values wrapped in square-brackets `[ ]`. The
  values of a List literal may be any value literal or variable (ex. `[1, 2, 3]`).

  Commas are optional throughout GraphQL so trailing commas are allowed and repeated
  commas do not represent missing values.

  ## Semantics

  ListValue : [ ]

    * Return a new empty list value.

  ListValue : [ Value+ ]

    * Let {inputList} be a new empty list value.
    * For each {Value+}
      * Let {value} be the result of evaluating {Value}.
      * Append {value} to {inputList}.
    * Return {inputList}

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#list-value).
  """
  use GraphqlSpec.Language

  defstruct [values: []]
  @type t :: %__MODULE__{
    values: [Language.value]
  }

  defimpl GraphqlSpec.Encoder do
    def encode(list_value, _opts \\ []) do
      values = GraphqlSpec.Encoder.encode(list_value.values, joiner: ", ")
      "[#{values}]"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(list_value, opts) do
      container_opts = [separator: ",", break: :flex]
      container_doc("[", list_value.values, "]", opts, &to_doc/2, container_opts)
    end
  end
end
