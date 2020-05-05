defmodule Domino do
  # NOTE: rename this (at some point?)
  # see https://github.com/domino-clj/domino
  
  # MODEL:
  #   - support streaming / partitioning?
  #   - nesting triggers and/or interceptors
  #   - ids
  #   - sequences / collections of data
  # INPUTS/OUTPUTS:
  #   - omitted / unchanged results
  #   - revisiting nodes (use interceptors? allow / disallow cycles?)
  #   - wait for multiple triggers (join?) using interceptors?
  # HANDLERS:
  #   - domino-clj args :: [ctx inputs outputs]
  #     args :: [ctx] (???)
  #   - step
  # INTERCEPTORS: use interceptor app
  # HISTORY:
  #   - graph-like history (i.e. track origin and parent of each 'event')
  # ENGINE:
  #   - deterministic/intuitive execution path w/ multiple inputs/outputs
end
