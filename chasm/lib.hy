(require hyrule.argmove [-> ->>])
(require hyrule.control [unless])
(import hyrule [inc dec rest butlast starmap distinct])

(import hyjinx.lib [mreload
                    first second last drop
                    hash-id short-id])
(import hyjinx.lib [slurp
                    spit
                    jload :as load
                    jsave :as save
                    jappend :as file-append])

(import functools [partial cache lru-cache])
(import itertools *)

(import importlib)
(import os)
(import re)
(import json)
(import readline)
(import pathlib [Path])
(import hashlib [sha1 pbkdf2-hmac])
(import hmac [compare-digest])

(import tomllib) ; tomllib for python 3.11 onwards


;; list functions
;; -----------------------------------------------------------------------------

(defn sieve [xs]
  (filter None xs))

(defn pairs [xs]
  "Split into pairs. So ABCD -> AB CD."
  (zip (islice xs 0 None 2) (islice xs 1 None 2)))
  
;; config functions
;; -----------------------------------------------------------------------------

(setv config-file "client.toml")

(defn config [#* keys]
  "Get values in a toml file like a hashmap, but default to None."
  (unless (os.path.isfile config-file)
    (raise (FileNotFoundError config-file)))
  (try
    (-> config-file
        (slurp)
        (tomllib.loads)
        (get #* keys))
    (except [KeyError]
      None)))

;; File & IO functions
;; -----------------------------------------------------------------------------

(defn mksubdir [d]
  (.mkdir (Path (.join "/" [path d]))
          :parents True
          :exist-ok True))  

;; Hashing, id and password functions
;; -----------------------------------------------------------------------------

(defn hash-pw [pw]
  "Hash password with a secret salt."
  (let [salt (os.urandom 24)
        digest (pbkdf2-hmac "sha512"
                            (pw.encode "utf-8")
                            :iterations 100000
                            :salt salt)]
    {"salt" (.hex salt)
     "hexdigest" (.hex digest)}))

(defn check-pw [pw stored]
  "Check password is correct."
  (let [salt (bytes.fromhex (:salt stored))
        hexdigest (:hexdigest stored)]
    (compare-digest hexdigest (.hex (pbkdf2-hmac "sha512"
                                                 (pw.encode "utf-8")
                                                 :iterations 100000
                                                 :salt salt)))))

;; String functions
;; -----------------------------------------------------------------------------

(defn format-msg [message] 
  "Format a chat or dialogue message as a string."
  (let [l (-> message
              (:role)
              (.capitalize)
              (+ ":"))
        content (-> message
                    (:content)
                    (.strip))]
    f"{l :<3} {(.strip (:content message))}"))

(defn format-msgs [messages]
  "Format a chat or dialogue as a long string."
  (.join "\n"
         (map format-msg messages)))
