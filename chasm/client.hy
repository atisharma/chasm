"
ZMQ REQ-ROUTER connection.
"

(require hyrule [unless])

(import zmq)

(import chasm.lib [config])
(import chasm.wire [wrap unwrap zerror])

;; TODO: DEALER socket, async, watch for updates

(setv REQUEST_TIMEOUT 180 ; seconds
      context (zmq.Context))

(defn start-socket []
  (setv socket (.socket context zmq.REQ))
  ; see https://stackoverflow.com/questions/26915347/zeromq-reset-req-rep-socket-state
  (.setsockopt socket zmq.RCVTIMEO (* REQUEST_TIMEOUT 1000))
  (.setsockopt socket zmq.REQ_CORRELATE 1)
  (.setsockopt socket zmq.REQ_RELAXED 1)
  (.setsockopt socket zmq.LINGER 1000)
  (.connect socket (config "server"))
  socket)

(setv socket (start-socket))

(defn rpc [payload]
  "Call a method on the server. Return None for timeout."
  (try
    (.send socket (wrap payload))
    (:payload (unwrap (.recv socket)))
    (except [zmq.Again]
      (zerror "TIMEOUT" "Request timed out."))))

(defn send-quit [#* args #** kwargs]
  "This is a parse request but with no waiting for the reply."
  (.send socket (wrap {"method" "parse"
                       "args" args
                       "kwargs" kwargs})))

(defn spawn [#* args #** kwargs]
  (rpc {"method" "spawn"
        "args" args
        "kwargs" kwargs}))

(defn parse [#* args #** kwargs]
  (rpc {"method" "parse"
        "args" args
        "kwargs" kwargs}))

(defn motd [#* args #** kwargs]
  (rpc {"method" "motd"
        "args" args
        "kwargs" kwargs}))

(defn status [#* args #** kwargs]
  (rpc {"method" "status"
        "args" args
        "kwargs" kwargs}))
