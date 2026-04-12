;;; t-evaluator.lisp — Tests for evaluator
(in-package :gakuri/tests)

(deftest test-smoothness-score
  (let ((low-cost '(0.1d0 0.2d0 0.15d0))
        (high-cost '(5.0d0 6.0d0 4.0d0)))
    (ok (> (smoothness-score low-cost) (smoothness-score high-cost)))
    (ok (<= (smoothness-score low-cost) 1.0d0))
    (ok (>= (smoothness-score high-cost) 0.0d0))))

(deftest test-functional-coherence
  (let ((key (make-key-signature :root 0 :mode :major))
        (good-prog (list (build-chord 2 :minor-seventh)  ; ii
                         (build-chord 7 :dominant)       ; V
                         (build-chord 0 :major-seventh))) ; I
        (bad-prog (list (build-chord 0 :major-seventh)
                        (build-chord 6 :dominant)         ; tritone sub, unusual
                        (build-chord 3 :major))))
    (ok (> (functional-coherence good-prog key)
           (functional-coherence bad-prog key)))))

(deftest test-tension-arc-classification
  (let* ((key (make-key-signature :root 0 :mode :major))
         ;; Create an ascending tension curve
         (asc-states (loop for i below 8
                           collect (make-tension-state
                                    :total (float (* 0.1d0 (1+ i)) 0.0d0))))
         (arc (tension-arc-type asc-states)))
    (ok (eq arc :ascending))))

(deftest test-emotional-score-bounds
  (let ((score (emotional-score 0.8d0 0.7d0 :convex 0.5d0)))
    (ok (<= 0.0d0 score 1.0d0))))
