defmodule Digraph do
  @moduledoc """
  TENTATIVE, NAIVE, UNOPTIMIZED, INCOMPLETE
  """
  import Kernel, except: [update_in: 3]
  alias EQL.AST.{Join, Property, Root, Union, Union.Entry}
  require Logger
  
  defstruct vertices: [],
            edges: [],
            options: []
  @type t :: %__MODULE__{
    vertices: [vertex],
    edges: [edge],
    options: [:digraph.d_type]
  }
  
  @type vertex :: {:digraph.vertex, :digraph.label}
  @type edge :: {:digraph.edge, :digraph.vertex, :digraph.vertex, :digraph.label}
  
  def from_digraph(dg) do
    
  end

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
  
  @type plan :: [[atom | {:and, [plan]}]]
  
  # FIXME: translate will only work with single output resolvers atm
  def translate(_index, []), do: []
  def translate(index, [h | t]) when is_list(h) do
    [translate(index, h) | translate(index, t)]
  end
  def translate(index, [{:and, ps, n} | t]) do
    %{input: ni, output: [no]} = Map.get(index.resolvers, n)
    [{:and, translate(index, ps), {ni, no}} | translate(index, t)]
  end
  def translate(index, [h | t]) do
    %{input: [i], output: [o]} = Map.get(index.resolvers, h)
    [{i, o} | translate(index, t)]
  end
  
  def new_acc() do
    %{plan: [], unreachable_attrs: MapSet.new([]), attr_trail: [], res_trail: [], count: 0}
  end
  
  def pipe_debug(result, msg) do
    _ = Logger.debug(msg)
    result
  end

  # TODO: refactor + change acc & state -> struct(s)
  # TODO: change logging -> tracing?
  def walk(graph, source_attrs, attr, acc) do
    _ = Logger.debug("enter walk: attr=#{attr}")
    :digraph.in_edges(graph, attr)
    |> Enum.map(&:digraph.edge(graph, &1))
    |> Enum.reduce(acc, fn
      {e, i, o, %{id: id}}, acc ->
        _ = Logger.debug("enter edge=#{inspect({e, i, o})}, path=#{inspect(acc.attr_trail)}")
        cond do
          i in acc.unreachable_attrs ->
            _ = Logger.debug("unreachable: attr=#{i}")
            acc
          i in acc.attr_trail ->
            _ = Logger.debug("cyclic: attr=#{i}")
            acc
          known?(i, source_attrs) ->
            _ = Logger.debug("known: attr=#{i}")
            %{acc | plan: [[id | acc.res_trail] | acc.plan], count: acc.count + 1}
          is_list(i) and length(i) > 1 ->
            _ = Logger.debug("and-branch: attr=#{inspect(i)}")
            state =
              Enum.reduce(i, %{acc: acc, plans: []}, fn i, s ->
                _ = Logger.debug("continue walk: attr=#{inspect(i)}")
                case walk(graph, source_attrs, i, %{s.acc | attr_trail: [attr | s.acc.attr_trail], res_trail: [], count: 0, plan: []}) do
                  %{count: 0} = acc ->
                    _ = Logger.debug("unreachable and-branch: attr=#{i} | unreachable=#{inspect(acc.unreachable_attrs)}")
                    %{s | acc: %{s.acc | unreachable_attrs: MapSet.put(acc.unreachable_attrs, i)}, plans: [{i, []} | s.plans]}
                  acc ->
                    _ = Logger.debug("reachable and-branch: attr=#{i}")
                    %{s | acc: %{s.acc | unreachable_attrs: acc.unreachable_attrs}, plans: [{i, acc.plan} | s.plans]}
                end
              end)
            if Enum.all?(state.plans, fn {_, p} -> length(p) > 0 end) do
              _ = Logger.debug("reachable and: attr=#{inspect(i)}")
              and_plan = [{:and, Enum.map(state.plans, &elem(&1, 1)), id} | state.acc.res_trail]
              %{state.acc | plan: [and_plan | state.acc.plan], count: acc.count + 1}
            else
              _ = Logger.debug("unreachable and: attr=#{inspect(i)}")
              %{state.acc | unreachable_attrs: MapSet.put(state.acc.unreachable_attrs, i)}
            end
          true ->
            _ = Logger.debug("continue walk: attr=#{i}")
            case walk(graph, source_attrs, i, %{acc | attr_trail: [attr | acc.attr_trail], res_trail: [id | acc.res_trail], count: 0}) do
              %{count: 0, unreachable_attrs: uattrs} ->
                _ = Logger.debug("unreachable walk: attr=#{i}")
                %{acc | unreachable_attrs: MapSet.put(uattrs, i)}
              %{plan: plan, unreachable_attrs: uattrs} ->
                _ = Logger.debug("reachable paths: attr=#{i}")
                %{acc | plan: plan, unreachable_attrs: uattrs, count: acc.count + 1}
            end
        end
        |> pipe_debug("leave edge=#{inspect({e, i, o})}")
    end)
    |> pipe_debug("leave walk: attr=#{attr}")
  end
  
  def create_vertex(graph, dest, source \\ nil)
  def create_vertex(graph, dest, nil) do
    _ = :digraph.add_vertex(graph, dest)
    graph
  end
  def create_vertex(graph, dest, source) do
    _ = create_vertex(graph, dest, nil)
    
    :digraph.out_neighbours(graph, source)
    |> Enum.map(&:digraph.vertex(graph, &1))
    |> case do
      [] -> :digraph.add_edge(graph, source, dest)
      [{next, :or}] -> :digraph.add_edge(graph, next, dest)
      [{next, _}] ->
        or_vertex = :digraph.add_vertex(graph)
        or_vertex = :digraph.add_vertex(graph, or_vertex, :or)
        [e] = :digraph.out_edges(graph, source)
        _ = :digraph.add_edge(graph, e, source, or_vertex, nil)
        _ = :digraph.add_edge(graph, or_vertex, next)
        :digraph.add_edge(graph, or_vertex, dest)
      _ -> nil
    end
    
    graph
  end

  def known?([], _known), do: true
  def known?(input, known) when is_list(input), do: Enum.all?(input, &(&1 in known))
  def known?(input, known), do: input in known
  
  def to_graphvix(dg) do
    g = Graphvix.Graph.new()
    
    {g, _} =
      :digraph.vertices(dg)
      |> Enum.reduce({g, nil}, fn v, {g, _} -> Graphvix.Graph.add_vertex(g, v) end)

    {g, _} =
      :digraph.edges(dg)
      |> Enum.map(&:digraph.edge(dg, &1))
      |> Enum.reduce({g, nil}, fn {_, i, o, label}, {g, _} ->
        Graphvix.Graph.add_edge(g, i, o, Enum.into(label, []))
      end)
      
    g
  end
end

defmodule Digraph.Viz do
  # DOT - https://graphviz.org/doc/info/lang.html
  #   graph 	: 	[ strict ] (graph | digraph) [ ID ] '{' stmt_list '}'
  #   stmt_list 	: 	[ stmt [ ';' ] stmt_list ]
  #   stmt 	: 	node_stmt
  #   	| 	edge_stmt
  #   	| 	attr_stmt
  #   	| 	ID '=' ID
  #   	| 	subgraph
  #   attr_stmt 	: 	(graph | node | edge) attr_list
  #   attr_list 	: 	'[' [ a_list ] ']' [ attr_list ]
  #   a_list 	: 	ID '=' ID [ (';' | ',') ] [ a_list ]
  #   edge_stmt 	: 	(node_id | subgraph) edgeRHS [ attr_list ]
  #   edgeRHS 	: 	edgeop (node_id | subgraph) [ edgeRHS ]
  #   node_stmt 	: 	node_id [ attr_list ]
  #   node_id 	: 	ID [ port ]
  #   port 	: 	':' ID [ ':' compass_pt ]
  #   	| 	':' compass_pt
  #   subgraph 	: 	[ subgraph [ ID ] ] '{' stmt_list '}'
  #   compass_pt 	: 	(n | ne | e | se | s | sw | w | nw | c | _)
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
    [%{:"citrix.xapi.vm/all" => [:"citrix.xapi.vm/opaque-reference"]}]
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

strange = [
  %{id: :r1, input: [:a], output: [:b]},
  %{id: :r2, input: [:c], output: [:d]},
  %{id: :r3, input: [:c], output: [:e]},
  %{id: :r4, input: [:e], output: [:l]},
  %{id: :r5, input: [:l], output: [:m]},
  %{id: :r6, input: [:l], output: [:n]},
  %{id: :r7, input: [:n], output: [:o]},
  %{id: :r8, input: [:m], output: [:p]},
  %{id: :r9, input: [:o], output: [:p]},
  %{id: :r10, input: [:g], output: [:k]},
  %{id: :r11, input: [:h], output: [:g]},
  %{id: :r12, input: [:i], output: [:h]},
  %{id: :r13, input: [:j], output: [:i]},
  %{id: :r14, input: [:g], output: [:j]},
  %{id: :r15, input: [:b, :d], output: [:f]},
  %{id: :r16, input: [:q], output: [:r]},
  %{id: :r17, input: [:t], output: [:v]},
  %{id: :r18, input: [:u], output: [:v]},
  %{id: :r19, input: [:v], output: [:w]},
  %{id: :r20, input: [:r, :w], output: [:s]},
  %{id: :r21, input: [:s], output: [:y]},
  %{id: :r22, input: [:y], output: [:z]},
  %{id: :r23, input: [:z], output: [:o]},
  %{id: :r24, input: [:aa], output: [:ab]},
  %{id: :r25, input: [:ab], output: [:z]},
  %{id: :r26, input: [:ac], output: [:y]},
  %{id: :r27, input: [:ad], output: [:ac]},
  %{id: :r28, input: [:ae], output: [:ad]},
  %{id: :r29, input: [:ae], output: [:af]},
  %{id: :r30, input: [:af], output: [:ab]},
  %{id: :r31, input: [:ad], output: [:ab]},
  %{id: :r32, input: [:f], output: [:k]},
  %{id: :r33, input: [:k], output: [:p]},
]
sg = :digraph.new()
strange_index = Digraph.index(strange, sg)
sres = Digraph.walk(sg, [:c, :q, :t, :u, :ae], :p, Digraph.new_acc())
# Digraph.translate(strange_index, sres.plan) |> pp.()
pp.(sres)
