# Incubation

Personal Elixir incubation monorepo.

## Overview

```
apps/
|  dataloader/              # re-implement absinthe/dataloader?
|  datalog/                 # datomic query + transaction + schema + metaschema?
|  graphql_experimental/    # e.g. @defer, @export, @stream, @live
|  graphql_extensions/      # e.g. tracing, query planner, complexity analysis
|  graphql_federation/      # implement apollo federation / gateway
|  graphql_phoenix/         # graphql plug integration w/ phoenix
|  graphql_plug/            # graphql spec as a plug
|  graphql_spec/            # implement graphql spec in Elixir
|  logic/                   # e.g. clojure.logic
|  mutant/                  # mutation testing for ExUnit
|  prop_bench/              # benchmark b/t StreamData, PropCheck, PropEr, ExCheck, Quixir
|  rand_scheduler/          # re-implement PULSE / Concuerror + auto-instrumentation (compiler?)
|  ex_spec/                    # e.g. clojure.spec
|  test_check/              # re-implement StreamData/PropEr/QuickCheck?
```

## Priorites

0. Github Actions:
  - `mix compile --warnings-as-errors`
  - `mix format --check-formatted`
  - `mix xref unreachable --abort-if-any --include-siblings`
  - `mix xref deprecated --abort-if-any --include-siblings`
  - `mix credo --strict`
  - `mix dialyzer --halt-exit-status`
  - `mix test --trace --stale`
1. Spec/Contract (e.g. clojure.spec)
2. Property-Based Testing
  - StreamData.Utilties (more generators, e.g. DateTime, function, lazy)
  - StreamData.Measurement (aggregate/3, classify/3, collect/3, measure/3, etc.)
  - StreamData.Fsm
  - StreamData.Statem
  - StreamData.Targeted + SimulatedAnnealing
  - StreamData.Symbolic
  - StreamData.TypeServer
  - StreamData.Component
  - StreamData.Cluster
  - StreamData.DynamicCluster
  - StreamData.Grammar (i.e. yecc)
  - StreamData.Load
  - StreamData.Mock
  - StreamData.Fixed
  - StreamData.Concurrency (i.e. PULSE / Concuerror integration or emulation)
3. GraphQL (Highstorm?)
  - GraphQL Spec (parse/1, validate/2, execute/5)
  - Plug
  - Phoenix
  - Federation
  - Dataloader
  - Experimental (e.g. @defer, @export, @stream, @live)
  - Extensions
    - Apollo Tracing
    - Apollo Gateway Query Planner
    - Complexity Analysis
4. Datomic
  - Logic
  - Query Reference
  - Schema Reference
  - Transaction Reference
  - Interface(s) for Storage
5. Mutation Testing

### Highstorm Details

- [ ] [GraphQL Spec](https://graphql.github.io/graphql-spec/draft/#)
  - [ ] Language & Type System (i.e. parser/interpreter)
    - [ ] refactor all encoders to conform to {:ok, _} | {:error, _} format
    - [ ] refactor list + optional encoding -> DRY
    - [ ] add NimbleParsec labels for better errors
    - [ ] add %GraphqlSpec.DecodingError{}
    - [ ] add byte_offset -> column number coversion for better errors
    - [ ] add benchmarking for compilation time and parsing speed (so as to better evaluate the trade-offs)
    - [ ] add a check for `./_build/*env*/lib/*project*/ebin/Elixir.GraphqlSpec.Interpreter.beam` filesize
    - [ ] StreamData generators for GraphQL documents
      - [ ] define `GraphqlSpec.Encoder`
      - [ ] implement it for all documents
    - [ ] add a macro for the interpreter to switch b/t parsec(:__*name*__) and *name* (easier control over compilation vs parsing speed)
    - [ ] property-based tests for various document(s) parsing
    - [ ] doctests mirroring example tests in spec
    - [ ] typespecs + typedocs for all interpreter combinators + parsecs
    - [ ] use `NimbleParsec.defparsecp` or `NimbleParsec.defcombinatorp` on non-`__document__` parsecs
    - [ ] reorganize parser definitions to be more readable?
    - [ ] @include, @skip, @deprecated support
  - [ ] Introspection
    - [ ] add validation for reserved names (e.g. beginning with '__')
    - [ ] add root queries:
      - [ ] __schema: __Schema!
      - [ ] __type(name: String!): __Type
    - [ ] add [types](https://graphql.github.io/graphql-spec/draft/#sec-Schema-Introspection):
      - [ ] __Schema
      - [ ] __Type
      - [ ] __Field
      - [ ] __InputValue
      - [ ] __EnumValue
      - [ ] __TypeKind
      - [ ] __Directive
      - [ ] __DirectiveLocation
    - [ ] implement resolvers for all [queries and types](https://graphql.github.io/graphql-spec/draft/#sec-The-__Type-Type)
    - [ ] add descriptions for all introspection types
  - [ ] [Validation](https://graphql.github.io/graphql-spec/draft/#sec-Validation)
    - [ ] define validation protocol
    - [ ] `%GraphqlSpec.ValidationError{}`
    - [ ] implement protocol for all `GraphqlSpec.Language.*`
  - [ ] [Execution](https://graphql.github.io/graphql-spec/draft/#sec-Execution)
    - [ ] schema -> operation -> type -> resolver mapping
    - [ ] variable / argument coercion
    - [ ] execute_query
    - [ ] execute_mutation
    - [ ] execute_subscription
      - [ ] source stream
      - [ ] response stream
      - [ ] unsubscribe
    - [ ] execute_selection_set
      - [ ] parallel vs serial execution
      - [ ] field collection
    - [ ] execute_field
      - [ ] value resolution
      - [ ] value completion
      - [ ] errors
  - [ ] [Response](https://graphql.github.io/graphql-spec/draft/#sec-Response)
    - [ ] define response struct
    - [ ] define serializer behaviour and/or protocol
    - [ ] implemnt for JSON via [jason](https://github.com/michalmuskala/jason)

- [ ] [Apollo Federation Spec](https://www.apollographql.com/docs/apollo-server/federation/federation-spec/#schema-modifications-glossary)

- [ ] [@defer, @export, @stream, @live support](https://github.com/apollographql/apollo-server/pull/1287/files#diff-d6763c33086f6f84305d78da9c9e2a63R70)

- [ ] `Highstorm.Plug`
  - [ ] graphql request plug
  - [ ] context (argument & static)
  - [ ] middleware support (e.g. request -> receive -> validate -> execute -> respond)
    - [ ] middleware behaviour
    - [ ] extension behaviour
    - [ ] document adapter (e.g. snake_case <--> camelCase)
    - [ ] subscription filters
  - [ ] response support
    - [ ] synchronous HTTP
    - [ ] multi-part HTTP
    - [ ] websocket or asynchronous HTTP?

- [ ] Extensions
  - [ ] [Apollo Tracing Extension](https://github.com/apollographql/apollo-tracing#response-format)
  - [ ] [Apollo Gateway Query Planner Extension](https://github.com/apollographql/apollo-server/blob/master/packages/apollo-gateway/src/QueryPlan.ts)
  - [ ] Telemetry Extension / Integration
  - [ ] Complexity Analysis Extension (e.g. https://hexdocs.pm/absinthe/complexity-analysis.html#content)
    - [ ] 'malicious query security' extension instead? (see https://blog.apollographql.com/securing-your-graphql-api-from-malicious-queries-16130a324a6b)

- [ ] `Highstorm.Phoenix`
  - [ ] mix template
  - [ ] gateway support (e.g. https://github.com/apollographql/apollo-server/tree/master/packages/apollo-gateway)

- [ ] `Highstorm.Dataloader`
  - [ ] dataloader + ecto + windows (e.g. https://github.com/absinthe-graphql/dataloader)
  - [ ] caching behaviour?


### Testing Utilities Details

- stream_data extensions / additions:
  - function generator(s)
  - integration with concuerror
    - Concuerror vs PULSE: different roles or similar enough to not matter?
  - test containers (i.e. https://www.testcontainers.org/)
  - [PropEr](https://proper-testing.github.io/):
    - look for other generator(s) and utility function(s)
    - measurement and stats:
      - aggregate/3, classify/3, collect/3, measure/3, etc.
    - fsm
    - statem
    - targeted property-based testing
      - simulated annealing
    - symbolic datatypes?
    - typeserver?
    - specs?
  - [QuickCheck](http://quviq.com/documentation/eqc/index.html):
    - look for other generator(s) and utility function(s)
    - component
    - cluster
    - dynamic cluster
    - grammar (i.e. yecc)
    - group_commands
    - load (integration w/ tsung? or amoc?)
    - mocking
    - parallelize (necessary?)
    - fixed test suites (possible?)
    - symbolic calls
    - temporal
    - PULSE
  - [clojure.spec](https://clojure.org/guides/spec)
    - new protocol that StreamData (StreamData.Spec maybe?) will implement:
      - @spec conform(t, any) :: {:ok, destructured} | {:error, :invalid}
      - @spec describe(t) :: form_data
      - @spec explain(t, any) :: :ok | {:error, reason :: term}
      - @spec form(t) :: form_data
      - @spec unform(t, destructured) :: {:ok, any} | {:error, reason :: term}
    - utility functions...
    - ability to link to func / spec / type / callback?
    - runtime checks? (no idea how to even start with this...)
    - parse spec / type / callback -> generator?
- mutation testing
  - identify mutators
  - identify mutation candidates
  - generate mutant test plan (i.e. all the mutants to be tested)
      - serial vs parallel
      - 1st-order vs higher-order mutants
  - create mutants
      - modification level
      - elixir AST
      - fully macro-expanded elixir AST
      - core erlang
      - bytecode
      - modification method
      - original 'code' -> mutator -> new 'code' + recompile
      - mutant schemata (i.e. case statements + mutant flag(s))
  - identify tests that must be run for a given set of mutations (i.e. a mutant)
  - run the aforementioned tests up to the 1st failure for each mutant
      - serial vs parallel
  - test coverage + mutant coverage -> mutation score (e.g. infection)
  - mutation test reporting (e.g. Stryker)
  - mutant benchmarking / efficacy score?
  - identify / eliminate equivalent mutations?
  - dogfood

