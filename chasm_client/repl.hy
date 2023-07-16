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
(import chasm-client.interface [banner clear console rlinput spinner
                                exception error info print-message print-messages
                                set-status-line])


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
        objectives (:objectives p None)]
    (set-status-line
      (.join "\n"
             [(.join " | "
                     [f"{world-name}"
                      f"{place-name}"
                      f"{(:x coords)} {(:y coords)}"])
              (.join " | "
                     [f"{name}"
                      f"{objectives}"
                      f"score: {score}"])
              f"{inventory}"]))))

(defn run []
  "Launch the REPL, which takes player's input, parses
it, and passes it to the appropriate action."
  (log.info f"Starting REPL at {(.isoformat (datetime.today))}")

  (banner)
  (console.rule)

  (let [player-name (config "name")
        card-path f"characters/{player-name}.json"
        player-attributes (or (load card-path) {})
        response (with [(spinner "Spawning...")]
                   (spawn player-name #** player-attributes))]
    (while True
      (try ; ----- parser block ----- 
        (if response
            (do
              (let [errors (:errors response None)
                    message (:result response None)]
                (when errors
                  (error errors))
                (when message
                  (match (:role message)
                         "QUIT" (do (clear) (break))
                         "assistant" (print-message message)
                         "info" (info (:content message))
                         "error" (error (:content message))
                         "history" (print-messages (msgs->dlg player-name "narrator" (:narrative response))))))
              (status response)
              (let [line (.strip (rlinput "> "))]
                (when (quit? line)
                  (send-quit player-name "/quit")
                  (clear)
                  (break))
                (when line
                  (setv response (with [(spinner "Writing...")]
                                   (parse player-name line))))))
            (do
              (error "The request to the server timed out. Try again later.")
              (sleep 1)))
        (except [KeyboardInterrupt]
          (print)
          (error "**/quit** to exit"))
        (except [e [Exception]]
          (log.error "REPL error" e :mode "w" :logfile "traceback.log")
          (exception)
          (sleep 10))))))

(defmain [#* args]
  (sys.exit (run)))
