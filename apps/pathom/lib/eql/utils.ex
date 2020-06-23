defmodule EQL.Utils do
  defguard is_property(value) when is_atom(value) or (is_tuple(value) and tuple_size(value) == 2 and is_atom(elem(value, 0)) and is_atom(elem(value, 1)))
  defguard is_ident(value) when is_property(hd(value)) and not is_list(tl(value))
  defguard is_join(value) when is_map(value) and map_size(value) == 1
  defguard is_union(value) when is_map(value) and map_size(value) > 1
end
