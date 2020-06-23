defmodule Pathom.Index do
  alias Pathom.{Resolver, Index.Attribute}

  defstruct resolvers: %{},
            reverse: %{},
            reach: %{},
            idents: MapSet.new([]),
            attributes: %{}
  @type t :: %__MODULE__{
    resolvers: %{optional(Resolver.name) => Resolver.t},
    # mutations: %{optional(mutation_name) => mutation},
    reverse: %{optional(attribute) => %{optional(Resolver.input) => MapSet.t(Resolver.name)}},
    reach: %{optional(Pathom.attribute_set) => reach},
    idents: MapSet.t(attribute),
    attributes: %{optional(attribute) => Attribute.t}
  }

  @type attribute :: Attribute.attribute
  @type reach :: %{optional(attribute) => reach}
  @type resolver_or_resolvers :: Resolver.t | [resolver_or_resolvers]
  @type index :: map | MapSet.t(any)

  @spec new(keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @spec register(t, resolver_or_resolvers) :: t
  def register(index, []) do
    index
  end
  def register(index, [h | t]) do
    index
    |> register(h)
    |> register(t)
  end
  def register(index, %Resolver{} = resolver) do
    add(index, resolver)
  end

  # FIXME: refactor
  @spec add(t, Resolver.t) :: t
  def add(index, %Resolver{name: name} = resolver) do
    provides =
      resolver
      |> Map.get(:output, [])
      |> normalize_io()

    resolver = %Resolver{input: raw_input, output: output} =
      %{resolver | provides: provides}

    input =
      if reach_contains?(index, raw_input) do
        MapSet.new([])
      else
        raw_input
      end

    merge(
      index,
      new(
        resolvers: %{name => resolver},
        attributes: index_attributes(resolver),
        reach: %{input => provides},
        idents: (if Enum.count(input) == 1, do: input, else: MapSet.new([])),
        reverse: (output
                  |> flat_query()
                  |> Enum.reduce(%{}, fn attr, acc ->
                    if ident_of?(attr, raw_input) do
                      acc
                    else
                      Map.update(
                        acc,
                        attr,
                        %{raw_input => MapSet.new([name])},
                        fn oir ->
                          Map.update(
                            oir,
                            raw_input,
                            MapSet.new([name]),
                            &MapSet.put(&1, name)
                          )
                        end
                      )
                    end
                  end)
                  )
      )
    )
  end

  @spec merge(t, t) :: t
  def merge(a, b) do
    b
    |> Map.from_struct()
    |> Enum.reduce(a, fn {k, v}, idx ->
      Map.update!(idx, k, &index_merger(k, &1, v))
    end)
  end

  @spec normalize_io(Resolver.output) :: reach
  def normalize_io(output) do
    output
    |> normalize_io_impl()
    |> Enum.into(%{})
  end

  @spec index_merger(atom, index, index) :: index
  defp index_merger(:reach, a, b), do: merge_io(a, b)
  defp index_merger(:reverse, a, b), do: merge_oir(a, b)
  defp index_merger(:attributes, a, b), do: merge_grow(a, b)
  defp index_merger(_, a, b), do: merge_grow(a, b)

  @spec merge_grow(index, index) :: index
  defp merge_grow(%MapSet{} = a, %MapSet{} = b) do
    MapSet.union(a, b)
  end
  defp merge_grow(%{} = a, %{} = b) do
    Map.merge(a, b, fn _, x, y -> merge_grow(x, y) end)
  end
  defp merge_grow(a, nil) do
    a
  end
  defp merge_grow(_, b) do
    b
  end

  @spec merge_oir(map, map) :: map
  defp merge_oir(a, b) do
    Map.merge(a, b, fn _, x, y -> MapSet.union(x, y) end)
  end

  @spec merge_io(map, map) :: map
  def merge_io(a, b) do
    Map.merge(a, b, fn _, x, y -> merge_io_attrs(x, y) end)
  end

  @spec merge_io_attrs(any, any) :: any
  defp merge_io_attrs(%{} = a, %{} = b) do
    Map.merge(a, b, fn _, x, y -> merge_io_attrs(x, y) end)
  end
  defp merge_io_attrs(%{} = a, _) do
    a
  end
  defp merge_io_attrs(_, b) do
    b
  end

  @spec normalize_io_impl(Resolver.output) :: [{attribute, reach}]
  defp normalize_io_impl(%{} = union) do
    unions =
      union
      |> Enum.map(fn {k, v} -> {k, normalize_io_impl(v)} end)
      |> Enum.into(%{})

    unions
    |> Map.values()
    |> Enum.reduce(nil, &merge_io_attrs(&2, &1))
    |> Map.put(:__unions__, unions)
  end
  defp normalize_io_impl([]) do
    []
  end
  defp normalize_io_impl([%{} = h | t]) do
    [{k, v} | _] = Enum.into(h, [])
    [{k, Enum.into(normalize_io_impl(v), %{})} | normalize_io_impl(t)]
  end
  defp normalize_io_impl([h | t]) do
    [{h, %{}} | normalize_io_impl(t)]
  end

  @spec flat_query(Resolver.output) :: [attribute]
  defp flat_query(%{} = query) do
    query
    |> Map.values()
    |> Enum.map(&flat_query/1)
    |> Enum.concat()
  end
  defp flat_query(query) do
    case EQL.query_to_ast(query) do
      {:ok, %{children: children}} ->
        Enum.map(children, &Map.get(&1, :key))
      _ -> []
    end
  end

  @spec reach_contains?(t, MapSet.t) :: boolean
  defp reach_contains?(index, input) do
    case Enum.into(input, []) do
      [item] ->
        index.reach
        |> Map.get(MapSet.new([]), %{})
        |> Enum.member?(item)
      _ -> false
    end
  end

  @spec ident_of?(attribute, MapSet.t) :: boolean
  defp ident_of?(attr, set) do
    MapSet.member?(set, attr) and Enum.count(set) == 1
  end

  @spec index_attributes(Resolver.t) :: %{optional(attribute) => Attribute.t}
  defp index_attributes(%Resolver{name: name, input: input, output: output}) do
    provides = output |> output_provides() |> Enum.reject(&Enum.member?(input, &1))
    name_group = MapSet.new([name])
    attr_provides = provides |> Enum.zip(Stream.repeatedly(fn -> name_group end)) |> Enum.into(%{})
    input_count = Enum.count(input)

    # FIXME: finish
    attributes =
      input_count
      |> case do
        0 -> [MapSet.new([])]
        1 -> input
        _ -> [input]
      end
      |> Enum.reduce(%{}, fn id, idx ->
        attribute = Attribute.new(
          id: id,
          provides: attr_provides,
          input_in: name_group
        )
        Map.update(idx, id, attribute, &Map.merge(&1, attribute))
      end)
  end

  defp output_provides(%{} = query) do
    query
    |> Map.values()
    |> Enum.map(&output_provides/1)
    |> Enum.concat()
  end
  defp output_provides(query) do
    query
    |> EQL.query_to_ast()
    |> Map.get(:children, [])
    |> Enum.map(&output_provides_impl/1)
    |> Enum.concat()
  end

  defp output_provides_impl(%{children: [%EQL.AST.Union{} | _]} = query) do
    query.key
  end

  defmodule Attribute do
    alias Pathom.Resolver

    defstruct id: nil,
              input_in: MapSet.new([]),
              output_in: MapSet.new([]),
              provides: %{},
              reach_via: %{},
              leaf_in: MapSet.new([]),
              branch_in: MapSet.new([])
    @type t :: %__MODULE__{
      id: attribute,
      input_in: MapSet.t(Resolver.name),
      output_in: MapSet.t(Resolver.name),
      provides: %{optional(path) => MapSet.t(Resolver.name)},
      reach_via: %{optional(path) => MapSet.t(Resolver.name)},
      leaf_in: MapSet.t(Resolver.name),
      branch_in: MapSet.t(Resolver.name)
    }

    @type global :: MapSet.t
    @type attribute :: global | Pathom.attribute
    @type path :: attribute | [attribute]
  end
end

# parse:          edn -> eql -> ast
# compile_index:  [resolvers] -> %Index{resolvers, idents, oir, io, attributes, graph}
# plan:           ast + index -> plan
# execute:        plan + execution_strategy -> edn

defmodule Digraph do
  def resolver(id, input, output \\ []) do
    %{
      id: id,
      input: input,
      output: output
    }
  end

  def graph([], dg), do: dg
  def graph([res | t], dg) do
    input =
      case res.input do
        [x] -> [x]
        x -> [x | x]
      end

    _ = Enum.each(input, &:digraph.add_vertex(dg, &1))
    #_ = add_output(res.output, dg)
    graph(t, dg)
  end

  def add_output([], _), do: :ok
  def add_output([{k, v} | t], dg) do
    add_output(k, dg)
    add_output(v, dg)
    add_output(t, dg)
  end
  def add_output(%{} = output, dg) do
    add_output(Enum.into(output, []), dg)
  end
  def add_output(attr, dg) do
    :digraph.add_vertex(dg, attr)
  end
end

resolvers = [
  Digraph.resolver(
    :"get-started/latest-product",
    [],
    [%{:"get-started/latest-product" => [:"product/id", :"product/title", :"product/price"]}]
  ),
  Digraph.resolver(
    :"get-started/product-brand",
    [:"product/id"],
    [:"product/brand"]
  ),
  Digraph.resolver(
    :"get-started/brand-id-from-name",
    [:"product/brand"],
    [:"product/brand-id"]
  ),
]
dg = :digraph.new()
Digraph.graph(resolvers, dg)
:digraph.vertices(dg)
