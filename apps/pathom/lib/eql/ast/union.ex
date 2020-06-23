defmodule EQL.AST.Union do
  alias EQL.{AST.Union.Entry, Utils}
  require EQL.Utils

  defstruct query: nil,
            children: []
  @type t :: %__MODULE__{
    query: EQL.expr,
    children: [Entry.t]
  }

  @spec new(EQL.expr, [Entry.t]) :: t
  def new(query, children \\ []) do
    %__MODULE__{
      query: query,
      children: children
    }
  end

  @spec from_query(EQL.expr | EQL.union) :: EQL.result(t)
  def from_query(union) when Utils.is_union(union) do
    union
    |> Enum.into([])
    |> from_query_impl()
    |> case do
      {:error, reason} ->
        {:error, reason}
      {:ok, children} ->
        {:ok, new(union, children)}
    end
  end
  def from_query(expr) do
    {:error, EQL.Error.new(:invalid_expression, expr)}
  end

  @spec from_query_impl([{EQL.property, EQL.query}], [Entry.t]) :: EQL.result([Entry.t])
  defp from_query_impl(list_union, acc \\ [])
  defp from_query_impl([], acc) do
    {:ok, acc}
  end
  defp from_query_impl([{key, query} | t], acc) do
    case Entry.from_query({key, query}) do
      {:error, reason} -> {:error, reason}
      {:ok, ast} -> from_query_impl(t, [ast | acc])
    end
  end

  defimpl EQL.AST do
    def to_expr(union) do
      union.query
    end
  end

  defmodule Entry do
    defstruct key: nil,
              query: nil,
              children: []
    @type t :: %__MODULE__{
      key: EQL.property,
      query: EQL.query,
      children: [EQL.AST.t]
    }

    @spec new(EQL.property, EQL.query, [EQL.AST.t]) :: t
    def new(key, query, children \\ []) do
      %__MODULE__{
        key: key,
        query: query,
        children: children
      }
    end

    @spec from_query({EQL.property, EQL.query}) :: EQL.result(t)
    def from_query({key, query}) do
      case EQL.expr_to_ast(query) do
        {:error, reason} -> {:error, reason}
        {:ok, ast} -> {:ok, new(key, query, ast)}
      end
    end

    defimpl EQL.AST do
      def to_expr(entry) do
        entry.query
      end
    end
  end
end
