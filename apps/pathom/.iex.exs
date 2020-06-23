defmodule Digraph do
  @moduledoc """
  TENTATIVE, NAIVE, UNOPTIMIZED, INCOMPLETE

  NOTES:
    - {module, atom} properties, unions, and multi-inputs may not work...
      - add the 'virtual' in_edges for multi-inputs (for indexing purposes only)
      - add the edges for multi-inputs, but label them differently (would require filtering these out...)
        - I'm leaning more towards this one (b/c traversal -> plan might be more straightforward?)
    - refactor to remove all instances of `++`
    - entity -> all attributes gathered + unreachable + path + deps
      - 'where we are', 'where we have been', and 'everything gathered along the way'
      - entity + ast -> result (i.e. traverse ast & entity -> build result)
    - plan graph nodes will need to have ids + labels w/ attributes (b/c graph 'collapsing')
    - plan traversal:
      - accumulation:
        - track attributes / nodes (+ structure to build 'entity')
        - track past resolvers / edges
        - track missing attributes / output
      - what step next? when nothing is directly achievable, what gets me closer?
      - track 'reductions' for optimizing paths? (path traversal optimization?)
      - plan nodes:
        - resolver
        - and
        - or
      - plan edges -> resolver execution order & deps

  TODO:
    - [x] resolvers -> digraph
    - [x] digraph -> oir
    - [x] digraph -> resolvers
    - [x] digraph -> io
    - [x] digraph -> attributes
    - [ ] digraph -> graph_index_attrs?
    - [ ] digraph + ast -> plan{nodes: [resolver | and | or]}
    - [ ] traverse(plan, entity, (node, entity -> {node, entity})) -> entity
  """
  import Kernel, except: [update_in: 3]
  alias EQL.AST.{Join, Property, Root, Union, Union.Entry}

  def resolver(id, input, output \\ []) do
    %{
      id: id,
      input: input,
      output: output
    }
  end

  def graph([], dg), do: dg
  def graph([res | t], dg) do
    [i | _] = input =
      case res.input do
        [x] -> [x]
        x -> [x | x]
      end

    labels = output_info(res)
    output = Enum.map(labels, &Map.get(&1, :id))
    _ = Enum.each(input, &:digraph.add_vertex(dg, &1))
    _ = Enum.each(output, &:digraph.add_vertex(dg, &1))
    _ = Enum.each(labels, &:digraph.add_edge(dg, i, &1.id, %{&1 | id: res.id}))

    graph(t, dg)
  end

  def update_in(data, [], fun), do: fun.(data)
  def update_in(data, path, fun) do
    Kernel.update_in(data, path, fun)
  end

  def output_info(resolver) do
    resolver.output
    |> EQL.query_to_ast()
    |> elem(1)
    |> output_info(0, [], nil)
    |> Enum.map(fn
      {id, depth, path, union_key, leaf?} ->
        %{id: id, depth: depth, parent: Enum.reverse(path), union_key: union_key, leaf?: leaf?}
    end)
  end

  def output_info([], _, _, _), do: []
  def output_info([h | t], d, p, u), do: output_info(h, d, p, u) ++ output_info(t, d, p, u)
  def output_info(%Property{key: key}, d, p, u), do: [{key, d, p, u, true}]
  def output_info(%Join{key: key, children: cs}, d, p, u), do: [{key, d, p, u, false} | output_info(cs, d + 1, [key | p], nil)]
  def output_info(%Union{children: cs}, d, p, _), do: output_info(cs, d, p, nil)
  def output_info(%Entry{key: key, children: cs}, d, p, _), do: output_info(cs, d + 1, p, key)
  def output_info(%Root{children: cs}, _, _, _), do: output_info(cs, 0, [], nil)

  def flatten([]), do: []
  def flatten([{k, v} | t]), do: flatten([k, v | t])
  def flatten([h | t]), do: flatten(h) ++ flatten(t)
  def flatten(%{} = x), do: flatten(Enum.into(x, []))
  def flatten(x), do: [x]

  def top([]), do: []
  def top([{k, _} | t]), do: [k | top(t)]
  def top([%{} = h | t]) do
    [{k,_}|_] = Enum.into(h, [])
    [k | top(t)]
  end
  def top([h | t]), do: [h | top(t)]

  def oir(dg) do
    dg
    |> :digraph.edges()
    |> to_edges(dg)
    |> Enum.map(fn {_, i, o, %{id: r, parent: parent}} ->
      if parent == [], do: {o, i, r}
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.group_by(&elem(&1, 0), fn {_, i, r} -> {i, r} end)
    |> Enum.map(fn {o, irs} ->
      {o, Enum.group_by(irs, &elem(&1, 0), &elem(&1, 1)) |> Enum.map(fn {i, rs} -> {i, MapSet.new(rs)} end) |> Enum.into(%{})}
    end)
    |> Enum.into(%{})
  end

  def io(dg) do
    dg
    |> :digraph.edges()
    |> to_edges(dg)
    |> Enum.sort_by(fn {_, _, _, %{depth: d}} -> d end)
    |> Enum.reduce(%{}, fn {_, i, o, %{parent: p}}, io ->
      Digraph.update_in(io, [i | p], fn
        nil -> %{o => %{}}
        x -> Map.put(x, o, %{})
      end)
    end)
  end

  def idents(dg) do
    dg
    |> :digraph.edges()
    |> to_edges(dg)
    |> Enum.reject(&is_list(elem(&1, 1)))
    |> Enum.uniq_by(&Map.get(elem(&1, 3), :id))
    |> Enum.map(&elem(&1, 1))
  end

  def attributes(dg) do
    dg
    |> :digraph.vertices()
    |> Enum.map(fn v ->
      %{
        attribute: v,
        provides: provides(dg, v),
        output_in: output_in(dg, v),
        input_in: input_in(dg, v),
        reach_via: reach_via(dg, v),
        leaf_in: leaf_in(dg, v),
        branch_in: branch_in(dg, v),
      }
    end)
    |> Enum.map(&{&1.attribute, &1 |> Enum.reject(fn {:attribute, _} -> false; {_, v} -> empty?(v) end) |> Enum.into(%{})})
    |> Enum.into(%{})
  end

  def provides(dg, v) do
    dg
    |> :digraph.out_edges(v)
    |> to_edges(dg)
    |> Enum.group_by(
      fn
        {_, _, o, %{parent: []}} -> o
        {_, _, o, %{parent: p}} -> p ++ [o]
      end,
      &get_in(&1, [Access.elem(3), :id])
    )
  end

  def output_in(dg, v), do: gather_ids(dg, v, &:digraph.in_edges/2)
  def input_in(dg, v), do: gather_ids(dg, v, &:digraph.out_edges/2)
  def gather_ids(dg, v, edge_fun) do
    dg
    |> edge_fun.(v)
    |> to_edges(dg)
    |> Enum.reduce(MapSet.new([]), fn {_, _, _, %{id: id}}, ins ->
      MapSet.put(ins, id)
    end)
  end

  def leaf_in(dg, v), do: gather_tree(dg, v, &Enum.filter/2)
  def branch_in(dg, v), do: gather_tree(dg, v, &Enum.reject/2)
  def gather_tree(dg, v, filter_fun) do
    dg
    |> :digraph.in_edges(v)
    |> to_edges(dg)
    |> filter_fun.(fn {_, _, _, %{leaf?: leaf?}} -> leaf? end)
    |> Enum.map(fn {_, _, _, %{id: id}} -> id end)
    |> Enum.into(MapSet.new([]))
  end

  def reach_via(dg, v) do
    dg
    |> :digraph.in_edges(v)
    |> to_edges(dg)
    |> Enum.reduce(%{}, fn {_, i, _, %{id: id, parent: p}}, acc ->
      Map.update(acc, [i | p], MapSet.new([id]), &MapSet.put(&1, id))
    end)
  end

  def to_edges(edge_ids, dg) do
    Enum.map(edge_ids, &:digraph.edge(dg, &1))
  end

  def empty?(nil), do: true
  def empty?(x) do
    if Enumerable.impl_for(x) do
      Enum.empty?(x)
    else
      false
    end
  end

  def resolvers(dg) do
    dg
    |> :digraph.edges()
    |> to_edges(dg)
    |> Enum.group_by(fn {_, _, _, %{id: id}} -> id end)
    |> Enum.map(fn {id, [{_, i, _, _}|_] = es} ->
      %{
        id: id,
        input: (if is_list(i), do: i, else: [i]),
        output: (
          es
          |> Enum.sort_by(fn {_, _, _, %{depth: d}} -> d end)
          |> Enum.reduce([], fn {_, _, o, %{parent: p}}, acc ->
            put_in(acc, p ++ [o], [])
          end)
          |> format_output()
        )
      }
    end)
  end

  def format_output([]), do: []
  def format_output([{k, []} | t]), do: [k | format_output(t)]
  def format_output([{k, v} | t]), do: [%{k => format_output(v)} | format_output(t)]
  def format_output([h | t]), do: [h | format_output(t)]

  def index(resolvers, dg) do
    dg = graph(resolvers, dg)

    %{
      resolvers: Enum.map(resolvers, &{&1.id, &1}) |> Enum.into(%{}),
      graph: dg,
      oir: oir(dg),
      io: io(dg),
      idents: idents(dg),
      attributes: attributes(dg)
    }
  end

  def plan(graph, query) do
    case EQL.query_to_ast(query) do
      {:error, reason} -> {:error, reason}
      {:ok, ast} ->
        {ast, available} =
          Enum.reduce(ast.children, {[], %{}}, fn
            %Property{key: [k | v]}, {ns, av} -> {ns, Map.put(av, k, v)}
            %{__struct__: m} = n, {ns, av} when m in [Property, Join] -> {[n | ns], av}
            _, acc -> acc
          end)

        plan = %{
          graph: :digraph.new(),
          available: available,
          unreachable: [],
          trail: []
        }

        # NOTE: label edges w/ the attr they are executing for
        Enum.reduce(ast, plan, fn %{key: attr}, plan ->
        end)
    end
  end

  def digraph_walk(dg, source_attrs, dest_attrs) do
    plan = :digraph.new()
    _ = Enum.each(dest_attrs, &{&1, digraph_walk(dg, source_attrs, &1, plan)})
    plan
  end

  def digraph_walk(dg, source_attrs, dest_attr, plan) do
    :digraph.in_edges(dg, dest_attr)
    |> Enum.map(&:digraph.edge(dg, &1))
    |> Enum.map(fn {e, i, o, %{id: id}} ->
      if known?(i, source_attrs) do
        :digraph.add_vertex(plan, id, %{input: i, source: [o]})
      else
        case digraph_walk(dg, source_attrs, i, plan) do
          [] -> nil
          [v | vs] ->
            # create vertex / update existing vertex sources
            # connect
        end
      end
    end)
    |> Enum.reject(&is_nil/1)

  end

  def known?([], _known), do: true
  def known?(input, known) when is_list(input), do: Enum.all?(input, &(&1 in known))
  def known?(input, known), do: input in known

  # more of a 'copy' of pathom's compute-run-graph logic
  def reader_old(index, query, acc \\ %{}) do
    case EQL.query_to_ast(query) do
      {:error, reason} -> {:error, reason}
      {:ok, ast} ->
        {ast, available} =
          Enum.reduce(ast.children, {[], %{}}, fn
            %Property{key: [k | v]}, {ns, av} -> {ns, Map.put(av, k, v)}
            %{__struct__: m} = n, {ns, av} when m in [Property, Join] -> {[n | ns], av}
            _, acc -> acc
          end)

          plan = %{
            graph: :digraph.new(),
            available: available,
            unreachable: [],
            trail: []
          }
          root = :digraph.add_vertex(plan.graph, :__root__, %{provides: available})
          plan = Map.put(plan, :root, root)

          Enum.reduce(ast, plan, fn %{key: attr}, plan ->     # ast / {o, [{i, [r]}]}
            if attr in plan.available or
               attr in plan.unreachable or
               attr in plan.trail or
               Map.has_key?(index.oir, attr) or
               is_nil(get_attribute_node(plan, attr)) do
              plan
            else
              Map.get(index.oir, attr)
              |> Enum.reduce(plan, fn {i, rs}, plan ->        # {i, [r]}
                if in_input?(attr, i) do
                  plan
                else
                  Enum.reduce(rs, plan, fn r, plan ->         # r
                    if r in plan.unreachable_resolvers do
                      plan
                    else
                      v = :digraph.add_vertex(plan.graph)
                      :digraph.add_vertex(plan.graph, v, %{
                        resolver: r,
                        requires: %{attr => %{}},
                        input: Enum.map(i, &{&1, %{}}) |> Enum.into(%{}),
                        # params: ???,
                      })
                      # |> compute_root_or(...)
                    end
                  end)
                  # |> compute_missing(...)
                  # |> compute_root_or(...)
                end
              end)
              # |> compute_root_and(...)
            end
          end)
    end
  end

  def in_input?(attr, input) when is_list(input) do
    attr in input
  end
  def in_input?(attr, attr), do: true
  def in_input?(_, _), do: false

  def get_attribute_node(plan, attr) do
    plan.graph
    |> :digraph.vertices()
    |> Enum.map(&:digraph.vertex(plan.graph, &1))
    |> Enum.filter(fn {_, %{provides: p}} -> attr in p end)
    |> case do
      [{n, _} | _] -> n
      _ -> nil
    end
  end
end

pp = &IO.inspect(&1, pretty: true, limit: :infinity, printable_limit: :infinity)

xen_resolvers = [
  Digraph.resolver(
    :"citrix.xapi.vm/get-record",
    [:"citrix.xapi.vm/opaque-reference"],
    [
      :"citrix.xapi.vm/uuid",
      %{:"citrix.xapi.vm/vbds" => [:"citrix.xapi.vbd/opaque-reference"]},
      %{:"citrix.xapi.vm/vifs" => [:"citrix.xapi.vif/opaque-reference"]},
      :"citrix.xapi.vm/name-description",
      :"citrix.xapi.vm/name-label",
      :"citrix.xapi.vm/tags",
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.vm/get-by-name-label",
    [:"citrix.xapi.vm/name-label"],
    [:"citrix.xapi.vm/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vm/get-by-uuid",
    [:"citrix.xapi.vm/uuid"],
    [:"citrix.xapi.vm/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vm/get-all",
    [],
    [:"citrix.xapi.vm/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vif/get-record",
    [:"citrix.xapi.vif/opaque-reference"],
    [
      :"citrix.xapi.vif/uuid",
      :"citrix.xapi.vif/mac",
      :"citrix.xapi.vif/device",
      :"citrix.xapi.vif/currently-attached",
      :"citrix.xapi.vif/mtu",
      %{:"citrix.xapi.vif/vm" => [:"citrix.xapi.vm/opaque-reference"]},
      %{:"citrix.xapi.vif/network" => [:"citrix.xapi.network/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.vif/get-by-uuid",
    [:"citrix.xapi.vif/uuid"],
    [:"citrix.xapi.vif/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vif/get-all",
    [],
    [:"citrix.xapi.vif/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.network/get-record",
    [:"citrix.xapi.network/opaque-reference"],
    [
      :"citrix.xapi.network/uuid",
      :"citrix.xapi.network/mtu",
      %{:"citrix.xapi.network/vifs" => [:"citrix.xapi.vif/opaque-reference"]},
      %{:"citrix.xapi.network/pifs" => [:"citrix.xapi.pif/opaque-reference"]},
      :"citrix.xapi.network/bridge",
      :"citrix.xapi.network/name-description",
      :"citrix.xapi.network/name-label",
      :"citrix.xapi.network/tags",
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.network/get-by-name-label",
    [:"citrix.xapi.network/name-label"],
    [:"citrix.xapi.network/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.network/get-by-uuid",
    [:"citrix.xapi.network/uuid"],
    [:"citrix.xapi.network/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.network/get-all",
    [],
    [:"citrix.xapi.network/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.pif/get-record",
    [:"citrix.xapi.pif/opaque-reference"],
    [
      :"citrix.xapi.pif/uuid",
      :"citrix.xapi.pif/mac",
      :"citrix.xapi.pif/mtu",
      :"citrix.xapi.pif/dns",
      :"citrix.xapi.pif/ip",
      :"citrix.xapi.pif/vlan",
      %{:"citrix.xapi.pif/host" => [:"citrix.xapi.host/opaque-reference"]},
      %{:"citrix.xapi.pif/network" => [:"citrix.xapi.network/opaque-reference"]},
      %{:"citrix.xapi.pif/bond-master-of" => [:"citrix.xapi.bond/opaque-reference"]},
      %{:"citrix.xapi.pif/bond-slave-of" => [:"citrix.xapi.bond/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.pif/get-by-uuid",
    [:"citrix.xapi.pif/uuid"],
    [:"citrix.xapi.pif/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.pif/get-all",
    [],
    [:"citrix.xapi.pif/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vbd/get-record",
    [:"citrix.xapi.vbd/opaque-reference"],
    [
      :"citrix.xapi.vbd/uuid",
      :"citrix.xapi.vbd/device",
      %{:"citrix.xapi.vbd/vdi" => [:"citrix.xapi.vdi/opaque-reference"]},
      %{:"citrix.xapi.vbd/vm" => [:"citrix.xapi.vm/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.vbd/get-by-uuid",
    [:"citrix.xapi.vbd/uuid"],
    [:"citrix.xapi.vbd/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vbd/get-all",
    [],
    [:"citrix.xapi.vbd/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vdi/get-record",
    [:"citrix.xapi.vdi/opaque-reference"],
    [
      :"citrix.xapi.vdi/uuid",
      :"citrix.xapi.vdi/location",
      :"citrix.xapi.vdi/name-description",
      :"citrix.xapi.vdi/name-label",
      %{:"citrix.xapi.vdi/parent" => [:"citrix.xapi.vdi/opaque-reference"]},
      %{:"citrix.xapi.vdi/sr" => [:"citrix.xapi.sr/opaque-reference"]},
      %{:"citrix.xapi.vdi/vbds" => [:"citrix.xapi.vbd/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.vdi/get-by-name-label",
    [:"citrix.xapi.vdi/name-label"],
    [:"citrix.xapi.vdi/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vdi/get-by-uuid",
    [:"citrix.xapi.vdi/uuid"],
    [:"citrix.xapi.vdi/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.vdi/get-all",
    [],
    [:"citrix.xapi.vdi/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.sr/get-record",
    [:"citrix.xapi.sr/opaque-reference"],
    [
      :"citrix.xapi.sr/uuid",
      :"citrix.xapi.sr/tags",
      :"citrix.xapi.sr/name-description",
      :"citrix.xapi.sr/name-label",
      %{:"citrix.xapi.sr/vdis" => [:"citrix.xapi.vdi/opaque-reference"]},
      %{:"citrix.xapi.sr/pbds" => [:"citrix.xapi.pbd/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.sr/get-by-name-label",
    [:"citrix.xapi.sr/name-label"],
    [:"citrix.xapi.sr/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.sr/get-by-uuid",
    [:"citrix.xapi.sr/uuid"],
    [:"citrix.xapi.sr/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.sr/get-all",
    [],
    [:"citrix.xapi.sr/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.pbd/get-record",
    [:"citrix.xapi.pbd/opaque-reference"],
    [
      :"citrix.xapi.pbd/uuid",
      :"citrix.xapi.pbd/currently-attached",
      %{:"citrix.xapi.pbd/host" => [:"citrix.xapi.host/opaque-reference"]},
      %{:"citrix.xapi.pbd/sr" => [:"citrix.xapi.sr/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.pbd/get-by-uuid",
    [:"citrix.xapi.pbd/uuid"],
    [:"citrix.xapi.pbd/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.pbd/get-all",
    [],
    [:"citrix.xapi.pbd/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.host/get-record",
    [:"citrix.xapi.host/opaque-reference"],
    [
      :"citrix.xapi.host/uuid",
      :"citrix.xapi.host/enabled",
      :"citrix.xapi.host/hostname",
      :"citrix.xapi.host/name-label",
      :"citrix.xapi.host/name-description",
      :"citrix.xapi.host/tags",
      :"citrix.xapi.host/address",
      %{:"citrix.xapi.host/pbds" => [:"citrix.xapi.pbd/opaque-reference"]},
      %{:"citrix.xapi.host/pifs" => [:"citrix.xapi.pif/opaque-reference"]},
      %{:"citrix.xapi.host/control-domain" => [:"citrix.xapi.vm/opaque-reference"]},
      %{:"citrix.xapi.host/resident-vms" => [:"citrix.xapi.vm/opaque-reference"]},
      %{:"citrix.xapi.host/uuid" => [:"citrix.xapi.host/opaque-reference"]},
      %{:"citrix.xapi.host/local-cache-sr" => [:"citrix.xapi.sr/opaque-reference"]},
      %{:"citrix.xapi.host/suspend-image-sr" => [:"citrix.xapi.sr/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.host/get-by-name-label",
    [:"citrix.xapi.host/name-label"],
    [:"citrix.xapi.host/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.host/get-by-uuid",
    [:"citrix.xapi.host/uuid"],
    [:"citrix.xapi.host/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.host/get-all",
    [],
    [:"citrix.xapi.host/opaque-reference"]
  ),
  Digraph.resolver(
    :"citrix.xapi.session/get-record",
    [:"citrix.xapi.session/opaque-reference"],
    [
      :"citrix.xapi.session/uuid",
      :"citrix.xapi.session/last-active",
      :"citrix.xapi.session/validation-time",
      :"citrix.xapi.session/originator",
      %{:"citrix.xapi.session/parent" => [:"citrix.xapi.session/opaque-reference"]},
      %{:"citrix.xapi.session/tasks" => [:"citrix.xapi.task/opaque-reference"]},
      %{:"citrix.xapi.session/this-host" => [:"citrix.xapi.host/opaque-reference"]},
      %{:"citrix.xapi.session/this-user" => [:"citrix.xapi.user/opaque-reference"]},
    ]
  ),
  Digraph.resolver(
    :"citrix.xapi.session/get-by-uuid",
    [:"citrix.xapi.session/uuid"],
    [:"citrix.xapi.session/opaque-reference"]
  ),
]

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
  Digraph.resolver(
    :"get-started/widget",
    [:"product/brand-id", :"user/id"],
    [:"widget/description", :"widget/id"]
  ),
]

xg = :digraph.new()
xen_index = Digraph.index(xen_resolvers, xg)

dg = :digraph.new()
index = Digraph.index(resolvers, dg)
# pp.(index)
