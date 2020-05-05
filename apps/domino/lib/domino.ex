defmodule Domino do
  # NOTE: rename this (at some point?)
  # see https://github.com/domino-clj/domino
  
  # NOTE: I LIKE the name domino, but what do we call a single
  #       schema? domino (singular)? that is less 'intuitive'
  # NOTE: rename schema? (i.e. the collection of model, events, effects, etc.)
  
  # nested schemas, multi-schemas
  
  # MODEL:
  #   - support streaming / partitioning?
  #   - nesting triggers and/or interceptors
  #   - default root trigger (w/ id=root)
  #   - root interceptors
  #   - ids
  #   - enumerable: element_id?
  #   - collection: key=id
  #   - external / remote?
  #   - nested 'schema'
  # INPUTS/OUTPUTS:
  #   - omitted / unchanged results
  #   - revisiting nodes (use interceptors? allow / disallow cycles?)
  #   - wait for multiple triggers (join?) using interceptors?
  # HANDLERS:
  #   - interceptors attached to handlers
  #   - domino-clj args :: [ctx inputs outputs]
  #     args :: [ctx] (???)
  #   - step
  #   - error handling?
  #   - events vs effects (i.e. side-effects)
  # HISTORY:
  #   - graph-like history (i.e. track origin and parent of each 'event')
  #   - linear (execution order) history
  # ENGINE:
  #   - deterministic/intuitive execution path w/ multiple inputs/outputs
  #   - multiple outputs present an 'ordering' problem (i.e. which to execute 1st?)
  #   - multiple inputs present a 'waiting' problem (i.e. should we wait for potential changes, or re-execute on each/first input change)
  #   - engine protocol / behaviour? + depth-first, breadth-first, async engines
end
