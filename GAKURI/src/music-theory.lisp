;;; music-theory.lisp — Core music theory representation
;;; Jazz harmony model: pitch classes, chords, extensions, alterations

(in-package :gakuri)

;;; ── Pitch Classes & Note Representation ──────────────────────────

(defparameter *pitch-classes*
  '(("C" . 0) ("C#" . 1) ("Db" . 1) ("D" . 2) ("D#" . 3) ("Eb" . 3)
    ("E" . 4) ("Fb" . 4) ("E#" . 5) ("F" . 5) ("F#" . 6) ("Gb" . 6)
    ("G" . 7) ("G#" . 8) ("Ab" . 8) ("A" . 9) ("A#" . 10) ("Bb" . 10)
    ("B" . 11) ("Cb" . 11)))

(defparameter *note-names* #("C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"))

(defparameter *scale-degrees*
  '((1 . "tonic") (2 . "supertonic") (3 . "mediant") (4 . "subdominant")
    (5 . "dominant") (6 . "submediant") (7 . "leading-tone")))

;;; Jazz scale degrees with alterations
(defparameter *jazz-scale-degrees*
  '((1 . "root") (b2 . "flat-nine") (2 . "nine") (#2 . "sharp-nine")
    (b3 . "flat-third") (3 . "third") (4 . "eleven") (#4 . "sharp-eleven")
    (b5 . "flat-five") (5 . "fifth") (#5 . "sharp-five")
    (b6 . "flat-thirteen") (6 . "thirteen") (b7 . "flat-seven") (7 . "major-seven")))

;;; ── Chord Representation ──────────────────────────────────────────

(defstruct chord
  "Represents a jazz chord with root, type, extensions, and inversion."
  (root 0 :type integer)              ; pitch class 0-11
  (type :major :type keyword)         ; :major :minor :dominant :diminished :half-diminished
  (extensions nil :type list)         ; e.g. (7 9 13) for Cmaj9(13)
  (alterations nil :type list)        ; e.g. (b9 #11) for altered dominant
  (inversion 0 :type integer)         ; 0=root, 1=1st, 2=2nd, 3=3rd
  (bass-note nil :type (or null integer)) ; if non-nil, specifies bass pitch class
  (voicing :close :type keyword))     ; :close :open :drop2 :drop3

(defstruct key-signature
  "Key signature with mode."
  (root 0 :type integer)
  (mode :major :type keyword))        ; :major :minor :dorian :mixolydian :lydian etc.

;;; ── Chord Types & Jazz Voicings ──────────────────────────────────

(defparameter *chord-intervals*
  "Interval structures for chord types (semitones from root)."
  '((:major . (0 4 7))
    (:minor . (0 3 7))
    (:diminished . (0 3 6))
    (:augmented . (0 4 8))
    (:dominant . (0 4 7 10))
    (:major-seventh . (0 4 7 11))
    (:minor-seventh . (0 3 7 10))
    (:half-diminished . (0 3 6 10))
    (:fully-diminished . (0 3 6 9))
    (:minor-major-seventh . (0 3 7 11))))

(defparameter *jazz-extensions*
  "Interval offsets for chord extensions."
  '((7 . 10) (b7 . 10) (7M . 11)
    (9 . 14) (b9 . 13) (#9 . 15)
    (11 . 17) (#11 . 18)
    (13 . 21) (b13 . 20)))

(defparameter *jazz-chord-qualities*
  "Common jazz chord qualities with typical extensions."
  '((:maj7 . (:major-seventh (7M) (9 7M) (9 7M 13) (6 9)))
    (:min7 . (:minor-seventh (7) (9 7) (11 7) (9 11 7)))
    (:dom7 . (:dominant (7) (9 7) (13 7) (b9 7) (#11 7) (b9 #11 7)))
    (:min7b5 . (:half-diminished (7) (9 7) (11 7)))
    (:dim7 . (:fully-diminished (b9) (b9 b13)))
    (:alt . (:dominant (7 b9 #9 #11 b13) (7 b9) (7 #9) (7 #11) (7 b13)))))

;;; ── Scale/Mode Definitions ────────────────────────────────────────

(defparameter *mode-intervals*
  "Interval patterns for modes (semitones from root)."
  '((:major . (0 2 4 5 7 9 11))
    (:natural-minor . (0 2 3 5 7 8 10))
    (:harmonic-minor . (0 2 3 5 7 8 11))
    (:melodic-minor . (0 2 3 5 7 9 11))
    (:dorian . (0 2 3 5 7 9 10))
    (:phrygian . (0 1 3 5 7 8 10))
    (:lydian . (0 2 4 6 7 9 11))
    (:mixolydian . (0 2 4 5 7 9 10))
    (:locrian . (0 1 3 5 6 8 10))
    (:lydian-dominant . (0 2 4 6 7 9 10))   ; 4th mode melodic minor
    (:altered . (0 1 3 5 6 8 10))           ; 7th mode melodic minor
    (:whole-tone . (0 2 4 6 8 10))
    (:diminished . (0 2 3 5 6 8 9 11)))))

;;; ── Core Functions ────────────────────────────────────────────────

(defun build-chord (root type &key (extensions nil) (alterations nil)
                            (inversion 0) (voicing :close))
  "Build a chord struct from root pitch-class, type, and optional parameters."
  (make-chord :root root
              :type type
              :extensions extensions
              :alterations alterations
              :inversion inversion
              :voicing voicing))

(defun chord-pitch-classes (chord)
  "Return the pitch classes of a chord as a sorted list."
  (let* ((base-intervals (cdr (assoc (chord-type chord) *chord-intervals*)))
         (pcs (copy-seq base-intervals)))
    ;; Add extensions
    (dolist (ext (chord-extensions chord))
      (let ((interval (cdr (assoc ext *jazz-extensions*))))
        (when interval (push interval pcs))))
    ;; Apply alterations
    (dolist (alt (chord-alterations chord))
      (let ((interval (cdr (assoc alt *jazz-extensions*))))
        (when interval (push interval pcs))))
    ;; Normalize to pitch classes
    (sort (remove-duplicates (mapcar (lambda (x) (mod x 12)) pcs)) #'<)))

(defun chord->midi (chord &key (octave 4))
  "Return MIDI note numbers for the chord."
  (let ((pcs (chord-pitch-classes chord))
        (root (chord-root chord)))
    (mapcar (lambda (pc)
              (+ (* (1+ octave) 12) pc))
            pcs)))

(defun parse-chord-notation (str)
  "Parse a chord notation string like 'Cmaj9' or 'G7#11b13' into a chord struct."
  (let* ((root-str (subseq str 0 1))
         (acc-pos (position-if (lambda (c) (member c '(#\# #\b))) str))
         (root-name (if acc-pos (subseq str 0 2) root-str))
         (root (cdr (assoc root-name *pitch-classes* :test #'string=)))
         (rest (subseq str (length root-name)))
         (type (cond
                 ((or (search "maj" rest) (search "M" rest) (search "△" rest)) :major-seventh)
                 ((search "min" rest) (search "m" rest) :minor-seventh)
                 ((search "dim" rest) :fully-diminished)
                 ((search "aug" rest) :augmented)
                 ((search "ø" rest) :half-diminished)
                 ((search "alt" rest) :dominant)
                 (t :dominant)))
         (extensions nil)
         (alterations nil))
    ;; Parse extensions and alterations from the remaining string
    (let ((num-start (position-if #'digit-char-p rest)))
      (when num-start
        (let ((num-str (subseq rest num-start)))
          ;; Extract numbers and alterations
          (let ((pos 0))
            (loop while (< pos (length num-str)) do
              (let ((ch (char num-str pos)))
                (cond
                  ((member ch '(#\# #\b))
                   (let* ((alt-ch (char num-str (1+ pos)))
                          (digit (digit-char-p alt-ch)))
                     (if digit
                         (push (intern (string alt-ch) :keyword) alterations)
                         (push (intern (string ch) :keyword) alterations))
                     (incf pos)))
                  ((digit-char-p ch)
                   (let ((end (position-if-not #'digit-char-p num-str :start pos)))
                     (let ((num (parse-integer num-str :start pos :end end)))
                       (push num extensions)
                       (setq pos (or end (length num-str))))))
                  (t (incf pos)))))))))
    (build-chord root type :extensions extensions :alterations alterations)))

;;; ── Tonal Interval Space (TIS) — DFT-based representation ────────
;;; Based on: "A Computational Model of Tonal Tension" (MDPI, 2020)

(defconstant +PHI+ (/ (1+ (sqrt 5d0)) 2))  ; Golden ratio for aesthetic weighting

(defun chord->tonal-interval-vector (chord)
  "Compute the 6D Tonal Interval Vector (TIV) via DFT.
   This maps the chord into the Tonal Interval Space for tension computation."
  (let* ((pcs (chord-pitch-classes chord))
         (n 12)
         (tiv (make-array 6 :element-type 'double-float :initial-element 0.0d0)))
    ;; DFT-based computation
    (dotimes (k 6)
      (let ((real 0.0d0)
            (imag 0.0d0))
        (dotimes (p n)
          (let ((amp (if (member p pcs) 1.0d0 0.0d0)))
            (incf real (* amp (cos (* 2 pi (/ (* (1+ k) p) n)))))
            (incf imag (* amp (sin (* 2 pi (/ (* (1+ k) p) n)))))))
        (setf (aref tiv k) (sqrt (+ (* real real) (* imag imag))))))
    tiv))

(defun chord-dissonance (chord)
  "Compute dissonance as the magnitude (norm) of the chord's TIV.
   Higher magnitude = higher dissonance (per MDPI 2020 model)."
  (let ((tiv (chord->tonal-interval-vector chord)))
    (sqrt (reduce #'+ tiv :key (lambda (x) (* x x))))))

(defun tonal-distance (chord1 chord2)
  "Euclidean distance between two chords in Tonal Interval Space.
   Measures perceptual dissimilarity."
  (let ((tiv1 (chord->tonal-interval-vector chord1))
        (tiv2 (chord->tonal-interval-vector chord2)))
    (sqrt (reduce #'+ (map 'vector (lambda (a b) (expt (- a b) 2)) tiv1 tiv2)))))

(defun key-distance (chord key)
  "Angular distance from chord to key in TIS.
   Measures diatonic membership / stability."
  (let* ((key-chord (build-chord (key-signature-root key)
                                 (if (eq (key-signature-mode key) :major)
                                     :major-seventh
                                     :minor-seventh)))
         (tiv-chord (chord->tonal-interval-vector chord))
         (tiv-key (chord->tonal-interval-vector key-chord)))
    ;; Angular distance
    (let ((dot-product (reduce #'+ (map 'vector #'* tiv-chord tiv-key)))
          (norm-chord (chord-dissonance chord))
          (norm-key (chord-dissonance key-chord)))
      (if (or (zerop norm-chord) (zerop norm-key))
          0.0d0
          (acos (/ dot-product (* norm-chord norm-key)))))))
