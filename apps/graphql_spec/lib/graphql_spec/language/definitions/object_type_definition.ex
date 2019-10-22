defmodule GraphqlSpec.Language.ObjectTypeDefinition do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.{Directive, FieldDefinition}

  defstruct [:description, :name, interfaces: [], directives: [], fields: []]
  @type t :: %__MODULE__{
    description: String.t | nil,
    name: Language.name,
    interfaces: [Language.name] | nil,
    directives: [Directive.t] | nil,
    fields: [FieldDefinition.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(object, _opts \\ []) do
      with description = encode_description(object.description),
           name = object.name,
           interfaces = encode_interfaces(object.interfaces),
           directives = encode_directives(object.directives),
           fields = encode_fields(object.fields) do
        "#{description}type #{name}#{interfaces}#{directives}#{fields}"
      end
    end

    defp encode_description(nil), do: ""
    defp encode_description(description) do
      description = GraphqlSpec.Encoder.encode(description)
      "#{description} "
    end

    defp encode_interfaces(nil), do: ""
    defp encode_interfaces([]), do: ""
    defp encode_interfaces(interfaces) do
      interfaces
      |> Enum.map(&to_string/1)
      |> Enum.join(" & ")
      |> (&" implements #{&1}").()
    end

    defp encode_directives(nil), do: ""
    defp encode_directives([]), do: ""
    defp encode_directives(directives) do
      directives = GraphqlSpec.Encoder.encode(directives, joiner: " ")
      " #{directives}"
    end

    defp encode_fields(nil), do: ""
    defp encode_fields([]), do: ""
    defp encode_fields(fields) do
      fields = GraphqlSpec.Encoder.encode(fields, joiner: "\n")
      " {#{fields}}"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias GraphqlSpec.Language.Inspect.Utils

    def inspect(%{name: nil}), do: empty()
    def inspect(object, opts) do
      concat([
        Utils.optional_to_doc(object.description, opts, suffix: " "),
        "type ",
        to_string(object.name),
        inspect_interfaces(object.interfaces),
        Utils.optional_to_doc(object.directives, opts, separator: " ", prefix: " "),
        container_doc("{", object.fields, "}", opts, &to_doc/2, break: :flex, prefix: " ")
      ])
    end

    @spec inspect_interfaces([Language.name] | nil) :: Inspect.Algebra.t
    defp inspect_interfaces(nil), do: empty()
    defp inspect_interfaces([]), do: empty()
    defp inspect_interfaces([_|_] = interfaces) do
      interfaces
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(" & ")
      |> (&concat([" implements "|&1])).()
    end
  end
end
