defmodule Pathom do
  alias Pathom.Error

  @type result(x) :: EQL.result(x, Error.t)
  @type attribute :: EQL.property
  @type attribute_set :: MapSet.t(attribute)
  @type env :: map
  @type parser :: (env, EQL.query -> result(map))
  @type resolve :: (env, map -> map)
  @type mutate :: (env, map -> map)

  # TODO: EDN
  # TODO: Pathom.Plug
  # TODO: Pathom.Phoenix
  # TODO: Pathom.Playground (LiveView)
  # TODO: Pathom.Federation
  # TODO: Pathom.Diplomat.{HTTP, GraphQL, RPC, ...}

  # TODO: parser(env, tx) :: {:ok, map} | {:error, Error.t}
  # TODO: readers -> reader, async-reader, parallel-reader
  #               -> ident-reader, index-reader, open-ident-reader,
  #               -> map-reader, env-placeholder-reader

  # core engine:
  #   query notation
  #   parsers
  #   readers
  #   entities
  #   plugins
  #     error handling
  #     request caching
  #     placeholders
  #     tracing

  # NOTE: plugins [middleware] -> parser, read, resolve, mutate, ...; interceptors? more 'points'?
  # NOTE: not fond of the async-reader + async-parser dichotomy, combine parser & reader?
  # NOTE: focus on reader3 + planner (i.e. construct plan graph -> execute graph)
  # NOTE: tracing should support :telemetry
  # TODO: reader protocol? map, function/1, list?
  # TODO: understand pathom.planner run-graph + how it is constructed + how it is executed

  # compile-time flow:
  #   resolvers + env
  #   |> compile_index
  # runtime flow:
  #   query
  #   |> parser           (eql -> ast)
  #   |> planner          (index + ast -> run_graph)
  #   |> execute          (Task.Supervisor.async_stream_nolink/6 + run_graph )
  #   |> compile_result
end
