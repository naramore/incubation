defmodule ExSpec.ConformError do
  @moduledoc """
  """

  alias ExSpec.Conformable

  defexception [
    problems: [],
    spec: nil,
    value: nil
  ]
  @type t :: %__MODULE__{
    problems: [Problem.t],
    spec: Conformable.t,
    value: term
  }

  @impl Exception
  def message(%__MODULE__{} = error) do
    Enum.map(error.problems, fn p ->
      __MODULE__.Problem.message(p)
    end)
    |> Enum.join("\n")
  end

  @doc false
  @spec new([Problem.t], Conformable.t, term) :: t
  def new(problems, spec, value) do
    %__MODULE__{
      problems: problems,
      spec: spec,
      value: value
    }
  end

  @doc false
  defdelegate new_problem(predicate, spec_path, via, value_path, value, reason \\ nil),
    to: __MODULE__.Problem, as: :new

  @spec add_problems({:ok, term} | {:error, [Problem.t]}, [Problem.t], boolean) :: {:ok, term} | {:error, [Problem.t]}
  def add_problems(conform_response, problems, add_to_front? \\ false)
  def add_problems(response, [], _add_to_front?),
    do: response
  def add_problems({:ok, _conformed}, [_|_] = problems, _add_to_front?),
    do: {:error, problems}
  def add_problems({:error, problems}, [_|_] = more_problems, true),
    do: {:error, more_problems ++ problems}
  def add_problems({:error, problems}, [_|_] = more_problems, false),
    do: {:error, problems ++ more_problems}

  defimpl Inspect do
    @moduledoc false

    import Inspect.Algebra

    def inspect(e, opts) do
      coll = [
        {:prob, e.problems},
        {:spec, e.spec},
        {:val, e.value}
      ]
      fun = fn {k, i}, os -> concat([to_string(k), "=", @protocol.inspect(i, os)]) end
      container_doc("#ConformError<", coll, ">", opts, fun, breaK: :strict, separator: ",")
    end
  end

  defmodule Problem do
    @moduledoc """
    """

    defstruct [
      predicate: nil,
      spec_path: [],
      via: [],
      value_path: [],
      value: nil,
      reason: nil
    ]
    @type t :: %__MODULE__{
      predicate: ExSpec.t,
      spec_path: [atom],
      via: [{module, atom}],
      value_path: [term],
      value: term,
      reason: String.t | nil
    }

    @doc false
    @spec new(ExSpec.t, [atom], [module], [term], term, String.t | nil) :: t
    def new(predicate, spec_path, via, value_path, value, reason \\ nil) do
      %__MODULE__{
        predicate: predicate,
        spec_path: spec_path,
        via: via,
        value_path: value_path,
        value: value,
        reason: reason
      }
    end

    @doc false
    @spec message(t) :: String.t
    def message(p) do
      if p.value_path == [], do: "", else: "in: #{p.value_path}"
      |> (&"#{&1} value: #{p.value} fails").()
      |> (&(if p.via == [], do: &1, else: "#{&1} spec: #{List.last(p.via)}")).()
      |> (&(if p.spec_path == [], do: &1, else: "#{&1} at: #{p.spec_path}")).()
      |> (&"#{&1} predicate: #{p.predicate}").()
      |> (&(if is_nil(p.reason), do: &1, else: "#{&1} reason: #{p.reason}")).()
    end

    defimpl Inspect do
      @moduledoc false

      import Inspect.Algebra

      def inspect(problem, opts) do
        coll = [
          {:pred, problem.predicate},
          {:spath, problem.spec_path},
          {:via, problem.via},
          {:vpath, problem.value_path},
          {:value, problem.value},
          {:reason, problem.reason},
        ]
        fun = fn {k, p}, os -> concat([to_string(k), "=", @protocol.inspect(p, os)]) end
        container_doc("#Problem<", coll, ">", opts, fun, break: :flex, separator: ",")
      end
    end
  end
end
