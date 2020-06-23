defmodule EQL.AST.Property do
  alias EQL.Utils
  require EQL.Utils

  defstruct key: nil,
            dispatch_key: nil
  @type t :: %__MODULE__{
    key: EQL.ident_or_property,
    dispatch_key: EQL.property
  }

  @spec new(EQL.ident_or_property, EQL.property) :: t
  def new(key, dispatch_key) do
    %__MODULE__{
      key: key,
      dispatch_key: dispatch_key
    }
  end

  @spec from_query(EQL.expr) :: EQL.result(t)
  def from_query([prop | _] = ident) when Utils.is_ident(ident) do
    {:ok, new(ident, prop)}
  end
  def from_query(prop) when Utils.is_property(prop) do
    {:ok, new(prop, prop)}
  end
  def from_query(expr) do
    {:error, EQL.Error.new(:invalid_expression, expr)}
  end

  defimpl EQL.AST do
    def to_expr(prop) do
      prop.key
    end
  end
end
