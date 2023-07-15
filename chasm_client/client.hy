(require hyrule [unless])

(import json)
(import zmq [Context REQ POLLIN])

(import chasm-client.wire [wrap unwrap])


(setv REQUEST_TIMEOUT 20000) ; ms


(setv context (Context)
      socket (.socket context REQ))

(.connect socket (config "server"))


(defn rpc [payload]
  "Call a function on the server. Return None for timeout."
  (.send-string socket (wrap payload))
  (unless (& (socket.poll REQUEST_TIMEOUT) POLLIN)
    (unwrap (.recv-string socket))))

(defn send-quit [#* args #** kwargs]
  "This is a parse request but with no waiting."
  (.send-string socket (wrap {"function" "parse"
                              "args" args
                              "kwargs" kwargs})))

(defn spawn [#* args #** kwargs]
  (rpc {"function" "spawn"
        "args" args
        "kwargs" kwargs}))

(defn parse [#* args #** kwargs]
  (rpc {"function" "parse"
        "args" args
        "kwargs" kwargs}))
