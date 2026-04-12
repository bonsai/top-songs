;;; gakuri.asd — GAKURI: Emotional Jazz Chord Progression Generator
;;; Paper-driven Lisp project — SAKURA lab (Zappa)

(asdf:defsystem :gakuri
  :name "gakuri"
  :version "0.1.0"
  :author "Zappa (SAKURA Lab)"
  :licence "MIT"
  :description "Emotionally resonant jazz chord progression generator driven by academic research"
  :depends-on (:alexandria :serapeum :lparallel)
  :pathname "src/"
  :components ((:file "package")
               (:file "music-theory" :depends-on ("package"))
               (:file "tension-model" :depends-on ("package" "music-theory"))
               (:file "voice-leading" :depends-on ("package" "music-theory"))
               (:file "progression-gen" :depends-on ("package" "music-theory" "tension-model" "voice-leading"))
               (:file "evaluator" :depends-on ("package" "tension-model" "voice-leading"))
               (:file "emotional-profiles" :depends-on ("package" "tension-model" "evaluator"))
               (:file "database" :depends-on ("package" "progression-gen"))
               (:file "midi-export" :depends-on ("package" "music-theory" "progression-gen"))
               (:file "generator-facades" :depends-on ("package" "progression-gen" "emotional-profiles" "database"))
               (:file "cli" :depends-on ("package" "generator-facades" "midi-export")))
  :in-order-to ((test-op (test-op :gakuri/tests))))

(asdf:defsystem :gakuri/tests
  :name "gakuri-tests"
  :depends-on (:gakuri :rove)
  :pathname "tests/"
  :components ((:file "t-test")
               (:file "t-tension")
               (:file "t-progression-gen")
               (:file "t-evaluator")
               (:file "t-emotional-profiles"))
  :perform (test-op (o c)
             (symbol-call :rove :run :gakuri/tests)))
