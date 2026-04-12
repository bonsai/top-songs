;;; generator-facades.lisp — High-level generation API

(in-package :gakuri)

(defun generate-emotional-progression (key-root &key
                                        (key-mode :major)
                                        (mood :ballad)
                                        (length 8)
                                        (return-evaluation t))
  "Generate an emotionally resonant jazz progression for a given mood.
   
   Example:
     (generate-emotional-progression 0 :mood :yearning :length 10 :key-mode :major)
     => C major yearning progression, 10 chords"
  (let* ((key (make-key-signature :root key-root :mode key-mode))
         (result (progression-for-mood key :mood mood :length length)))
    (when return-evaluation
      (let ((eval-result (evaluate-progression
                          (getf result :progression) key)))
        (store-evaluated-progression (getf result :progression)
                                     key mood eval-result
                                     :tags (list mood key-mode))
        (list :progression (getf result :progression)
              :evaluation eval-result
              :tension-curve (getf result :tension-curve)
              :match-score (getf result :match-score)))))

(defun generate-batch (key-root &key
                       (key-mode :major)
                       (moods '(:ballad :yearning :noir :neo-soul :melancholic))
                       (per-mood 5)
                       (length 8))
  "Generate a batch of progressions across multiple moods.
   Returns a list of results sorted by emotional score."
  (let (results)
    (dolist (mood moods)
      (dotimes (i per-mood)
        (let ((result (generate-emotional-progression
                       key-root
                       :key-mode key-mode
                       :mood mood
                       :length length)))
          (push result results))))
    (sort results #'>
          :key (lambda (r)
                 (let ((eval (getf r :evaluation)))
                   (if eval (evaluation-result-overall eval) 0))))))

(defun analyze-and-rate (progression key &key (mood nil))
  "Analyze an existing progression and rate it.
   If mood is specified, also compute profile match score."
  (let* ((eval-result (evaluate-progression progression key))
         (result (list :evaluation eval-result
                       :emotional-score (evaluation-result-emotional-score eval-result)
                       :overall (evaluation-result-overall eval-result)
                       :tension-arc (evaluation-result-tension-arc eval-result))))
    (when mood
      (let* ((profile (cdr (assoc mood *emotional-profiles*)))
             (match (when profile
                      (match-profile-to-progression progression key profile))))
        (setf (getf result :profile-match) match)))
    result))

(defun export-progression-text (progression key &key (format :roman))
  "Export a progression as human-readable text.
   Formats: :roman (I, ii, V7, etc.), :pitch (Cmaj7, Dm7, G7, etc.)"
  (let ((key-root (key-signature-root key))
        (key-mode (key-signature-mode key)))
    (case format
      (:roman
       (mapcar (lambda (chord)
                 (chord->roman chord key-root key-mode))
               progression))
      (:pitch
       (mapcar (lambda (chord)
                 (chord->string chord))
               progression))
      (t (format nil "Unknown format: ~A" format)))))

(defun chord->roman (chord key-root key-mode)
  "Convert a chord to Roman numeral notation relative to key."
  (let* ((root (chord-root chord))
         (degree (mod (- root key-root) 12))
         (type (chord-type chord))
         (roman (case degree
                  (0 "I") (1 "bII") (2 "ii") (3 "bIII") (4 "III")
                  (5 "IV") (6 "bV/#IV") (7 "V") (8 "bVI") (9 "VI")
                  (10 "bVII") (11 "vii")))
         (quality-suffix (case type
                           (:major-seventh "maj7")
                           (:minor-seventh "m7")
                           (:dominant "7")
                           (:half-diminished "m7b5")
                           (:fully-diminished "dim7")
                           (:dominant "7")
                           (t "")))
         (extensions (chord-extensions chord))
         (alterations (chord-alterations chord))
         (ext-str (format nil "~{~A~}"
                          (mapcar (lambda (e)
                                    (case e
                                      (7M "") (9 "9") (11 "11") (13 "13")
                                      (b9 "b9") (#9 "#9") (#11 "#11") (b13 "b13")
                                      (otherwise (format nil "~A" e))))
                                  extensions)))
         (alt-str (format nil "~{~A~}"
                          (mapcar (lambda (a)
                                    (case a
                                      (b9 "b9") (#9 "#9") (#11 "#11") (b13 "b13")
                                      (otherwise (format nil "~A" a))))
                                  alterations))))
    (format nil "~A~A~A~A" roman quality-suffix ext-str alt-str)))

(defun chord->string (chord)
  "Convert a chord to pitch-class string notation (e.g., 'Cmaj9')."
  (let* ((root-name (car (rassoc (chord-root chord) *pitch-classes*)))
         (type-str (case (chord-type chord)
                     (:major-seventh "maj")
                     (:minor-seventh "m")
                     (:dominant "")
                     (:half-diminished "m7b5")
                     (:fully-diminished "dim")
                     (t "")))
         (ext-str (format nil "~{~A~}"
                          (mapcar (lambda (e)
                                    (case e
                                      (7M "maj7") (9 "9") (11 "11") (13 "13")
                                      (otherwise (format nil "~A" e))))
                                  (chord-extensions chord))))
         (alt-str (format nil "~{~A~}"
                          (mapcar (lambda (a)
                                    (case a
                                      (b9 "b9") (#9 "#9") (#11 "#11") (b13 "b13")
                                      (otherwise (format nil "~A" a))))
                                  (chord-alterations chord)))))
    (format nil "~A~A~A~A" root-name type-str ext-str alt-str)))
