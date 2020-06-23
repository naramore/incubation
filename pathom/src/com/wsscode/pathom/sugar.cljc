(ns com.wsscode.pathom.sugar
  "This namespace contains easy ways to setup common configurations for Pathom parsers"
  (:require
    [clojure.spec.alpha :as s]
    [com.fulcrologic.guardrails.core :refer [>def >defn >fdef => | <- ?]]
    [com.wsscode.pathom.connect :as pc]
    [com.wsscode.pathom.connect.foreign :as pcf]
    [com.wsscode.pathom.core :as p]))

(>def ::connect-reader "Connect reader to be used" fn?)

(>def ::plugins
  "Fn that takes plugin vector and return a modified version to be used as the plugins for the parser"
  fn?)

(>def ::foreign-parsers
  "Collection of parsers to be injected as foreign parsers."
  (s/coll-of fn?))

(defn connect-serial-parser
  "Create a standard connect parser using the serial parser.

  This parser recommended for handling small and simple queries, like
  resolvers to process missing configuration options."
  ([register] (connect-serial-parser {} register))
  ([{::keys [connect-reader foreign-parsers plugins]} register]
   (p/parser
     {::p/env     {::p/reader               [p/map-reader
                                             (or connect-reader pc/reader2)
                                             pc/open-ident-reader
                                             p/env-placeholder-reader]
                   ::p/placeholder-prefixes #{">"}}
      ::p/mutate  pc/mutate
      ::p/plugins (cond-> [(pc/connect-plugin {::pc/register register})
                           (if foreign-parsers
                             (pcf/foreign-parser-plugin {::pcf/parsers foreign-parsers})
                             {})
                           p/error-handler-plugin
                           p/trace-plugin]
                    plugins plugins)})))

(defn connect-async-parser
  "Create a standard connect parser using the async parser.

  Just like the serial parser, but supports waiting for core.async channels
  in responses. The most common usage of this one is in ClojureScript land, where
  most of the IO needs to be async."
  ([register] (connect-async-parser {} register))
  ([{::keys [connect-reader foreign-parsers plugins]} register]
   (p/async-parser
     {::p/env     {::p/reader               [p/map-reader
                                             (or connect-reader pc/async-reader2)
                                             pc/open-ident-reader
                                             p/env-placeholder-reader]
                   ::p/placeholder-prefixes #{">"}}
      ::p/mutate  pc/mutate-async
      ::p/plugins (cond-> [(pc/connect-plugin {::pc/register register})
                           (if foreign-parsers
                             (pcf/foreign-parser-plugin {::pcf/parsers foreign-parsers})
                             {})
                           p/error-handler-plugin
                           p/trace-plugin]
                    plugins plugins)})))

(defn connect-parallel-parser
  "Create a standard connect parser using the parallel parser.

  This is recommended if you have a lot of different information sources that
  are IO bound. This parser can handle things in parallel, but adds extra overhead
  to processing, use it in case your system has good parallelism opportunities."
  ([register] (connect-parallel-parser {} register))
  ([{::keys [connect-reader]} register]
   (p/parallel-parser
     {::p/env     {::p/reader               [p/map-reader
                                             (or connect-reader pc/parallel-reader)
                                             pc/open-ident-reader
                                             p/env-placeholder-reader]
                   ::p/placeholder-prefixes #{">"}}
      ::p/mutate  pc/mutate-async
      ::p/plugins [(pc/connect-plugin {::pc/register register})
                   p/error-handler-plugin
                   p/trace-plugin]})))

(defn context-parser
  "Transforms the signature of a regular parser to one that takes
  some initial context to run the query. This returns a fn with
  the following arities:

  [context query] => runs query using context as initial data.
  [env context query] => same as before but accepts initial environment."
  [parser]
  (fn context-parser-internal
    ([context query]
     (parser {::p/entity (atom context)} query))
    ([env context query]
     (parser (assoc env ::p/entity (atom context)) query))))
