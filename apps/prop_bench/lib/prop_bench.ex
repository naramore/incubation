defmodule PropBench do
  @moduledoc false
end

defmodule PropBench.Test do
  @moduledoc false

  @callback handle_run() :: {map, keyword}

  defmacro __using__(_opts) do
    quote do
      @behaviour PropBench.Test

      @spec run() :: any()
      def run() do
        {jobs, config} = handle_run()
        Benchee.run(jobs, config)
      end
    end
  end
end

# metrics:
#   1. generation speed
#   2. shrinking speed?
#   3. shrinking size?
# generators:
#   1. scalar(s)
#   2. enumerable(s)
#   3. collectable(s)
#   4. composed
#   5. recursive tree
#   6. recursive N cycle (i.e. 1-cycle -> a[b[a[...]]])

# StreamData: *gen* |> StreamData.seeded(seed) |> StreamData.resize(size)
#             Enum.map(1..count, fn gen -> Enum.take(gen, 1) end)
#             *gen* StreamData.integer(min..max)
# PropCheck: Enum.map(1..count, fn _ -> PropCheck.produce(*gen*, size, seed) |> elem(1) end)
#             *gen* PropCheck.BasicTypes.integer(min, max)
# PropEr: Enum.map(1..count, fn _ -> :proper_gen.pick(*gen*, size, seed) |> elem(1) end)
#         *gen* :proper_types.integer(min, max)
# Triq*: Enum.map(1..count, fn _ -> :triq_dom.pick(*gen*, size) |> elem(1) end)
#         *gen* :triq_dom.int(min, max) (doesn't support :inf?)

defmodule PropBench.Tests.List.Integer do
  use PropBench.Test

  @impl PropBench.Test
  def handle_run() do
    {
      %{
        "StreamData" => fn ->
          Enum.take(StreamData.resize(StreamData.list_of(StreamData.integer(-100..100)), 10), 1000)
        end,
        "PropEr" => fn ->
          Enum.map(1..1000, fn _ -> :proper_gen.pick(:proper_types.list(:proper_types.integer(-100, 100)), 10) end)
        end,
        "Triq" => fn ->
          Enum.map(1..1000, fn _ -> :triq_dom.pick(:triq_dom.list(:triq_dom.int(-100, 100)), 10) end)
        end,
        "Domain" => fn ->
          Domain.list_of(Domain.integer(-100..100)) |> Enum.take(1000)
        end,
        "TriqData" => fn ->
          Enum.map(1..1000, fn _ -> TriqData.pick(TriqData.list_of(TriqData.integer(-100..100)), 10) end)
        end
      },
      []
    }
  end
end

defmodule PropBench.Tests.Scalar.Boolean do
  use PropBench.Test

  @impl PropBench.Test
  def handle_run() do
    {
      %{
        "StreamData" => fn -> Enum.take(StreamData.boolean(), 1) end,
        "PropEr" => fn -> :proper_gen.pick(:proper_types.boolean()) end,
        "Triq" => fn -> :triq_dom.pick(:triq_dom.bool(), 1) end
      },
      []
    }
  end
end

defmodule PropBench.Tests.Scalar.Integer do
  use PropBench.Test

  @impl PropBench.Test
  def handle_run() do
    {
      %{
        "StreamData" => fn {min, max} -> Enum.take(StreamData.integer(min..max), 1) end,
        "PropEr" => fn {min, max} -> :proper_gen.pick(:proper_types.integer(min, max)) end,
        "Triq" => fn {min, max} -> :triq_dom.pick(:triq_dom.int(min, max), max) end
      },
      [
        inputs: %{
          "xsmall" => {-10, 10},
          "small" => {-100, 100},
          "medium" => {-1000, -1000},
          "large" => {-10_000, 10_000}
        }
      ]
    }
  end
end

defmodule PropBench.Tests.Scalar.Float do
  use PropBench.Test

  @impl PropBench.Test
  def handle_run() do
    {
      %{
        "StreamData" => fn {min, max} -> Enum.take(StreamData.float(min: min, max: max), 1) end,
        "PropEr" => fn {min, max} -> :proper_gen.pick(:proper_types.float(min, max)) end,
        "Triq" => fn {min, max} -> :triq_dom.pick(:triq_dom.float(), max) end
      },
      [
        inputs: %{
          "xsmall" => {-10.0, 10.0},
          "small" => {-100.0, 100.0},
          "medium" => {-1000.0, -1000.0},
          "large" => {-10_000.0, 10_000.0}
        }
      ]
    }
  end
end

defmodule Prop do
  defmacro lazy(gen) do
    quote do
      :proper_types.lazy(fn -> unquote(gen) end)
    end
  end
end

defmodule Foo do
  def bar() do
    :proper_types.list(
      :proper_types.frequency([
        {1, :proper_types.lazy(fn -> bar() end)},
        {10, :proper_types.integer()}
      ])
    )
  end
end

defmodule PropBench.Tests.Rand do
  use PropBench.Test

  @timestamp :os.timestamp()

  @impl PropBench.Test
  def handle_run() do
    {
      %{
        ":rand.uniform/1" => fn ->
          _ = :rand.seed(:exsp, @timestamp)
          Enum.reduce(1..10_000, nil, fn _, _ ->
            _ = :rand.uniform(100)
            nil
          end)
        end,
        ":rand.uniform_s/2" => fn ->
          s0 = :rand.seed_s(:exsp, @timestamp)
          Enum.reduce(1..10_000, s0, fn _, s ->
            {_, ns} = :rand.uniform_s(100, s)
            ns
          end)
        end,
      },
      []
    }
  end
end
