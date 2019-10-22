defmodule GraphqlSpec.Language.Field do
  @moduledoc ~S"""
  Field : Alias? Name Arguments? Directives? SelectionSet?

  A selection set is primarily composed of fields. A field describes one discrete
  piece of information available to request within a selection set.

  Some fields describe complex data or relationships to other data. In order to
  further explore this data, a field may itself contain a selection set, allowing
  for deeply nested requests. All GraphQL operations must specify their selections
  down to fields which return scalar values to ensure an unambiguously
  shaped response.

  For example, this operation selects fields of complex data and relationships
  down to scalar values.

  ```graphql example
  {
    me {
      id
      firstName
      lastName
      birthday {
        month
        day
      }
      friends {
        name
      }
    }
  }
  ```

  Fields in the top-level selection set of an operation often represent some
  information that is globally accessible to your application and its current
  viewer. Some typical examples of these top fields include references to a
  current logged-in viewer, or accessing certain types of data referenced by a
  unique identifier.

  ```graphql example
  # `me` could represent the currently logged in viewer.
  {
    me {
      name
    }
  }

  # `user` represents one of many users in a graph of data, referred to by a
  # unique identifier.
  {
    user(id: 4) {
      name
    }
  }
  ```

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#fields).
  """
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Argument, Directive, Selection}

  defstruct [:alias, :name, arguments: [], directives: [], selections: []]
  @type t :: %__MODULE__{
    alias: Language.name | nil,
    name: Language.name,
    arguments: [Argument.t] | nil,
    directives: [Directive.t] | nil,
    selections: [Selection.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    alias GraphqlSpec.Encoder

    def encode(field, _opts \\ []) do
      with alias = encode_alias(field.alias),
           name = field.name,
           arguments = encode_arguments(field.arguments),
           directives = encode_directives(field.directives),
           selection_set = encode_selections(field.selections) do
        "#{alias}#{name}#{arguments}#{directives}#{selection_set}"
      end
    end

    defp encode_alias(nil), do: ""
    defp encode_alias(alias) do
      "#{Encoder.encode(alias)} "
    end

    defp encode_arguments(nil), do: ""
    defp encode_arguments([]), do: ""
    defp encode_arguments(arguments) do
      "(#{Encoder.encode(arguments, joiner: ", ")})"
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      " #{Encoder.encode(directives, joiner: " ")}"
    end

    defp encode_selections(nil), do: ""
    defp encode_selections([]), do: ""
    defp encode_selections(selections) do
      " {#{Encoder.encode(selections, joiner: "\n")}}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(field, opts) do
      concat([
        (if is_nil(field.alias), do: empty(), else: concat([to_string(field.alias), " "])),
        to_string(field.name),
        Utils.optional_to_doc(field.arguments, opts, left: "(", right: ")", separator: ","),
        Utils.optional_to_doc(field.directives, opts, separator: " ", prefix: " "),
        Utils.optional_to_doc(field.selections, opts, left: "{", right: "}", prefix: " "),
      ])
    end
  end
end
