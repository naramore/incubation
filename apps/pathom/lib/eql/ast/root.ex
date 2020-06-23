defmodule EQL.AST.Root do
  defstruct children: []
  @type t :: %__MODULE__{
    children: [EQL.AST.t]
  }

  @spec new([EQL.AST.t]) :: t
  def new(children) do
    %__MODULE__{children: children}
  end

  @spec from_query(EQL.query) :: EQL.result(t)
  def from_query(query) do
    case EQL.expr_to_ast(query) do
      {:error, reason} -> {:error, reason}
      {:ok, children} -> {:ok, new(children)}
    end
  end

  defimpl EQL.AST do
    def to_expr(root) do
      Enum.map(root.children, &@protocol.to_expr/1)
    end
  end
end
