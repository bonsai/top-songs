;;; cli.lisp — Command-line interface for GAKURI

(in-package :gakuri)

(defun main ()
  "CLI entry point for GAKURI."
  (format t "~%╔══════════════════════════════════════════════════════════╗~%")
  (format t "║  GAKURI — Emotional Jazz Chord Progression Generator      ║~%")
  (format t "║  SAKURA Lab (Zappa) | Paper-Driven Lisp Project           ║~%")
  (format t "╚══════════════════════════════════════════════════════════╝~%~%")
  
  (let* ((moods '(:ballad :bebop :melancholic :uplifting :yearning
                  :noir :neo-soul :peaceful :dramatic :bittersweet))
         (keys '((0 . "C") (1 . "C#/Db") (2 . "D") (3 . "D#/Eb") (4 . "E")
                 (5 . "F") (6 . "F#/Gb") (7 . "G") (8 . "G#/Ab") (9 . "A")
                 (10 . "A#/Bb") (11 . "B")))
         (modes '(:major :minor :dorian :mixolydian)))
    
    ;; Demo: generate one progression per mood in C major
    (format t "--- Demo: One progression per mood (C major, 8 chords) ---~%~%")
    
    (dolist (mood moods)
      (let* ((key (make-key-signature :root 0 :mode :major))
             (result (progression-for-mood key :mood mood :length 8))
             (progression (getf result :progression))
             (eval-result (evaluate-progression progression key)))
        
        (format t "【~A】~%" (string-upcase (symbol-name mood)))
        (format t "  Progression: ~{~A~^ → ~}~%"
                (mapcar #'chord->string progression))
        (format t "  Roman:       ~{~A~^ → ~}~%"
                (mapcar (lambda (c) (chord->roman c 0 :major)) progression))
        (format t "  Tension:     ~{~,2F~^ → ~}~%"
                (tension-curve-normalized (evaluation-result-details eval-result)))
        (format t "  Arc:         ~A~%" (evaluation-result-tension-arc eval-result))
        (format t "  Emotional:   ~,2F~%" (evaluation-result-emotional-score eval-result))
        (format t "  Overall:     ~,2F~%~%" (evaluation-result-overall eval-result))))
    
    ;; Batch generation
    (format t "--- Top 5 Batch Results ---~%~%")
    (let ((batch (generate-batch 0 :moods '(:yearning :noir :neo-soul :bittersweet)
                                 :per-mood 3 :length 10)))
      (loop for i below (min 5 (length batch))
            for result = (nth i batch)
            do (format t "~2D. [~A] score=~,2F~%"
                       (1+ i)
                       (string-upcase (symbol-name (getf result :mood)))
                       (let ((eval (getf result :evaluation)))
                         (if eval (evaluation-result-overall eval) 0)))))
    
    (format t "~%Done.~%")))
