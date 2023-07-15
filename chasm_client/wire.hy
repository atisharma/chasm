(import json)
(import zmq)
(import time [time])
(import uuid [uuid1])

(setv sender-id (. (uuid1) hex))


(setv CHASM_PROTOCOL_VERSION "0.0.1")
(setv CHASM_CLIENT_VERSION (.join "/" [__name__ "0.0.1"]))


(defn wrap [payload]
  "Format and wrap message."
  (json.dumps {"payload" payload
               "proto_version" CHASM_PROTOCOL_VERSION
               "client_version" CHASM_CLIENT_VERSION
               "zmq_version" zmq.__version__
               "sender_id" sender-id
               "sender_time" (time)}))

(defn unwrap [zmsg]
  "Unwrap message. Return None if it doesn't decode.
Otherwise, return function and data."
  (try
    (let [msg (json.loads zmsg)]
      (:payload msg None))
    (except [json.JSONDecodeError]
      (log.error f"wire/unwrap: zmsg"))))
