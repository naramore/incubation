defmodule Interceptor do
  # see http://pedestal.io/reference/interceptors
  # see https://lispcast.com/a-model-of-interceptors/
  # see https://github.com/exoscale/interceptor
  # see https://github.com/metosin/sieppari
  
  # 'unrecoverable' interceptors:
  # enter, leave, error
  # a -> b -> c
  # => enter a -> enter b -> enter c |-> leave c -> leave b -> leave a
  #                                  |-> error c -> error b -> error a
  #                                  |
  #                          'point of no return'
  # => enter b -> error -> leave b (i.e. short-circuit)
  # => leave b -> error -> error b -> error|leave a
  
  # error
  # halt
  # terminate
  # enqueue, inject
  # when
  # in, out, lens
  # discard
  
  # 'recoverable' interceptors (worth it?)
  # would involve leave and/or error to conditionally point back to enter?
  # does this even make sense for interceptors?
  # saga: txn -> ok
  #           -> cmp
  #       cmp -> error
  #           -> abort
  #           -> txn
  #           -> ok
end
