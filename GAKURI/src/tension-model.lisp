;;; tension-model.lisp — Tonal tension computation
;;; Based on: Herremans & Chuan (2020) "A Computational Model of Tonal Tension"
;;; MDPI Entropy 22(11):1291

(in-package :gakuri)

(defparameter *tension-weights*
  "Empirically optimized weights from Herremans & Chuan (2020).
   Sum to 1.0. Dissonance dominates, followed by hierarchical structure."
  '(:dissonance 0.402d0
    :hierarchical 0.246d0
    :tonal-distance 0.202d0
    :voice-leading 0.193d0))

(defstruct tension-state
  "Captures the tension state of a chord within a progression."
  (chord nil)
  (key nil)
  (dissonance 0.0d0)
  (tonal-dist 0.0d0)
  (voice-leading-cost 0.0d0)
  (hierarchical 0.0d0)
  (total 0.0d0)
  (previous nil))

(defun compute-tension (chord key &key (previous-chord nil) (previous-key nil))
  "Compute the instantaneous tension of a chord within a key context.
   
   M(T_i, P) = ω₁·d_key + ω₂·c + ω₃·m + ω₄·h
   
   where:
   - d_key: angular distance to the key (diatonic stability)
   - c: dissonance (TIV magnitude)
   - m: voice leading cost (smoothness of transition)
   - h: hierarchical tension (functional dependency depth)"
  (let* ((dissonance (chord-dissonance chord))
         (tonal-dist (key-distance chord key))
         (vl-cost (if previous-chord
                      (voice-leading-between previous-chord chord)
                      0.0d0))
         (hier (hierarchical-tension chord key))
         (w-d (getf *tension-weights* :dissonance))
         (w-h (getf *tension-weights* :hierarchical))
         (w-td (getf *tension-weights* :tonal-distance))
         (w-vl (getf *tension-weights* :voice-leading))
         (total (+ (* w-td tonal-dist)
                   (* w-d dissonance)
                   (* w-vl vl-cost)
                   (* w-h hier))))
    (make-tension-state :chord chord
                        :key key
                        :dissonance dissonance
                        :tonal-dist tonal-dist
                        :voice-leading-cost vl-cost
                        :hierarchical hier
                        :total total
                        :previous previous-chord)))

(defun hierarchical-tension (chord key)
  "Compute hierarchical tension based on functional grammar depth.
   Based on Rohrmeier's generative grammar for tonal harmony.
   
   Functional hierarchy (shallow → deep):
   - Tonic (I, vi): depth 0 — most stable
   - Subdominant (IV, ii): depth 1 — moderate tension
   - Dominant (V, vii°): depth 2 — high tension
   - Secondary dominant / altered: depth 3 — very high tension
   - Tritone substitution / modal interchange: depth 4 — maximum tension"
  (let* ((root (chord-root chord))
         (key-root (key-signature-root key))
         (scale-degree (mod (- root key-root) 12))
         (type (chord-type chord)))
    (cond
      ;; Tonic function
      ((or (= scale-degree 0)
           (and (= scale-degree 9) (member type '(:minor :minor-seventh))))
       0.0d0)
      ;; Subdominant function
      ((or (= scale-degree 5)
           (and (= scale-degree 2) (member type '(:minor :minor-seventh))))
       0.25d0)
      ;; Dominant function
      ((or (= scale-degree 7)
           (and (= scale-degree 11) (eq type :half-diminished)))
       0.5d0)
      ;; Secondary dominant / altered
      ((and (eq type :dominant)
            (not (= scale-degree 7)))
       0.75d0)
      ;; Tritone sub / modal interchange
      ((or (member :b5 (chord-alterations chord))
           (member :b9 (chord-alterations chord))
           (member :#11 (chord-alterations chord)))
       1.0d0)
      (t 0.5d0))))

(defun compute-tension-curve (progression key)
  "Compute the tension curve for an entire progression.
   Returns a list of tension-state structs."
  (let ((states nil)
        (prev nil))
    (dolist (chord progression)
      (let ((state (compute-tension chord key :previous-chord prev)))
        (push state states)
        (setq prev chord)))
    (nreverse states)))

(defun tension-curve-normalized (states)
  "Normalize tension curve to [0, 1] range."
  (let* (values (max-t 0.0d0) (min-t 0.0d0))
    (dolist (s states)
      (push (tension-state-total s) values)
      (setq max-t (max max-t (tension-state-total s)))
      (setq min-t (min min-t (tension-state-total s))))
    (let ((range (- max-t min-t)))
      (if (zerop range)
          (mapcar (constantly 0.5d0) states)
          (mapcar (lambda (s) (/ (- (tension-state-total s) min-t) range))
                  states)))))
