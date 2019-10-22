defmodule GraphqlSpec.Language.Directive do
  use GraphqlSpec.Language
  alias GraphqlSpec.Language.Argument

  defstruct [:name, arguments: []]
  @type t :: %__MODULE__{
    name: Language.name,
    arguments: [Argument.t] | nil
  }

  defimpl GraphqlSpec.Encoder do
    def encode(directive, _opts \\ []) do
      directive.arguments
      |> GraphqlSpec.Encoder.encode(joiner: ", ")
      |> (&"@#{directive.name}(#{&1})").()
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{name: nil}, _opts), do: empty()
    def inspect(directive, opts) do
      container_opts = [separator: ",", break: :flex]
      arguments =
        container_doc("(", directive.arguments, ")", opts, &to_doc/2, container_opts)
      concat(["@", to_string(directive.name), arguments])
    end
  end
end
