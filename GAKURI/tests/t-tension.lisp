;;; t-tension.lisp — Tests for tension model
(in-package :gakuri/tests)

(deftest test-tension-computation
  (let ((key (make-key-signature :root 0 :mode :major))
        (chord (build-chord 0 :major-seventh)))
    (let ((state (compute-tension chord key)))
      (ok (>= (tension-state-total state) 0.0d0)))))

(deftest test-tension-curve
  (let ((key (make-key-signature :root 0 :mode :major))
        (progression (list (build-chord 2 :minor-seventh)
                           (build-chord 7 :dominant)
                           (build-chord 0 :major-seventh))))
    (let ((states (compute-tension-curve progression key)))
      (ok (= (length states) 3)))))

(deftest test-normalized-curve
  (let* ((key (make-key-signature :root 0 :mode :major))
         (states (compute-tension-curve
                  (list (build-chord 0 :major-seventh)
                        (build-chord 7 :dominant)
                        (build-chord 0 :major-seventh))
                  key))
         (normalized (tension-curve-normalized states)))
    (ok (every (lambda (x) (<= 0.0d0 x 1.0d0)) normalized))))
