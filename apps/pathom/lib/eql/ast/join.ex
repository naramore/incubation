defmodule EQL.AST.Join do
  alias EQL.Utils
  require EQL.Utils

  defstruct key: nil,
            dispatch_key: nil,
            query: nil,
            children: []
  @type t :: %__MODULE__{
    key: EQL.ident_or_property,
    dispatch_key: EQL.property,
    query: EQL.expr,
    children: [EQL.AST.t]
  }

  @spec new(EQL.ident_or_property, EQL.property, EQL.expr, [EQL.AST.t]) :: t
  def new(key, dispatch_key, query \\ nil, children \\ []) do
    %__MODULE__{
      key: key,
      dispatch_key: dispatch_key,
      query: query,
      children: children
    }
  end

  @spec from_query(EQL.expr) :: EQL.result(t)
  def from_query(%{} = join) when map_size(join) == 1 do
    [{k, v}] = Enum.into(join, [])
    case extract_join_key(k) do
      {:error, reason} -> {:error, reason}
      {:ok, join} ->
        add_children(join, v)
    end
  end
  def from_query(expr) do
    {:error, EQL.Error.new(:invalid_expression, expr)}
  end

  @spec extract_join_key(EQL.expr) :: EQL.result(t)
  defp extract_join_key([prop | _] = ident) when Utils.is_ident(ident) do
    {:ok, new(ident, prop)}
  end
  defp extract_join_key(prop) when Utils.is_property(prop) do
    {:ok, new(prop, prop)}
  end
  defp extract_join_key(expr) do
    {:error, EQL.Error.new(:invalid_expression, expr)}
  end

  @spec add_children(t, EQL.expr) :: EQL.result(t)
  defp add_children(join, query) do
    case EQL.expr_to_ast(query) do
      {:error, reason} -> {:error, reason}
      {:ok, ast} when is_list(ast) ->
        {:ok, %{join | query: query, children: ast}}
      {:ok, ast} ->
        {:ok, %{join | query: query, children: [ast]}}
    end
  end

  defimpl EQL.AST do
    def to_expr(join) do
      %{join.key => join.query}
    end
  end
end
