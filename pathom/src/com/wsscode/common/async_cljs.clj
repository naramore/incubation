(ns com.wsscode.common.async-cljs
  "DEPRECATED: please use com.wsscode.async.async-cljs instead"
  (:require
    [cljs.core.async :as async]))

(defmacro if-cljs
  [then else]
  (if (:ns &env) then else))

(defmacro go-catch [& body]
  `(async/go
     (try
       ~@body
       (catch :default e# e#))))

(defmacro <!p [promise]
  `(consumer-pair (cljs.core.async/<! (promise->chan ~promise))))

(defmacro <? [ch]
  `(throw-err (cljs.core.async/<! ~ch)))

(defmacro <?maybe
  "Tries to await for a value, first if checks if x is a channel, if so will read
  on it; then it checks if it's a JS promise, if so will convert it to a channel
  and read from it. Otherwise returns x as is."
  [x]
  `(let [res# ~x]
     (cond
       (chan? res#)
       (<? res#)

       (promise? res#)
       (<!p res#)

       :else
       res#)))

(defmacro <!maybe [x]
  `(let [res# ~x]
     (if (chan? res#) (cljs.core.async/<! res#) res#)))

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
         (let [~name (cljs.core.async/<! res#)]
           ~@body))
       (let [~name res#]
         ~@body))))

(defmacro go-promise [& body]
  `(let [ch# (cljs.core.async/promise-chan)]
     (async/go
       (let [res# (try
                    ~@body
                    (catch :default e# e#))]
         (cljs.core.async/put! ch# res#)))
     ch#))
