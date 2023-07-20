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
                                exception error info print-message print-messages print-input
                                set-window-title set-status-line set-width
                                _bold _italic _color])


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
        turns (:turns p None)
        objective (:objective p None)
        compass (.splitlines (:compass p "\n\n\n"))]
    (set-window-title f"chasm - {name} - {world-name} - {place-name}")
    (set-status-line
      (.join "\n"
             [(.join " | "
                     [(+ (_color (get compass 0) "green") (_bold (_italic (_color f"  {world-name}" "blue"))))
                      (_italic (_color f"{place-name}" "cyan"))
                      (_italic f"{(:x coords)} {(:y coords)}")
                      (_italic f"{turns} turns")
                      (_italic f"{score}")])
              (.join " | "
                     [(+ (_color (get compass 1) "green") (_bold (_italic (_color f"  {name}" "blue"))))
                      (_italic (_color f"{objective}" "cyan"))])
              (+ (_color (get compass 2) "green") (_italic (_color f"  {inventory}" "magenta")))]))))

(defn handle [response]
  "Output the response."
  (when response
    (let [errors (:errors response None)
          message (:result response None)
          width (or (config "width") 100)]
      (when errors
        (error errors :width width))
      (when message
        (match (:role message)
               "QUIT" (do (clear) (sys.exit))
               "assistant" (print-message message :width width)
               "info" (info (:content message) :width width)
               "error" (error (:content message) :width width)
               "history" (print-messages (msgs->dlg (config "name")
                                                    "narrator"
                                                    (:narrative response []))
                                         :width width))))
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
        (let [line (print-input "> ")
              width (or (config "width") 100)]
          (setv response None)
          (cond (.startswith line "/width ") (set-width line)
                (.startswith line "/banner") (banner)
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
