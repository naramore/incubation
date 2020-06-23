defmodule EQL.Error do
  defexception [:expr, :type]
  @type t :: %__MODULE__{
    expr: EQL.expr,
    type: atom
  }

  @impl Exception
  def message(%__MODULE__{expr: expr, type: type}) do
    "#{type}: #{inspect(expr)}"
  end

  @spec new(atom, EQL.expr) :: t
  def new(type, expr) do
    %__MODULE__{
      type: type,
      expr: expr
    }
  end
end
