"
Chat management functions.
"
(require hyrule.argmove [-> ->>])

(import chasm [log])

(import chasm.lib *)


;; -----------------------------------------------------------------------------

(defclass ChatError [Exception])

;; Message functions
;; -----------------------------------------------------------------------------

(defn msg [role #* content]
  "Just a simple dict with the needed fields."
  {"role" role
   "content" (->> content
                  (.join "\n")
                  (.strip))})

(defn system [#* content]
  (msg "system" #* content))

(defn user [#* content]
  (msg "user" #* content))

(defn assistant [#* content]
  (msg "assistant" #* content))

;; Chat functions
;; -----------------------------------------------------------------------------

(defn standard-roles [messages]
  "Remove messages not with standard role."
  (lfor m messages
        :if (in (:role m) ["assistant" "user" "system"])
        m))
  
(defn msg->dlg [user-name assistant-name message]
  "Replace standard roles with given names and ignore roles with system messages.
Return modified dialogue message or None." 
  (let [role (:role message)]
    (cond (= role "user") (msg user-name (:content message))
          (= role "assistant") (msg assistant-name (:content message))
          :else None)))

(defn msgs->dlg [user-name assistant-name messages]
  "Replace standard roles with given names and filter out system messages.
Return dialogue." 
  (->> messages
       (map (partial msg->dlg user-name assistant-name))
       (sieve)
       (list)))

(defn dlg->msg [user-name assistant-name message]
  "Replace given names with standard roles and replace other roles with system messages.
Return modified message."
  (let [role (:role message)]
    (cond (= role user-name) (user (:content message))
          (= role assistant-name) (assistant (:content message))
          :else (system f"{role}: {(:content message)}"))))
    
(defn dlg->msgs  [user-name assistant-name messages]
  "Replace given names with standard roles and replace other roles with system messages.
Return modified messages."
  (->> messages
       (map (partial dlg->msg user-name assistant-name))
       (list)))

(defn flip-roles [messages]
  (dlg->msgs "assistant" "user" messages))
