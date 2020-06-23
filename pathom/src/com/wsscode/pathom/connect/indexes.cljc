(ns com.wsscode.pathom.connect.indexes
  (:require
    [clojure.spec.alpha :as s]
    [com.fulcrologic.guardrails.core :refer [>def >defn >fdef => | <- ?]]
    [com.wsscode.pathom.core :as p]))

(>def :com.wsscode.pathom.connect/sym symbol?)
(>def :com.wsscode.pathom.connect/attribute ::p/attribute)
(>def :com.wsscode.pathom.connect/attributes-set (s/coll-of ::p/attribute :kind set?))
(>def :com.wsscode.pathom.connect/io-map (s/map-of :com.wsscode.pathom.connect/attribute :com.wsscode.pathom.connect/io-map))

(declare normalize-io)

(defn resolver-data
  "Get resolver map information in env from the resolver sym."
  [env-or-indexes sym]
  (let [idx (cond-> env-or-indexes
              (contains? env-or-indexes :com.wsscode.pathom.connect/indexes)
              :com.wsscode.pathom.connect/indexes)]
    (get-in idx [:com.wsscode.pathom.connect/index-resolvers sym])))

(defn resolver-provides
  [{:com.wsscode.pathom.connect/keys [provides output]}]
  (or provides
      (if output (normalize-io output))))

; region io map

(defn merge-io-attrs [a b]
  (cond
    (and (map? a) (map? b))
    (merge-with merge-io-attrs a b)

    (map? a) a
    (map? b) b

    :else b))

(>defn normalize-io
  "Convert pathom output format into io/provides format."
  [output]
  [:com.wsscode.pathom.connect/output
   => :com.wsscode.pathom.connect/io-map]
  (if (map? output) ; union
    (let [unions (into {} (map (fn [[k v]]
                                 [k (normalize-io v)]))
                       output)
          merged (reduce merge-io-attrs (vals unions))]
      (assoc merged :com.wsscode.pathom.connect/unions unions))
    (into {} (map (fn [x] (if (map? x)
                            (let [[k v] (first x)]
                              [k (normalize-io v)])
                            [x {}])))
          output)))

(defn merge-io
  "Merge ::p/shape-descriptor maps."
  ([] {})
  ([a] a)
  ([a b]
   (merge-with merge-io-attrs a b)))

(defn io->query
  "Converts IO format to query format."
  [io]
  (into []
        (map (fn [[k v]]
               (if (seq v)
                 {k (io->query v)}
                 k)))
        io))

(defn merge-oir
  "Merge ::index-oir maps."
  [a b]
  (merge-with #(merge-with into % %2) a b))

(>defn sub-select-io
  "Given io-map, filters the parts of it that are also contained in mask."
  [io-map mask]
  [:com.wsscode.pathom.connect/io-map :com.wsscode.pathom.connect/io-map
   => :com.wsscode.pathom.connect/io-map]
  (reduce-kv
    (fn [m k v]
      (if (contains? io-map k)
        (assoc m k (if (seq v) (sub-select-io (get io-map k) v) v))
        m))
    {}
    mask))

(>defn sub-select-ast
  "Given an ast and a io-map mask, returns the parts of AST that match the mask."
  [{:keys [children] :as ast} mask]
  [:edn-query-language.ast/node :com.wsscode.pathom.connect/io-map
   => :edn-query-language.ast/node]
  (if (seq children)
    (reduce
      (fn [ast {:keys [key] :as node}]
        (if-let [sub (get mask key)]
          (update ast :children conj
            (if (:children node)
              (if (seq sub)
                (sub-select-ast node sub)
                (-> node (assoc :type :prop) (dissoc :children)))
              node))
          ast))
      (assoc ast :children [])
      children)
    ast))

; endregion

