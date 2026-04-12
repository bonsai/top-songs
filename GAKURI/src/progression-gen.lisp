;;; progression-gen.lisp — Jazz chord progression generation engine
;;; Driven by: TRoco algorithm, CoreaChord Markov chains, jazz theory rules

(in-package :gakuri)

;;; ── Functional Harmony Rules ──────────────────────────────────────

(defparameter *functional-transitions*
  "Markov-style transition probabilities for functional harmony.
   Based on jazz harmonic practice (Mark Levine, Mark Harrison).
   Keys: current scale degree → list of (next-degree . weight)"
  `((:tonic . ((:subdominant . 0.30d0)
               (:dominant . 0.25d0)
               (:tonic . 0.20d0)
               (:mediant . 0.15d0)
               (:submediant . 0.10d0)))
    (:subdominant . ((:dominant . 0.45d0)
                     (:tonic . 0.20d0)
                     (:submediant . 0.15d0)
                     (:subdominant . 0.10d0)
                     (:mediant . 0.10d0)))
    (:dominant . ((:tonic . 0.55d0)
                  (:submediant . 0.20d0)
                  (:subdominant . 0.10d0)
                  (:dominant . 0.10d0)
                  (:mediant . 0.05d0)))
    (:mediant . ((:subdominant . 0.30d0)
                 (:dominant . 0.25d0)
                 (:submediant . 0.20d0)
                 (:tonic . 0.15d0)
                 (:mediant . 0.10d0)))
    (:submediant . ((:subdominant . 0.30d0)
                    (:dominant . 0.25d0)
                    (:tonic . 0.20d0)
                    (:mediant . 0.15d0)
                    (:submediant . 0.10d0)))))

(defparameter *scale-degree-chords*
  "Scale degree → default chord type mapping for jazz."
  '((:tonic . ((:major . :major-seventh) (:minor . :minor-seventh)))
    (:supertonic . ((:major . :minor-seventh) (:minor . :half-diminished)))
    (:mediant . ((:major . :minor-seventh) (:minor . :major-seventh)))
    (:subdominant . ((:major . :major-seventh) (:minor . :minor-seventh)))
    (:dominant . ((:major . :dominant) (:minor . :dominant)))
    (:submediant . ((:major . :minor-seventh) (:minor . :major-seventh)))
    (:leading-tone . ((:major . :half-diminished) (:minor . :dominant)))))

;;; ── Weighted Random Selection ─────────────────────────────────────

(defun weighted-random (weighted-list)
  "Select an item from an alist of (item . weight) using weighted random."
  (let ((total (reduce #'+ weighted-list :key #'cdr)))
    (let ((pick (* (random 1.0d0) total)))
      (let ((cum 0.0d0))
        (dolist (pair weighted-list)
          (incf cum (cdr pair))
          (when (<= pick cum)
            (return-from weighted-random (car pair))))
        (caar weighted-list)))))

;;; ── ii-V-I Generation ─────────────────────────────────────────────

(defun generate-ii-v-i (key &key (mode :major) (extensions t))
  "Generate a ii-V-I progression with jazz extensions.
   The most fundamental jazz progression."
  (let* ((key-root (key-signature-root key))
         (ii-root (if (eq mode :major)
                      (mod (+ key-root 2) 12)
                      (mod (+ key-root 2) 12)))
         (v-root (mod (+ key-root 7) 12))
         (i-root key-root)
         (ii-type (if (eq mode :major) :minor-seventh :half-diminished))
         (v-type :dominant)
         (i-type (if (eq mode :major) :major-seventh :minor-seventh)))
    (list
     (build-chord ii-root ii-type
                  :extensions (when extensions
                                (weighted-random '((nil . 0.3d0) (9 . 0.4d0) (11 . 0.3d0))))
                  :voicing :drop2)
     (build-chord v-root v-type
                  :extensions (when extensions
                                (weighted-random '((7 . 0.2d0) (9 . 0.3d0) (13 . 0.2d0) (b9 . 0.15d0) (#11 . 0.15d0))))
                  :alterations (when extensions
                                 (weighted-random '((nil . 0.4d0) (b9 . 0.2d0) (#11 . 0.2d0) (b9 #11 . 0.2d0))))
                  :voicing :drop2)
     (build-chord i-root i-type
                  :extensions (when extensions
                                (weighted-random '((7M . 0.3d0) (9 . 0.3d0) (6 . 0.2d0) (9 7M . 0.2d0))))
                  :voicing :drop2))))

(defun generate-ii-v-i-variations (key &key (count 5) (mode :major))
  "Generate multiple variations of ii-V-I progressions."
  (loop repeat count
        collect (generate-ii-v-i key :mode mode :extensions t)))

;;; ── Tritone Substitution ──────────────────────────────────────────

(defun tritone-substitute (chord)
  "Create a tritone substitution of a dominant chord.
   V7 → bII7 (substitute dominant a tritone away)."
  (unless (member (chord-type chord) '(:dominant :dominant-seventh))
    (return-from tritone-substitute chord))
  (let* ((orig-root (chord-root chord))
         (sub-root (mod (+ orig-root 6) 12)))  ; tritone = 6 semitones
    (build-chord sub-root :dominant
                 :extensions (chord-extensions chord)
                 :alterations (chord-alterations chord)
                 :voicing (chord-voicing chord))))

(defun generate-tritone-substitutions (progression)
  "Apply tritone substitutions to dominant chords in a progression."
  (mapcar (lambda (chord)
            (if (and (eq (chord-type chord) :dominant)
                     (> (random 1.0d0) 0.5d0))
                (tritone-substitute chord)
                chord))
          progression))

;;; ── Modal Interchange ─────────────────────────────────────────────

(defparameter *modal-borrow-chords*
  "Common borrowed chords from parallel modes."
  '((:major . ((:minor . ((:bVI . :major-seventh) (:bVII . :dominant) (:iv . :minor-seventh)
                          (:bII . :major-seventh) (:bIII . :major)))
               (:dorian . ((:IV . :major-seventh) (:v . :minor-seventh)))
               (:phrygian . ((:bII . :major) (:bVI . :major-seventh)))
               (:lydian . ((:II . :major) (:vii . :half-diminished)))
               (:mixolydian . ((:bVII . :dominant) (:iv . :minor-seventh)))))
    (:minor . ((:dorian . ((:IV . :major-seventh) (:VI . :major)))
               (:phrygian . ((:bII . :major)))
               (:aeolian . ((:bVI . :major-seventh) (:bVII . :dominant)))
               (:harmonic-minor . ((:V . :dominant) (:bVI . :major-seventh)))))))

(defun generate-modal-interchange (key &key (length 8) (mode :major))
  "Generate a progression with modal interchange (borrowed chords)."
  (let* ((progression nil)
         (current-func :tonic)
         (borrow-mode (weighted-random '((nil . 0.6d0)
                                         (:dorian . 0.15d0)
                                         (:phrygian . 0.10d0)
                                         (:lydian . 0.10d0)
                                         (:mixolydian . 0.05d0)))))
    (dotimes (i length)
      (let ((func (weighted-random (cdr (assoc current-func *functional-transitions*))))
            (should-borrow (and borrow-mode (> (random 1.0d0) 0.7d0))))
        (if should-borrow
            (let ((borrowed (generate-borrowed-chord key borrow-mode func)))
              (when borrowed (push borrowed progression)))
            (let ((chord (generate-chord-for-function key func mode)))
              (push chord progression)))
        (setq current-func func)))
    (nreverse progression)))

(defun generate-borrowed-chord (key borrow-mode function)
  "Generate a borrowed chord from a parallel mode."
  (let* ((key-root (key-signature-root key))
         (borrow-chords (cdr (assoc borrow-mode
                                    (cdr (assoc (key-signature-mode key)
                                                *modal-borrow-chords*)))))
         (chord-spec (cdr (assoc function borrow-chords))))
    (when chord-spec
      (let ((root-offset (car chord-spec))
            (chord-type-spec (cdr chord-spec)))
        (build-chord (mod (+ key-root (case root-offset
                                         (:bVI 8) (:bVII 10) (:iv 5)
                                         (:bII 1) (:bIII 3) (:II 2)
                                         (:VI 9) (:v 7) (:IV 5)
                                         (:V 7) (:vii 11) (t 0)))
                           12)
                     chord-type-spec
                     :voicing :close)))))

(defun generate-chord-for-function (key function mode)
  "Generate a chord for a given harmonic function."
  (let* ((key-root (key-signature-root key))
         (root-offset (case function
                        (:tonic 0) (:supertonic 2) (:mediant 4)
                        (:subdominant 5) (:dominant 7)
                        (:submediant 9) (:leading-tone 11)))
         (root (mod (+ key-root root-offset) 12))
         (type-spec (cdr (assoc function *scale-degree-chords*)))
         (type (cdr (assoc mode type-spec))))
    (build-chord root type :voicing :drop2)))

;;; ── Altered Dominants ─────────────────────────────────────────────

(defparameter *alteration-sets*
  "Common jazz alteration sets for dominant chords."
  '((:basic . nil)
    (:b9 . (b9))
    (#9 . (#9))
    (b9#9 . (b9 #9))
    (#11 . (#11))
    (b13 . (b13))
    (b9#11 . (b9 #11))
    (#9b13 . (#9 b13))
    (alt . (b9 #9 #11 b13))
    (7alt . (b9 #11))))

(defun generate-altered-dominant (root &key (alteration-set :alt))
  "Generate an altered dominant chord."
  (let ((alts (cdr (assoc alteration-set *alteration-sets*))))
    (build-chord root :dominant
                 :alterations alts
                 :extensions '(7)
                 :voicing :drop2)))

(defun generate-altered-dominants (progression)
  "Add altered dominants to dominant-function chords in a progression."
  (mapcar (lambda (chord)
            (if (eq (chord-type chord) :dominant)
                (let ((alt-set (weighted-random '((:basic . 0.15d0)
                                                  (:b9 . 0.15d0)
                                                  (#11 . 0.15d0)
                                                  (b9#11 . 0.15d0)
                                                  (alt . 0.20d0)
                                                  (7alt . 0.20d0)))))
                  (generate-altered-dominant (chord-root chord)
                                             :alteration-set alt-set))
                chord))
          progression))

;;; ── Extended Progression Generation ───────────────────────────────

(defun generate-extended-progressions (key &key (length 12) (style :standard))
  "Generate an extended jazz progression."
  (let ((progression nil)
        (current-func :tonic))
    (dotimes (i length)
      (let ((next-func (weighted-random
                        (cdr (assoc current-func *functional-transitions*)))))
        (push (generate-chord-for-function key next-func
                                           (key-signature-mode key))
              progression)
        (setq current-func next-func)))
    (let ((result (nreverse progression)))
      (ecase style
        (:standard result)
        (:tritone-sub (generate-tritone-substitutions result))
        (:altered (generate-altered-dominants result))
        (:modal (generate-modal-interchange key :length length
                                            :mode (key-signature-mode key)))))))

(defun with-tension-profile (progression key target-profile)
  "Filter/select chords to match a target tension profile.
   target-profile is a list of desired tension values [0,1]."
  (let* ((tension-states (compute-tension-curve progression key))
         (normalized (tension-curve-normalized tension-states))
         (scores nil))
    ;; Score how well the progression matches the target profile
    (let ((mse (reduce #'+ (mapcar (lambda (actual target)
                                     (expt (- actual target) 2))
                                   normalized target-profile))))
      (list :progression progression
            :tension-curve normalized
            :match-score (sqrt mse)
            :states tension-states))))

(defun progression-for-mood (key &key (mood :ballad) (length 8))
  "Generate a progression optimized for a specific emotional mood."
  (let* ((profile (cdr (assoc mood *emotional-profiles*)))
         (best nil)
         (best-score most-positive-double-float))
    (dotimes (i 50)  ; Generate 50 candidates, pick best match
      (let ((candidate (generate-extended-progressions key
                                                       :length length
                                                       :style (case mood
                                                                (:ballad :standard)
                                                                (:noir :altered)
                                                                (:neo-soul :modal)
                                                                (t :standard))))
            (result (with-tension-profile candidate key profile)))
        (when (< (getf result :match-score) best-score)
          (setq best result)
          (setq best-score (getf result :match-score)))))
    best))
