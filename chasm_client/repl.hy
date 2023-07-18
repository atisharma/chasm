"
The main REPL where we read output and issue commands.
"
(require hyrule [defmain])
(require hyrule.argmove [-> ->> as->])

(import chasm-client [log])

(import os)
(import datetime [datetime])
(import time [sleep])

(import chasm-client.lib *)
(import chasm-client.client [parse spawn send-quit])
(import chasm-client.chat [msgs->dlg])
(import chasm-client.interface [banner clear console rlinput
                                spinner
                                exception error info print-message print-messages
                                set-status-line set-width
                                _italic _color])


;;; -----------------------------------------------------------------------------
;;; All player-specific code goes in here
;;; -----------------------------------------------------------------------------

(defn quit? [line]
  (or (.startswith line "/q")
      (.startswith line "/exit")))

(defn status [response]
  "Show game, place, inventory..."
  (let [world-name (:world response None)
        coords (:coords response {"x" Inf "y" Inf})
        p (:player response {})
        name (:name p None) 
        inventory (.join ", " (:inventory p []))
        place-name (:place p None)
        score (:score p None)
        score (:turns p None)
        objective (:objective p None)]
    (set-status-line
      (.join "\n"
             [(.join " | "
                     [(_italic (_color f"{world-name}" "blue"))
                      (_italic (_color f"{place-name}" "cyan"))
                      (_italic f"{(:x coords)} {(:y coords)}")])
              (.join " | "
                     [(_italic (_color f"{name}" "blue"))
                      (_italic (_color f"{objective}" "cyan"))
                      (_italic f"score: {score}/{turns}")])
              (_italic (_color f"{inventory}" "magenta"))]))))

(defn handle [response]
  "Output the response."
  (when response
    (let [errors (:errors response None)
          message (:result response None)]
      (when errors
        (error errors))
      (when message
        (match (:role message)
               "QUIT" (do (clear) (sys.exit))
               "assistant" (print-message message)
               "info" (info (:content message))
               "error" (error (:content message))
               "history" (print-messages (msgs->dlg (config "name") "narrator" (:narrative response [])))
               "history" (print (:narrative response [])))))
    (status response)))

(defn run []
  "Launch the REPL, which takes player's input, parses
it, and passes it to the appropriate action."
  (log.info f"Starting REPL at {(.isoformat (datetime.today))}")
  (banner)
  (info "Enter **/help** for help\n")
  (console.rule)
  (let [player-name (config "name")
        card-path f"characters/{player-name}.json"
        player-attributes (or (load card-path) {})
        response (with [(spinner "Spawning...")]
                   (spawn player-name #** player-attributes))]
    (while True
      (try ; ----- parser block ----- 
        (handle response)
        (let [line (.strip (rlinput "> "))]
          (setv response None)
          (cond (.startswith line "/width ") (set-width line)
                (quit? line) (do
                               (send-quit player-name "/quit")
                               (clear)
                               (break))
                line (setv response (with [(spinner "Writing...")]
                                      (parse player-name line)))))
        (except [KeyboardInterrupt]
          (clear)
          (error "**/quit** to exit"))
        (except [e [Exception]]
          (log.error "REPL error" e :mode "w" :logfile "traceback.log")
          (exception)
          (sleep 5))))))

(defmain [#* args]
  (sys.exit (run)))
