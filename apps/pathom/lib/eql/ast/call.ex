defmodule EQL.AST.Call do
  defstruct mod: nil,
            fun: nil,
            args: []
  @type t :: %__MODULE__{
    mod: module,
    fun: atom,
    args: [any]
  }

  @spec new(module, atom, [any]) :: t
  def new(mod, fun, args \\ []) do
    %__MODULE__{
      mod: mod,
      fun: fun,
      args: args
    }
  end

  @spec from_query({module, atom, [any]}) :: EQL.result(t)
  def from_query({mod, fun, args}) do
    {:ok, new(mod, fun, args)}
  end
  def from_query(expr) do
    {:error, EQL.Error.new(:invalid_expression, expr)}
  end

  defimpl EQL.AST do
    def to_expr(call) do
      {call.mod, call.fun, call.params}
    end
  end
end
