defmodule EQL.AST.Params do
  defstruct child: nil,
            params: nil
  @type t :: %__MODULE__{
    child: EQL.expr,
    params: EQL.params
  }

  @spec new(EQL.params, EQL.AST.t) :: t
  def new(params, child) do
    %__MODULE__{
      params: params,
      child: child
    }
  end

  @spec from_query({EQL.expr, EQL.params}) :: EQL.result(t)
  def from_query({expr, %{} = params}) do
    case EQL.expr_to_ast(expr) do
      {:error, reason} -> {:error, reason}
      {:ok, child} -> {:ok, new(params, child)}
    end
  end

  defimpl EQL.AST do
    def to_expr(params) do
      {@protocol.to_expr(params.child), params.params}
    end
  end
end
