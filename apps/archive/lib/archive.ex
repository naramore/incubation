defmodule Archive do
end

defmodule TriqData do
  @type size :: non_neg_integer
  @type domain(a) :: t(a) | :triq_dom.domain(a)

  @default_size 10

  defstruct [:domain]
  @type t :: t(term)
  @type t(a) :: %__MODULE__{
    domain: :triq_dom.domain(a)
  }

  @compile {:inline, new: 1, wrap: 1}

  @spec new(domain(a)) :: t(a) when a: term
  def new(%__MODULE__{} = domain), do: domain
  def new(domain), do: %__MODULE__{domain: domain}

  @spec wrap({domain(a), a} | domain(a)) :: {domain(a), a} | domain(a) when a: term
  def wrap({domain, value}), do: {new(domain), value}
  def wrap(domain), do: new(domain)

  @spec pick(domain(a), size) :: {t(a), a} when a: term
  def pick(domain, size \\ @default_size)
  def pick(%__MODULE__{domain: domain}, size), do: pick(domain, size)
  def pick(domain, size), do: :triq_dom.pick(domain, size) |> wrap()

  @spec sample(domain(a), count :: pos_integer, size) :: {t(a), [a]} when a: term
  def sample(domain, count \\ 10, initial_size \\ 1, size_fun \\ fn s -> min(s + 1, 100) end) do
    {dom, vals, _} =
      Enum.reduce(1..count, {domain, [], initial_size}, fn _, {dom, vals, size} ->
        {dom, val} = pick(dom, size)
        {dom, [val|vals], size_fun.(size)}
      end)
    {dom, vals}
  end

  @spec shrink(domain(a), a) :: {t(a), a} when a: term
  def shrink(%__MODULE__{domain: domain}, value), do: shrink(domain, value)
  def shrink(domain, value), do: :triq_dom.shrink(domain, value) |> wrap()

  @spec list_of(domain(a)) :: t([a]) when a: term
  def list_of(%__MODULE__{domain: domain}), do: list_of(domain)
  def list_of(domain), do: :triq_dom.list(domain) |> wrap()

  @spec integer(Range.t) :: t(integer)
  def integer(min..max), do: :triq_dom.int(min, max) |> wrap()
end

defmodule TestCheck do
  # pick, sample, shrink
  # for_all, for_all_targetted, implies
  # when_fail, exists, not_exists
  # trap_exit, timeout, setup
  # conjunction, equals
  # ------------------
  # measure, classify
  # aggregate, collect
  ##################################################
  # atom, binary, bitstring
  # boolean, byte, float, integer, int, bool
  # string, term, any, timeout, real
  # iodata, iolist, char, charlist
  # {pos, neg, non_neg}_{integer, float}
  # number, range, arity, mfa, module
  # ------------------
  # tuple, map, struct, set, vector, ordered_list, uniq_list, loose_tuple
  # list, keyword, improper_list, maybe_improper_list
  # non_empty, fixed_{list, map}, optional_map
  # ------------------
  # function
  ##################################################
  # bind, bind_filter, let, lazy
  # constant, exactly, return, filter
  # frequency, map, member_of, one_of
  # union, weighted_union, choose, elements
  # default, weighted_default
  # resize, scale, sized
  # noshrink, unshrinkable
  # seeded
  ##################################################
  # *size* -> min_length, max_length, length
  # ------------------
  # tuple -> {t1, t2, ...}
  # fixed_list -> [t1, t2, ...]
  # fixed_map -> %{k1 => t1, k2 => t2, ...}
  # optional_map -> "
  # ------------------
  # loose_tuple -> t, *size*
  # list -> t, *size*, improper_t, improper: :yes, :maybe, :no
  # uniq_list -> t, *size*, uniq_fun
  # keyword -> t, *size*, atom_opts
  # map -> kt, vt, *size*
  # ------------------
  # function -> arity|[t1, t2, ...], ret_t
  # atom -> kind, *size*
  # binary -> *size*
  # bitstring -> *size*
  # float -> min, max
  # integer -> range
  # string -> kind, codepoints, *size*, encoding
  # ------------------
  # no_shrink -> t
  # one_of -> [t]
  # member_of -> [term]
  # resize -> t, size
  # sized -> (size -> t)
  # seeded -> t, seed
  # bind -> t, (t, x -> t)
  # bound_domain -> {t1, x1, t2, (t, x -> t)}
  # filter -> t, (x -> boolean)
  # ------------------
  # seal -> t, seed
  # sealed -> t, value
end

defprotocol TestCheck.Generator do
  @type size :: non_neg_integer
  @type seed :: :rand.state

  @spec pick(t, non_neg_integer, :rand.state) :: {t, size, seed, value} when value: term
  def pick(generator, size, seed)

  @spec shrink(t, value) :: {t, shrunk_value :: value} when value: term
  def shrink(generator, value)
end

defmodule Domain do
  @moduledoc """
  """

  @typedoc """
  """
  @type size :: pos_integer

  @typedoc """
  """
  @type seed :: :rand.state

  @typedoc """
  """
  @type pick_fun(a) :: (t(a), size, seed -> {t(a), a, seed})

  @typedoc """
  """
  @type shrink_fun(a) :: (t(a), a, seed -> {t(a), a, seed})

  @typedoc """
  """
  @type domain(a) :: t(a) | [domain(a)] | tuple() | %{optional(term) => domain(a)} | (() -> domain(a)) | a
  @type domain :: domain(term)
  # NOTE: for domain(x) doc -> tuple() would ideally be tuple(t(x)) (which doesn't exist...)
  # NOTE: t(a) is Enumerable but domain(a) IS NOT!

  defstruct [
    kind: nil,
    pick: nil,
    shrink: nil,
    empty_ok?: true
  ]
  @type t :: t(term)
  @type t(a) :: %__MODULE__{
    kind: atom | tuple,
    pick: pick_fun(a),
    shrink: shrink_fun(a),
    empty_ok?: boolean
  }

  # TODO: remove once we depend on OTP 20+ since :exs64 is deprecated.
  if String.to_integer(System.otp_release()) >= 20 do
    @default_algorithm :exsp
  else
    @default_algorithm :exs64
  end

  @doc """
  """
  @spec new_seed(seed | :rand.seed, :rand.builtin_alg) :: seed
  def new_seed(seed_or_state \\ :erlang.timestamp(), algorithm \\ @default_algorithm)
  def new_seed({alg_handler, alg_state} = state, _algorithm)
    when is_map(alg_handler) and is_tuple(alg_state) do
      :rand.seed_s(state)
  end
  def new_seed(seed, algorithm) do
    :rand.seed_s(algorithm, seed)
  end

  @compile {:inline, wrap: 1, unwrap: 1}

  @type wrapped(a) :: {:wrapped, a}

  @doc """
  """
  @spec wrap(term) :: t
  def wrap(term) do
    %__MODULE__{kind: {:wrapper, term}}
  end

  @doc """
  """
  @spec unwrap(t) :: term
  def unwrap(%__MODULE__{kind: {:wrapped, wrapped}}) do
    wrapped
  end

  @size 10

  @doc """
  """
  @spec pick(domain(a), size, seed) :: {domain(a), a, seed} when a: term
  def pick(domain, size \\ @size, seed \\ new_seed())
  def pick(%__MODULE__{kind: {:wrapped, wrapped}}, size, seed) do
    {dom, val, seed} = pick(wrapped, size, seed)
    {wrap(dom), val, seed}
  end
  def pick(%__MODULE__{pick: pick_fun} = dom, size, seed)
    when is_integer(size) and size > 0 do
      pick_fun.(dom, size, seed)
  end
  def pick({}, size, seed), do: {{}, {}, size, seed}
  def pick(t, size, seed)
    when is_tuple(t) and is_integer(size) and size > 0 do
      {ldom, lval, lseed} = pick(Tuple.to_list(t), size, seed)
      {List.to_tuple(ldom), List.to_tuple(lval), lseed}
  end
  def pick([], _size, seed), do: {[], [], seed}
  def pick([h|t], size, seed)
    when is_integer(size) and size > 0 do
      {hdom, hval, hseed} = pick(h, size, seed)
      {tdom, tval, tseed} = pick(t, size, hseed)
      {[hdom|tdom], [hval|tval], tseed}
  end
  def pick(%{} = m, _size, seed) when map_size(m) == 0, do: {m, m, seed}
  def pick(m, size, seed)
    when is_map(m) and is_integer(size) and size > 0 do
      {mdom, mval, mseed} = pick(Map.to_list(m), size, seed)
      {Enum.into(mdom, %{}), Enum.into(mval, %{}), mseed}
  end
  def pick(fun, size, seed)
    when is_function(fun, 0) do
      pick(fun.(), size, seed)
  end
  def pick(value, _size, seed) do
    {value, value, seed}
  end

  @doc """
  """
  @spec shrink({domain(a), a, seed}) :: {domain(a), a , seed} when a: term
  def shrink({domain, value, seed}),
    do: shrink(domain, value, seed)

  @doc """
  """
  @spec shrink(domain(a), a, seed) :: {domain(a), a, seed} when a: term
  def shrink(domain, value, seed \\ new_seed())
  def shrink(%__MODULE__{kind: {:wrapped, wrapped}}, value, seed) do
    {dom, val, seed} = shrink(wrapped, value, seed)
    {wrap(dom), val, seed}
  end
  def shrink(%__MODULE__{shrink: nil} = dom, value, seed) do
    {dom, value, seed}
  end
  def shrink(%__MODULE__{shrink: shrink_fun} = dom, value, seed) do
    shrink_fun.(dom, value, seed)
  end
  def shrink(tuple_domain, tuple, seed)
    when is_tuple(tuple_domain) and is_tuple(tuple) and tuple_size(tuple_domain) == tuple_size(tuple) do
      shrink_tuple_samesize(tuple_domain, tuple, seed)
  end
  def shrink(list_domain, list, seed)
    when is_list(list_domain) and is_list(list) and length(list_domain) == length(list) do
      shrink_list_samesize(list_domain, list, seed, length(list))
  end
  def shrink([_|_] = list_domain, [_|_] = list, seed) do
    shrink_pair(list_domain, list, seed)
  end
  def shrink(%{} = map_domain, %{} = map, seed)
    when map_size(map_domain) == map_size(map) do
      shrink_map_samesize(map_domain, map, seed)
  end
  def shrink(fun, value, seed) when is_function(fun, 0) do
    shrink(fun.(), value, seed)
  end
  def shrink(value, value, seed) do
    {value, value, seed}
  end

  @shrink_attempts 10

  @spec shrink_pair([domain(h)|domain(t)], [h|t], seed, non_neg_integer) :: {[domain(h)|domain(t)], [h|t], seed} when h: term, t: term
  defp shrink_pair(list_domain, list, seed, attempts \\ @shrink_attempts)
  defp shrink_pair(list_domain, list, seed, 0), do: {list_domain, list, seed}
  defp shrink_pair([hdom|tdom] = list_dom, [h|t] = list, seed, attempts) do
    {shrink_head, seed} = :rand.uniform_s(2, seed)
    {shrink_tail, seed} = :rand.uniform_s(2, seed)
    {hsdom, hs, seed} = if shrink_head == 1, do: shrink(hdom, h, seed), else: {hdom, h, seed}
    {tsdom, ts, seed} = if shrink_tail == 1, do: shrink(tdom, t, seed), else: {tdom, t, seed}
    case {{hsdom, hs}, {tsdom, ts}} do
      {{_, ^h}, {_, ^t}} -> shrink_pair(list_dom, list, seed, attempts - 1)
      _ -> {[hsdom|tsdom], [hs|ts], seed}
    end
  end

  @spec shrink_map_samesize(%{optional(term) => domain(a)}, %{optional(term) => a}, seed, non_neg_integer) :: {%{optional(term) => domain(a)}, %{optional(term) => a}, seed} when a: term
  defp shrink_map_samesize(%{} = map_domain, %{} = map, seed, attempts \\ @shrink_attempts)
    when map_size(map_domain) == map_size(map) do
      {keys, list_dom, list} = unzip_samesize(map_domain, map)
      {shrunk_dom, shrunk_list, seed} = shrink_list_samesize(list_dom, list, seed, map_size(map), attempts)
      {shrunk_map_dom, shrunk_map} = zip_samesize(keys, shrunk_dom, shrunk_list)
      {shrunk_map_dom, shrunk_map, seed}
  end

  @spec unzip_samesize(map, map) :: {keys :: list, values1 :: list, values2 :: list}
  defp unzip_samesize(map1, map2)
    when map_size(map1) == map_size(map2) do
      keys = Map.keys(map1)
      {values1, values2} =
        Enum.reduce(keys, {[], []}, fn k, {values1, values2} ->
          {[Map.get(map1, k)|values1], [Map.get(map2, k)|values2]}
        end)
      {keys, Enum.reverse(values1), Enum.reverse(values2)}
  end

  @spec zip_samesize(keys :: list, values1 :: list, values2 :: list) :: {map, map}
  defp zip_samesize(keys, values1, values2)
    when length(keys) == length(values1) and length(keys) == length(values2) do
      zip_map = fn ks, vs -> Enum.zip(ks, vs) |> Enum.into(%{}) end
      {zip_map.(keys, values1), zip_map.(keys, values2)}
  end

  @spec shrink_tuple_samesize(tuple(), tuple(), seed, non_neg_integer) :: {tuple(), tuple(), seed}
  defp shrink_tuple_samesize(tuple_domain, tuple, seed, attempts \\ @shrink_attempts)
    when is_tuple(tuple_domain) and is_tuple(tuple) and tuple_size(tuple_domain) == tuple_size(tuple) do
      {list_dom, list} = {Tuple.to_list(tuple_domain), Tuple.to_list(tuple)}
      {shrunk_dom, shrunk_list, seed} = shrink_list_samesize(list_dom, list, seed, tuple_size(tuple), attempts)
      {List.to_tuple(shrunk_dom), List.to_tuple(shrunk_list), seed}
  end

  @spec shrink_list_samesize([t(a)], [a], seed, non_neg_integer, non_neg_integer) :: {[t(a)], [a], seed} when a: term
  defp shrink_list_samesize(domain_list, list, seed, length, attempts \\ @shrink_attempts)
  defp shrink_list_samesize([], [], seed, _length, _attempts), do: {[], [], seed}
  defp shrink_list_samesize(list_domain, list, seed, _length, 0), do: {list_domain, list, seed}
  defp shrink_list_samesize(list_domain, list, seed, length, attempts)
    when is_list(list_domain) and is_list(list) and length(list_domain) == length(list) do
      {how_many, seed} = shrink_members(length, seed)
      case shrink_list_members(list_domain, list, seed, length, how_many) do
        {_dom, ^list, seed} -> shrink_list_samesize(list_domain, list, seed, length, attempts - 1)
        {_, _, _} = result -> result
      end
  end

  @spec shrink_members(non_neg_integer, seed) :: {non_neg_integer, seed}
  defp shrink_members(0, seed), do: {0, seed}
  defp shrink_members(length, seed) when length > 0 do
    case :rand.uniform_s(5, seed) do
      {1, new_seed} -> :rand.uniform_s(5, new_seed)
      {_, new_seed} -> {1, new_seed}
    end
  end

  @spec shrink_list_members([t(a)], [a], seed, non_neg_integer, non_neg_integer) :: {t(a), [a], seed} when a: term
  defp shrink_list_members(list_domain, list, seed, _length, 0), do: {list_domain, list, seed}
  defp shrink_list_members(list_domain, list, seed, length, how_many)
    when is_list(list_domain) and is_list(list) and length == length(list) do
      {i, seed} = :rand.uniform_s(length, seed)
      {elem, elem_domain} = {:lists.nth(i, list), :lists.nth(i, list_domain)}
      {next_dom, next_list, next_seed} =
        case shrink(elem_domain, elem, seed) do
          {_dom, ^elem, seed} -> {list_domain, list, seed}
          {shrunk_elem_dom, shrunk_elem, seed} ->
            {
              List.replace_at(list_domain, i, shrunk_elem_dom),
              List.replace_at(list, i, shrunk_elem),
              seed
            }
        end
      shrink_list_members(next_dom, next_list, next_seed, length, how_many - 1)
  end

  @initial_size 1
  @max_size 100

  @doc """
  """
  @spec sample(t(a), non_neg_integer, seed, size, (size -> size)) :: {domain(a), [a], seed} when a: term
  def sample(domain, count \\ 20, seed \\ new_seed(), initial_size \\ @initial_size, size_fun \\ fn s -> min(s + 1, @max_size) end) do
    {dom, vals, _, seed} =
      Enum.reduce(1..count, {domain, [], initial_size, seed}, fn _, {dom, vals, size, seed} ->
        {dom, val, seed} = pick(dom, size, seed)
        {dom, [val|vals], size_fun.(size), seed}
      end)
    {dom, vals, seed}
  end

  # compound generators
  ########################

  @compile {:inline, get_range: 1}

  @type length_opt ::
    {:min_length, non_neg_integer} |
    {:max_length, non_neg_integer} |
    {:length, Range.t | non_neg_integer}
  @type length_opts :: [length_opt]

  @spec get_range(length_opts) :: {non_neg_integer, non_neg_integer | nil}
  defp get_range(opts) do
    with {:length, nil} <- {:length, Keyword.get(opts, :length)},
         {:min, min} <- {:min, Keyword.get(opts, :min_length, 0)},
         {:max, max} <- {:max, Keyword.get(opts, :max_length)} do
      {min, max}
    else
      {:length, min..max} -> {min, max}
      {:length, len} -> {len, len}
    end
  end

  @doc """
  """
  @spec list_of(t(a), length_opts) :: t([a]) when a: term
  def list_of(elem_dom, opts \\ []) do
    {min, max} = get_range(opts)
    %__MODULE__{
      kind: {:list, elem_dom, min, max},
      pick: &list_pick/3
    }
  end

  @spec list_pick(t([a]), size, seed) :: {t([a]), [a], seed} when a: term
  defp list_pick(%__MODULE__{kind: {:list, elem_dom, min, max}, empty_ok?: empty_ok?}, size, seed) do
    max = if is_nil(max), do: size, else: max
    min = if not empty_ok? and min == 0, do: 1, else: min
    {len, seed} = range_pick(min, max, seed)
    if len == 0 do
      {[], [], seed}
    else
      {list_dom, list, seed} =
        Enum.reduce(1..len, {[], [], seed}, fn _, {dom, t, s0} ->
          {edom, e, s1} = pick(elem_dom, size, s0)
          {[edom|dom], [e|t], s1}
        end)

      shrinkable_list(list_dom, list, len, empty_ok?, seed)
    end
  end

  @spec shrinkable_list([t(a)], [a], non_neg_integer, boolean, seed) :: {t([a]), [a], seed} when a: term
  defp shrinkable_list(list_dom, list, 1, false, seed), do: {list_dom, list, seed}
  defp shrinkable_list(_list_dom, [], 0, _empty_ok?, seed), do: {[], [], seed}
  defp shrinkable_list(list_dom, list, len, empty_ok?, seed)
    when length(list_dom) == length(list) and length(list) == len do
      shrunk_dom = %__MODULE__{
        kind: {:shrinkable_list, list_dom, len},
        shrink: &list_shrink/3,
        empty_ok?: empty_ok?
      }
      {shrunk_dom, list, seed}
  end

  @spec list_shrink(t([a]), [a], seed) :: {t([a]), [a], seed} when a: term
  defp list_shrink(%__MODULE__{kind: {:shrinkable_list, list_dom, len}, empty_ok?: empty_ok?}, list, seed)
    when length(list) == len do
      smaller_ok? = ((empty_ok? and (len > 0)) or (len > 1))
      {rnd, seed} = :rand.uniform_s(5, seed)
      if smaller_ok? and (rnd == 1) do
        shorter_list(list_dom, list, len, empty_ok?, seed)
      else
        case shrink(list_dom, list, seed) do
          {_, ^list, seed} when smaller_ok? ->
            shorter_list(list_dom, list, len, empty_ok?, seed)
          {shrunk_list_dom, shrunk_list, seed} ->
            shrinkable_list(shrunk_list_dom, shrunk_list, len, empty_ok?, seed)
        end
      end
  end

  @spec shorter_list(t([a]), [a], non_neg_integer, boolean, seed) :: {t([a]), [a], seed} when a: term
  defp shorter_list(list_dom, list, len, empty_ok?, seed) do
    {shorter_list_dom, shorter_list, shorter_len, seed} =
      case :rand.uniform_s(3, seed) do
        {1, seed} -> # remove one element
          {idx, seed} = :rand.uniform_s(len, seed)
          {List.delete_at(list_dom, idx - 1), List.delete_at(list, idx - 1), len - 1, seed}
        {2, seed} -> # remove or keep a random sublist
          {idx1, seed} = :rand.uniform_s(len, seed)
          {idx2, seed} = :rand.uniform_s(len, seed)
          if idx1 < idx2 do
            {
              without(idx1, idx2, list_dom),
              without(idx1, idx2, list),
              len - (idx2 - idx1),
              seed
            }
          else
            short_len = idx1 - idx2 + 1
            {
              :lists.sublist(list_dom, idx2, short_len),
              :lists.sublist(list, idx2, short_len),
              short_len,
              seed
            }
          end
        {3, seed} -> # remove a random sublist
          zipped = Enum.zip(list_dom, list)
          {true_threshold, seed} = :rand.uniform_s(seed)
          {false_threshold, seed} = :rand.uniform_s(seed)
          {pruned, seed} = markov_prune_list(zipped, true_threshold, false_threshold, false, seed)
          {pruned_list_dom, pruned_list} = Enum.unzip(pruned)
          {pruned_list_dom, pruned_list, length(pruned), seed}
      end
    {new_list_dom, new_list, new_len} =
      case {empty_ok?, shorter_len} do
        {false, 0} -> {list_dom, list, len}
        _ -> {shorter_list_dom, shorter_list, shorter_len}
      end
    shrinkable_list(new_list_dom, new_list, new_len, empty_ok?, seed)
  end

  @compile {:inline, without: 3}

  @spec without(list, non_neg_integer, non_neg_integer) :: list
  defp without(list, idx1, idx2) do
    {first, tail} = :lists.split(idx1 - 1, list)
    {_middle, rest} = :lists.split(idx2 - idx1, tail)
    first ++ rest
  end

  @spec markov_prune_list(list, true_threshold :: float, false_threshold :: float, previous? :: boolean, seed) :: {list, seed}
  defp markov_prune_list([], _, _, _, seed), do: {[], seed}
  defp markov_prune_list([h|t], true_threshold, false_threshold, previous?, seed) do
    with {rnd, seed} <- :rand.uniform_s(seed),
         threshold = (if previous?, do: true_threshold, else: false_threshold),
         include? = rnd > threshold,
         {new_tail, seed} <- markov_prune_list(t, true_threshold, false_threshold, include?, seed) do
      if include? do
        {[h|new_tail], seed}
      else
        {new_tail, seed}
      end
    end
  end

  @doc """
  """
  @spec non_empty(t) :: t
  def non_empty(domain) do
    %{domain | empty_ok?: false}
  end

  @doc """
  """
  @spec frequency([{pos_integer, t(a)}]) :: t(a) when a: term
  def frequency(_frequencies) do

  end

  @doc """
  """
  @spec tree(t(a), (t(a|b) -> t(b))) :: t(a|b) when a: term, b: term
  def tree(leaf_domain, subtree_fun) do
    %__MODULE__{
      kind: {:tree, leaf_domain, subtree_fun},
      pick: &tree_pick/3
    }
  end

  @spec tree_pick(t(a), size, seed) :: {t(a), a, seed} when a: term
  defp tree_pick(_dom, _size, _seed) do
  end

  @spec random_pseudofactors(integer, seed) :: {[integer], seed}
  defp random_pseudofactors(n, seed) when n < 2, do: {[n], seed}
  defp random_pseudofactors(n, seed) do
    {factor, seed} = :rand.uniform_s(trunc(:math.log2(n)), seed)
    if factor == 1 do
      {[n], seed}
    else
      {factors, seed} = random_pseudofactors(div(n, factor), seed)
      {[factor|factors], seed}
    end
  end

  # "simple" generators
  ########################

  @type integer_kind :: {:int, min :: integer, max :: integer, shrink_to :: integer}

  @doc """
  """
  @spec integer(Range.t | nil) :: t(integer())
  def integer(range \\ nil)
  def integer(nil) do
    unbounded_integer()
  end
  def integer(min..max) do
    bounded_integer(min, max)
  end

  @spec bounded_integer(integer(), integer()) :: t(integer())
  defp bounded_integer(min, max)
    when is_integer(min) and is_integer(max) and min <= max do
      shrink_to = case {min >= 0, max >= 0} do
        {true, true} -> min
        {false, true} -> 0
        {false, false} -> max
      end

      %__MODULE__{
        kind: {:int, min, max, shrink_to},
        pick: &integer_pick/3,
        shrink: &integer_shrink/3
      }
  end

  @spec integer_pick(t(integer), size, seed) :: {t(integer), integer, seed}
  defp integer_pick(%__MODULE__{kind: {:int, min, max, _}} = dom, _size, seed) do
    {i, seed} = range_pick(min, max, seed)
    {dom, (i - 1 + min), seed}
  end

  @compile {:inline, range_pick: 3, integer_shrink_by_decrement: 2, integer_shrink_by_half: 2, unbounded_integer: 0}

  @spec range_pick(min :: integer, max :: integer, seed) :: {integer, seed}
  defp range_pick(min, max, seed) when max > min do
    {i, seed} = :rand.uniform_s((max - min + 1), seed)
    {(i - 1 + min), seed}
  end
  defp range_pick(val, val, seed), do: {val, seed}
  defp range_pick(min, _max, seed),
    do: range_pick(min, min, seed)

  @spec integer_shrink(t(integer), integer, seed) :: {t(integer), integer, seed}
  defp integer_shrink(%__MODULE__{kind: {:int, _, _, value}} = dom, value, seed),
    do: {dom, value, seed}
  defp integer_shrink(%__MODULE__{kind: {:int, _, _, shrink_to}} = dom, value, seed) do
    decrement_prob = 2 * :math.exp(-0.1 * abs(value - shrink_to))
    case :rand.uniform_s(seed) do
      {rnd, seed} when rnd < decrement_prob ->
        {dom, integer_shrink_by_decrement(value, shrink_to), seed}
      {_, seed} ->
        {dom, integer_shrink_by_half(value, shrink_to), seed}
    end
  end

  @spec integer_shrink_by_decrement(integer, integer) :: integer
  defp integer_shrink_by_decrement(value, shrink_to) when value > shrink_to, do: value - 1
  defp integer_shrink_by_decrement(value, shrink_to) when value > shrink_to, do: value + 1
  defp integer_shrink_by_decrement(value, value), do: value

  @spec integer_shrink_by_half(integer, integer) :: integer
  defp integer_shrink_by_half(value, shrink_to) do
    mid = div((value - shrink_to), 2)
    shrink_to + mid
  end

  @spec unbounded_integer() :: t(integer())
  defp unbounded_integer() do
    %__MODULE__{
      kind: :int,
      pick: fn dom, size, seed ->
        {i, seed} = :rand.uniform_s(size, seed)
        {dom, (i - div(size, 2)), seed}
      end,
      shrink: fn
        dom, val, seed when val > 0 -> {dom, val - 1, seed}
        dom, val, seed when val < 0 -> {dom, val + 1, seed}
        dom, 0, seed -> {dom, 0, seed}
      end
    }
  end

  @doc """
  """
  @spec byte() :: t(byte)
  def byte(), do: integer(0..255)

  @doc """
  """
  @spec non_neg_integer() :: t(non_neg_integer)
  def non_neg_integer() do
    %__MODULE__{
      kind: :int,
    }
  end

  @doc """
  """
  @spec pos_integer() :: t(pos_integer)
  def pos_integer() do
  end

  @doc """
  """
  @spec neg_integer() :: t(neg_integer)
  def neg_integer() do
  end

  @doc """
  """
  @spec large_integer() :: t(integer)
  def large_integer() do
  end

  @type float_opt :: {:min, float} | {:max, float}
  @type float_opts :: [float_opt]

  @doc """
  """
  @spec real(float_opts) :: t(float)
  def real(opts \\ []), do: float(opts)

  @doc """
  """
  @spec float(float_opts) :: t(float)
  def float(_opts \\ []) do
  end

  @doc """
  """
  @spec boolean() :: t(boolean)
  def boolean() do
  end

  @doc """
  """
  @spec char(:all | nil) :: t(char)
  def char(kind \\ nil)
  def char(nil), do: integer(32..126)
  def char(:all), do: integer(0..0x10FFFF)

  @doc """
  """
  @spec binary(length_opts) :: t(binary)
  def binary(_opts \\ []) do
  end

  @doc """
  """
  @spec bitstring(length_opts) :: t(bitstring)
  def bitstring(_opts \\ []) do
  end

  @doc """
  """
  @spec sized((size -> t(a))) :: t(a) when a: term
  def sized(fun) do
    %__MODULE__{
      kind: {:sized, fun},
      pick: fn %__MODULE__{kind: {:sized, fun}}, size, seed ->
        pick(fun.(size), size, seed)
      end
    }
  end

  @doc """
  """
  @spec resize(t(a), size) :: t(a) when a: term
  def resize(domain, size) do
    %__MODULE__{
      kind: {:resize, domain, size},
      pick: fn %__MODULE__{kind: {:resize, dom, size}}, _size, seed ->
        pick(dom, size, seed)
      end
    }
  end

  @doc false
  @spec __reduce__(Enumerable.t, Enumerable.acc, Enumerable.reducer) :: Enumerable.result
  def __reduce__(data, acc, fun) do
    reduce(data, acc, fun, new_seed(), @initial_size, @max_size)
  end

  @spec reduce(Enumerable.t, Enumerable.acc, Enumerable.reducer, seed, size, size) :: Enumerable.result
  defp reduce(_data, {:halt, acc}, _fun, _seed, _size, _max_size) do
    {:halted, acc}
  end
  defp reduce(data, {:suspend, acc}, fun, seed, size, max_size) do
    {:suspended, acc, &reduce(data, &1, fun, seed, size, max_size)}
  end
  defp reduce(data, {:cont, acc}, fun, seed, size, max_size) do
    {_dom, next, new_seed} = pick(data, size, seed)
    reduce(data, fun.(next, acc), fun, new_seed, min(max_size, size + 1), max_size)
  end

  defimpl Enumerable do
    def reduce(enumerable, acc, fun), do: @for.__reduce__(enumerable, acc, fun)
    def count(_enumerable), do: {:error, __MODULE__}
    def member?(_enumerable, _element), do: {:error, __MODULE__}
    def slice(_enumerable), do: {:error, __MODULE__}
  end

  defimpl Inspect do
    def inspect(%Domain{kind: kind}, opts) do
      @protocol.Algebra.container_doc(
        "#Domain<",
        [kind: kind],
        ">",
        opts,
        fn {k, i}, o ->
          @protocol.Algebra.concat([
            to_string(k), "=", @protocol.inspect(i, o)
          ])
        end,
        [separator: ",", break: :flex]
      )
    end
  end
end
