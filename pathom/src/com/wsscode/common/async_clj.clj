(ns com.wsscode.common.async-clj
  "DEPRECATED: please use com.wsscode.async.async-clj instead"
  (:require
    [clojure.core.async :as async]
    [clojure.core.async.impl.protocols :as async.prot]))

(defmacro if-cljs
  [then else]
  (if (:ns &env) then else))

(defn chan? [c]
  (satisfies? async.prot/ReadPort c))

(defmacro go-catch [& body]
  `(async/go
     (try
       ~@body
       (catch Throwable e# e#))))

(defn error? [err]
  (instance? Throwable err))

(defn throw-err [x]
  (if (error? x)
    (throw x)
    x))

(defmacro <? [ch]
  `(throw-err (async/<! ~ch)))

(defmacro <?maybe [x]
  `(let [res# ~x]
     (if (chan? res#) (<? res#) res#)))

(defmacro <!maybe [x]
  `(let [res# ~x]
     (if (chan? res#) (async/<! res#) res#)))

(defmacro <!!maybe [x]
  `(let [res# ~x]
     (if (chan? res#) (async/<!! res#) res#)))

(defmacro let-chan
  "Handles a possible channel on value."
  [[name value] & body]
  `(let [res# ~value]
     (if (chan? res#)
       (go-catch
         (let [~name (<? res#)]
           ~@body))
       (let [~name res#]
         ~@body))))

(defmacro let-chan*
  "Like let-chan, but async errors will be returned instead of propagated"
  [[name value] & body]
  `(let [res# ~value]
     (if (chan? res#)
       (go-catch
         (let [~name (async/<! res#)]
           ~@body))
       (let [~name res#]
         ~@body))))

(defmacro go-promise [& body]
  `(let [ch# (async/promise-chan)]
     (async/go
       (let [res# (try
                    ~@body
                    (catch Throwable e# e#))]
         (async/put! ch# res#)))
     ch#))
