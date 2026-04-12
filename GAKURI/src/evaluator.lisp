;;; evaluator.lisp — Progression quality evaluation
;;; Multi-metric assessment: smoothness, functional coherence, emotional score

(in-package :gakuri)

(defstruct evaluation-result
  "Complete evaluation of a chord progression."
  (progression nil)
  (key nil)
  (smoothness 0.0d0)
  (functional-coherence 0.0d0)
  (tension-arc :unknown)
  (emotional-score 0.0d0)
  (complexity 0.0d0)
  (novelty 0.0d0)
  (overall 0.0d0)
  (details nil))

(defun evaluate-progression (progression key)
  "Comprehensive evaluation of a chord progression.
   
   Metrics:
   1. Smoothness: voice leading quality (lower total movement = better)
   2. Functional coherence: adherence to functional harmony rules
   3. Tension arc: shape of the tension curve
   4. Emotional score: composite of above + tension profile match
   5. Complexity: harmonic richness (extensions, alterations)
   6. Novelty: deviation from common patterns"
  (let* ((states (compute-tension-curve progression key))
         (vl-costs (voice-leading-cost-sequence progression))
         (smooth (smoothness-score vl-costs))
         (func-coh (functional-coherence progression key))
         (tension-arc (tension-arc-type states))
         (complexity (complexity-score progression))
         (novelty (novelty-score progression key))
         (emotional (emotional-score smooth func-coh tension-arc complexity)))
    (make-evaluation-result
     :progression progression
     :key key
     :smoothness smooth
     :functional-coherence func-coh
     :tension-arc tension-arc
     :emotional-score emotional
     :complexity complexity
     :novelty novelty
     :overall (* 0.25d0 smooth
                 0.25d0 func-coh
                 0.25d0 emotional
                 0.15d0 complexity
                 0.10d0 novelty)
     :details (list :tension-states states
                    :voice-leading-costs vl-costs
                    :tension-curve (tension-curve-normalized states)))))

(defun smoothness-score (vl-costs)
  "Score voice leading smoothness on [0, 1].
   Lower total voice leading cost = higher smoothness score."
  (if (null vl-costs)
      1.0d0
      (let* ((avg-cost (/ (reduce #'+ vl-costs) (length vl-costs)))
             ;; Exponential decay: cost of 0 = score 1.0, high cost → 0
             (score (exp (* -0.5d0 avg-cost))))
        (min 1.0d0 (max 0.0d0 score)))))

(defun functional-coherence (progression key)
  "Score how well the progression follows functional harmony rules.
   [0, 1] — 1.0 = perfect adherence to jazz functional harmony."
  (if (< (length progression) 2)
      1.0d0
      (let* ((total-transitions (1- (length progression)))
             (valid-transitions 0))
        (loop for (c1 c2) on progression
              while c2
              for func1 = (harmonic-function c1 key)
              for func2 = (harmonic-function c2 key)
              for valid = (valid-transition-p func1 func2)
              when valid do (incf valid-transitions))
        (/ valid-transitions total-transitions))))

(defun harmonic-function (chord key)
  "Determine the harmonic function of a chord relative to the key."
  (let* ((root (chord-root chord))
         (key-root (key-signature-root key))
         (degree (mod (- root key-root) 12)))
    (cond
      ((member degree '(0)) :tonic)
      ((member degree '(2)) :supertonic)
      ((member degree '(4)) :mediant)
      ((member degree '(5)) :subdominant)
      ((member degree '(7)) :dominant)
      ((member degree '(9)) :submediant)
      ((member degree '(11)) :leading-tone)
      (t :other))))

(defun valid-transition-p (from-func to-func)
  "Check if a harmonic transition is valid per jazz harmony rules."
  (let ((transitions (cdr (assoc from-func *functional-transitions*))))
    (when transitions
      (> (or (cdr (assoc to-func transitions)) 0) 0))))

(defun tension-arc-type (tension-states)
  "Classify the tension arc shape.
   Based on: ascending, descending, convex (arch), concave (valley), fluctuating."
  (let* ((curve (tension-curve-normalized tension-states))
         (n (length curve)))
    (if (< n 3)
        :flat
        (let* ((first-val (first curve))
               (last-val (car (last curve)))
               (mid-idx (floor n 2))
               (mid-val (nth mid-idx curve))
               (avg (/ (reduce #'+ curve) n))
               (trend (- last-val first-val)))
          (cond
            ;; Ascending: clear upward trend
            ((> trend 0.3d0) :ascending)
            ;; Descending: clear downward trend
            ((< trend -0.3d0) :descending)
            ;; Convex (arch): tension rises then falls
            ((and (> mid-val first-val) (> mid-val last-val)) :convex)
            ;; Concave (valley): tension falls then rises
            ((and (< mid-val first-val) (< mid-val last-val)) :concave)
            ;; Fluctuating: multiple direction changes
            ((> (count-direction-changes curve) 2) :fluctuating)
            (t :flat))))))

(defun count-direction-changes (curve)
  "Count the number of direction changes in a tension curve."
  (let ((changes 0)
        (prev-dir 0))
    (loop for (a b) on curve
          while b
          for dir = (cond ((> b a) 1) ((< b a) -1) (t 0))
          when (and (/= dir 0) (/= prev-dir 0) (/= dir prev-dir))
            do (incf changes)
          do (setq dir (if (= dir 0) prev-dir dir))
          do (setq prev-dir dir))
    changes))

(defun complexity-score (progression)
  "Score harmonic complexity [0, 1].
   Based on extensions, alterations, and chord type variety."
  (if (null progression)
      0.0d0
      (let* ((ext-count (reduce #'+ progression
                                :key (lambda (c) (length (chord-extensions c)))))
             (alt-count (reduce #'+ progression
                                :key (lambda (c) (length (chord-alterations c)))))
             (n (length progression))
             (avg-extensions (/ ext-count n))
             (avg-alterations (/ alt-count n))
             ;; Jazz complexity: moderate extensions + some alterations
             (score (+ (* 0.4d0 (min 1.0d0 (/ avg-extensions 3.0d0)))
                       (* 0.6d0 (min 1.0d0 (/ avg-alterations 2.0d0))))))
        (min 1.0d0 (max 0.0d0 score)))))

(defun novelty-score (progression key)
  "Score novelty (deviation from common patterns) [0, 1].
   Higher = more unexpected but still musically valid."
  (if (< (length progression) 2)
      0.0d0
      (let* ((vl-costs (voice-leading-cost-sequence progression))
             (avg-vl (/ (reduce #'+ vl-costs) (length vl-costs)))
             ;; Novelty: some unexpected transitions (not too smooth, not chaotic)
             (novelty (cond
                        ((< avg-vl 0.5d0) 0.3d0)    ; too predictable
                        ((< avg-vl 2.0d0) 0.7d0)    ; good balance
                        (t 0.5d0))))                ; too chaotic
        novelty)))

(defun emotional-score (smoothness func-coherence tension-arc complexity)
  "Composite emotional resonance score [0, 1].
   
   The 'エモい' formula:
   - Smoothness: provides warmth and flow
   - Functional coherence: provides sense of direction
   - Tension arc: provides emotional trajectory
   - Complexity: provides richness without overwhelming"
  (let* ((arc-bonus (case tension-arc
                      (:convex 0.15d0)     ; arch = classic emotional arc
                      (:ascending 0.10d0)  ; building tension
                      (:descending 0.10d0) ; resolution
                      (:fluctuating 0.05d0)
                      (:concave 0.08d0)    ; tension valley
                      (t 0.0d0)))
         (base (+ (* 0.30d0 smoothness)
                  (* 0.25d0 func-coherence)
                  (* 0.25d0 complexity)
                  arc-bonus)))
    (min 1.0d0 (max 0.0d0 base))))
