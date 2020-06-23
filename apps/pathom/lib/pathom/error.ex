defmodule Pathom.Error do
  defexception [:type, :error]
  @type t :: %__MODULE__{
    type: atom,
    error: any
  }

  @impl Exception
  def message(%__MODULE__{error: %{__exception__: true} = e}) do
    Exception.message(e)
  end
  def message(%__MODULE__{error: e}) do
    "#{inspect(e)}"
  end

  @spec new(atom, any) :: t
  def new(type, error) do
    %__MODULE__{
      type: type,
      error: error
    }
  end
end
