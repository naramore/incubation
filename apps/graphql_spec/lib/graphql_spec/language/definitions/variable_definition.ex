defmodule GraphqlSpec.Language.VariableDefinition do
  @moduledoc ~S"""
  VariableDefinitions : ( VariableDefinition+ )

  VariableDefinition : Variable : Type DefaultValue? Directives[Const]?

  A GraphQL query can be parameterized with variables, maximizing query reuse,
  and avoiding costly string building in clients at runtime.

  If not defined as constant (for example, in {DefaultValue}), a {Variable} can be
  supplied for an input value.

  Variables must be defined at the top of an operation and are in scope
  throughout the execution of that operation.

  In this example, we want to fetch a profile picture size based on the size
  of a particular device:

  ```graphql example
  query getZuckProfile($devicePicSize: Int) {
    user(id: 4) {
      id
      name
      profilePic(size: $devicePicSize)
    }
  }
  ```

  Values for those variables are provided to a GraphQL service along with a
  request so they may be substituted during execution. If providing JSON for the
  variables' values, we could run this query and request profilePic of
  size `60` width:

  ```json example
  {
    "devicePicSize": 60
  }
  ```

  **Variable use within Fragments**

  Query variables can be used within fragments. Query variables have global scope
  with a given operation, so a variable used within a fragment must be declared
  in any top-level operation that transitively consumes that fragment. If
  a variable is referenced in a fragment and is included by an operation that does
  not define that variable, the operation cannot be executed.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#variables)
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.DefaultValue

  defstruct [:variable, :type, :default_value]
  @type t :: %__MODULE__{
    variable: Language.name,
    type: Language.type,
    default_value: DefaultValue.t | nil
  }

  defimpl GraphqlSpec.Encoder do
    alias GraphqlSpec.Encoder

    def encode(variable_definition, _opts \\ []) do
      with variable = Encoder.encode(variable_definition.variable),
           value = Encoder.encode(variable_definition.type),
           default_value = encode_default_value(variable_definition.default_value) do
        "#{variable}: #{value}#{default_value}"
      end
    end

    defp encode_default_value(nil), do: ""
    defp encode_default_value(default_value) do
      Encoder.encode(default_value)
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(variable, opts) do

    end
  end
end
