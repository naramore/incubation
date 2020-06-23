defmodule Pathom.Resolver do
  defstruct name: nil,
            doc: nil,
            input: MapSet.new([]),
            output: [],
            params: [],
            resolve: nil,
            transform: nil,
            provides: %{}
  @type t :: %__MODULE__{
    name: name,
    doc: String.t | nil,
    input: input,
    output: output,
    params: params,
    resolve: resolve,
    transform: transform,
    provides: provides
  }

  @type name :: {module, atom} | module | atom
  @type input :: Pathom.attribute_set
  @type composed_output :: %{required(Pathom.attribute) => output}
  @type output :: [Pathom.attribute | composed_output, ...] | composed_output
  @type params :: output
  @type input_data :: %{required(Pathom.attribute) => any}
  @type output_data :: %{required(Pathom.attribute) => any}
  @type resolve :: (Pathom.env, input_data -> output_data)
  @type transform :: (resolve -> resolve)
  @type provides :: Pathom.Index.reach

  @spec new(name, resolve, keyword) :: t
  def new(name, resolve, opts \\ []) do
    struct(__MODULE__, Keyword.merge(opts, [name: name, resolve: resolve]))
  end

  # TODO: defresolver macro
  # TODO: 'typespec' + 'typedoc' for attributes
  # TODO: alias-resolver
  # TODO: alias-resolver2
  # TODO: constantly-resolver
  # TODO: single-attr-resolver
  # TODO: single-attr-resolver2

  @doc false
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :resolvers, accumulate: true)
      @before_compile Pathom.Resolver
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
    end
  end
end
