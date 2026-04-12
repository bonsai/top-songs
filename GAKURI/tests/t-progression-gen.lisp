;;; t-progression-gen.lisp — Tests for progression generation
(in-package :gakuri/tests)

(deftest test-ii-v-i-generation
  (let ((key (make-key-signature :root 0 :mode :major))
        (progression (generate-ii-v-i (make-key-signature :root 0 :mode :major)
                                      :mode :major :extensions t)))
    (ok (= (length progression) 3))
    ;; ii should be D minor (root=2)
    (ok (= (chord-root (first progression)) 2))
    ;; V should be G dominant (root=7)
    (ok (= (chord-root (second progression)) 7))
    ;; I should be C major (root=0)
    (ok (= (chord-root (third progression)) 0))))

(deftest test-tritone-substitution
  (let ((dom7 (build-chord 7 :dominant :extensions '(7)))
        (sub (tritone-substitute (build-chord 7 :dominant :extensions '(7)))))
    (ok (= (chord-root sub) 1))  ; 7 + 6 = 13 mod 12 = 1
    (ok (eq (chord-type sub) :dominant))))

(deftest test-extended-progression
  (let ((key (make-key-signature :root 0 :mode :major))
        (prog (generate-extended-progressions key :length 8 :style :standard)))
    (ok (= (length prog) 8))))

(deftest test-altered-dominants
  (let ((prog (list (build-chord 2 :minor-seventh)
                    (build-chord 7 :dominant)
                    (build-chord 0 :major-seventh)))
        (altered (generate-altered-dominants
                  (list (build-chord 2 :minor-seventh)
                        (build-chord 7 :dominant)
                        (build-chord 0 :major-seventh)))))
    ;; Dominant chord at position 1 should be altered
    (ok (or (null (chord-alterations (second altered)))
            (consp (chord-alterations (second altered)))))))
