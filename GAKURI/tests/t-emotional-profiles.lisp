;;; t-emotional-profiles.lisp — Tests for emotional profiles
(in-package :gakuri/tests)

(deftest test-profile-generation
  (dolist (type '(:ascending :descending :convex :concave :fluctuating :flat))
    (let ((profile (generate-profile type 8)))
      (ok (= (length profile) 8))
      (ok (every (lambda (x) (and (>= x 0.0d0) (<= x 1.0d0))) profile)))))

(deftest test-profile-accessors
  (ok (consp (profile-ballad)))
  (ok (consp (profile-bebop)))
  (ok (consp (profile-melancholic)))
  (ok (consp (profile-yearning)))
  (ok (consp (profile-noir)))
  (ok (consp (profile-neo-soul))))

(deftest test-profile-match
  (let* ((key (make-key-signature :root 0 :mode :major))
         (progression (list (build-chord 2 :minor-seventh)
                            (build-chord 7 :dominant)
                            (build-chord 0 :major-seventh)))
         (ballad-profile (profile-ballad))
         (match (match-profile-to-progression progression key ballad-profile)))
    (ok (>= match 0.0d0))
    (ok (<= match 1.0d0))))

(deftest test-progression-for-mood
  (let ((key (make-key-signature :root 0 :mode :major)))
    (dolist (mood '(:ballad :yearning :noir :neo-soul))
      (let ((result (progression-for-mood key :mood mood :length 8)))
        (ok (getf result :progression))
        (ok (getf result :tension-curve))
        (ok (numberp (getf result :match-score)))))))
