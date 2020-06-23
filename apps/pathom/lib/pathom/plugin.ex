defmodule Pathom.Plugin do
  # NOTE: investigate interceptors over middleware?

  defstruct parser: nil,
            read: nil,
            mutate: nil
  @type t :: %__MODULE__{
    parser: middleware(Pathom.parser) | nil,
    read: middleware(reader) | nil,
    mutate: middleware(mutate) | nil
  }

  @type middleware(f) :: (f -> f)
  @type mutate :: (Pathom.env, map -> map)
  @type reader :: any
end
