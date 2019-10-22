defmodule  GraphqlSpec.Language.Inspect.Utils do
  import Inspect.Algebra

  @spec optional_to_doc(term, Inspect.Opts.t, Keyword.t) :: Inspect.Algebra.t
  def optional_to_doc(term, opts, container_opts \\ [])
  def optional_to_doc(term, _opts, _container_opts) when term in [nil, []], do: empty()
  def optional_to_doc([h|t], opts, container_opts) do
    {fun, container_opts} = Keyword.pop(container_opts, :fun, &to_doc/2)
    {left, container_opts} = Keyword.pop(container_opts, :left, empty())
    {right, container_opts} = Keyword.pop(container_opts, :right, empty())
    {prefix, container_opts} = Keyword.pop(container_opts, :prefix)
    {suffix, container_opts} = Keyword.pop(container_opts, :suffix)
    container = container_doc(left, [h|t], right, opts, fun, Keyword.merge([break: :flex], container_opts))
    case {prefix, suffix} do
      {nil, nil} -> container
      {_, nil} -> concat([prefix, container])
      {nil, _} -> concat([container, suffix])
      _ -> concat([prefix, container, suffix])
    end
  end
  def optional_to_doc(term, opts, container_opts) do
    {prefix, container_opts} = Keyword.pop(container_opts, :prefix)
    {suffix, _} = Keyword.pop(container_opts, :suffix)
    case {prefix, suffix} do
      {nil, nil} -> to_doc(term, opts)
      {_, nil} -> concat([prefix, to_doc(term, opts)])
      {nil, _} -> concat([to_doc(term, opts), suffix])
      _ -> concat([prefix, to_doc(term, opts), suffix])
    end
  end
end
