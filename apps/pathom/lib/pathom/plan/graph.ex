defmodule Pathom.Plan.Graph do
  defstruct nodes: %{}
  @type t :: %__MODULE__{
    nodes: %{optional(node_id) => any}
  }

  @type node_id :: any
end
