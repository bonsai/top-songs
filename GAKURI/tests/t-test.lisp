;;; t-test.lisp — Unit tests for music theory module

(in-package :gakuri/tests)

(deftest test-pitch-class-mapping
  (ok (= (cdr (assoc "C" *pitch-classes* :test #'string=)) 0))
  (ok (= (cdr (assoc "G" *pitch-classes* :test #'string=)) 7))
  (ok (= (cdr (assoc "B" *pitch-classes* :test #'string=)) 11)))

(deftest test-build-chord
  (let ((c (build-chord 0 :major-seventh :extensions '(9 7M) :voicing :drop2)))
    (ok (= (chord-root c) 0))
    (ok (eq (chord-type c) :major-seventh))
    (ok (equal (chord-extensions c) '(9 7M)))
    (ok (eq (chord-voicing c) :drop2))))

(deftest test-chord-pitch-classes
  (let ((c (build-chord 0 :major)))
    (ok (equal (chord-pitch-classes c) '(0 4 7)))))

(deftest test-chord-dissonance
  (let ((major (build-chord 0 :major-seventh))
        (dom7 (build-chord 7 :dominant :alterations '(b9 #11))))
    ;; Altered dominant should be more dissonant than major seventh
    (ok (> (chord-dissonance dom7) (chord-dissonance major)))))

(deftest test-tonal-distance
  (let ((c1 (build-chord 0 :major-seventh))
        (c2 (build-chord 0 :major-seventh))
        (c3 (build-chord 6 :dominant :alterations '(b9 #11))))
    (ok (= (tonal-distance c1 c2) 0.0d0))  ; identical chords
    (ok (> (tonal-distance c1 c3) 0.0d0))))  ; different chords

(deftest test-key-distance
  (let ((key (make-key-signature :root 0 :mode :major))
        (tonic (build-chord 0 :major-seventh))
        (dominant (build-chord 7 :dominant)))
    ;; Tonic should be closer to key than dominant
    (ok (< (key-distance tonic key) (key-distance dominant key)))))
