defmodule GraphqlSpec.Language do
  @type name :: String.t
  @type value ::
    GraphqlSpec.Language.Variable.t |
    integer |
    float |
    String.t |
    boolean |
    nil |
    GraphqlSpec.Language.EnumValue.t |
    GraphqlSpec.Language.ListValue.t |
    GraphqlSpec.Language.ObjectValue.t
  @type type ::
    GraphqlSpec.Language.NamedType.t |
    GraphqlSpec.Language.ListType.t |
    GraphqlSpec.Language.NonNullType.t

  @callback fromTaggedList([{atom, [term]}]) :: struct

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour GraphqlSpec.Language
      alias GraphqlSpec.Language

      @impl GraphqlSpec.Language
      def fromTaggedList(data) do
        struct = struct(__MODULE__, %{})

        struct
        |> Map.from_struct()
        |> Enum.reduce(struct, fn
          {key, []}, acc -> Map.put(acc, key, Language.extract_tagged_list(data, key))
          {key, nil}, acc -> Map.put(acc, key, Language.extract_tagged_value(data, key))
        end)
      end

      defoverridable [fromTaggedList: 1]
    end
  end

  @spec extract_tagged_value([term], term, term) :: term
  def extract_tagged_value(values, key, default \\ nil) do
    case values[key] do
      nil ->
        default

      [value] ->
        value
    end
  end

  @spec extract_tagged_list([term], term) :: [term]
  def extract_tagged_list(values, key) do
    case values[key] do
      nil ->
        []

      list ->
        list
    end
  end
end
