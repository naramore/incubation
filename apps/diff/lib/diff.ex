defmodule Diff do
  # lists -> List.myers_difference(list1, list2, &List.myers_difference/2)
  # strings -> String.myers_difference/2
  # maps -> ...
  # tuples -> Tuple.to_list() |> list_diff() |> List.to_tuple()
  # keyword -> lists + tuples?
  # MapSet -> MapSet.difference/2 x2 -> :ins & :del + MapSet.intersection/2 -> :eq
  # otherwise -> atomic
  
  @type script :: [{:ins | :eq | :del, list} | {:diff, script}]
  # script + a -> b
  # script + b -> a
  # diff ~ {only-a, only-b, both}
end
