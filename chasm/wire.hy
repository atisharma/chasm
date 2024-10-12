"
The client protocol implementation. The client signs messages.
"
(import json)
(import zmq)
(import time [time])
(import uuid [uuid1])

(import hyjinx [crypto])

(import chasm.lib [config hash-id])


(setv sender-id (. (uuid1) hex))


;; TODO increment this when implementing `status`
(setv CHASM_PROTOCOL_VERSION "0.0.1")
;; TODO maybe get this from the module version
(setv CHASM_CLIENT_VERSION (.join "/" [__name__ "0.0.1"]))

(setv keys (crypto.keys (config "passphrase"))
      player (config "name")
      priv-key (:private keys)
      pub-key (:public-pem keys))


(defn wrap [payload]
  "Format, sign and wrap the payload."
  (let [t (str (time))
        payload-hash (hash-id (+ t (json.dumps payload)))
        signature (crypto.sign priv-key payload-hash)]
    (.encode (json.dumps {"payload" payload
                          "proto_version" CHASM_PROTOCOL_VERSION
                          "client_version" CHASM_CLIENT_VERSION
                          "zmq_version" zmq.__version__
                          "player" player
                          "sender_id" sender-id
                          "sender_time" t
                          "public_key" pub-key
                          "signature" signature}))))

(defn unwrap [zmsg]
  "Unwrap message. Return None if it doesn't decode. Otherwise, return function and data."
  (try (json.loads (.decode zmsg))
    (except [json.JSONDecodeError]
      (log.error f"wire/unwrap: {zmsg}"))))

(defn zerror [code message]
  {"error" {"code" code "message" message}})
