;;; emotional-profiles.lisp — Emotional tension curve templates
;;; Based on: Herremans & Chuan (2020) Experiment 2 — 5 prototypical tension curves
;;; Extended for jazz-specific emotional categories

(in-package :gakuri)

(defparameter *emotional-profiles*
  "Target tension curves for different emotional moods.
   Each profile is a list of normalized tension values [0, 1].
   Based on listener-selected prototypical emotional trajectories."
  `((:ballad . ,(generate-profile :descending 12 :peak 0.3d0 :depth 0.8d0))
    (:bebop . ,(generate-profile :fluctuating 16 :peak 0.9d0 :depth 0.2d0))
    (:melancholic . ,(generate-profile :concave 10 :peak 0.7d0 :depth 0.3d0))
    (:uplifting . ,(generate-profile :ascending 12 :peak 0.2d0 :depth 0.85d0))
    (:yearning . ,(generate-profile :convex 10 :peak 0.85d0 :depth 0.2d0))
    (:noir . ,(generate-profile :ascending 14 :peak 0.1d0 :depth 0.95d0))
    (:neo-soul . ,(generate-profile :fluctuating 12 :peak 0.6d0 :depth 0.35d0))
    (:peaceful . ,(generate-profile :descending 8 :peak 0.2d0 :depth 0.9d0))
    (:dramatic . ,(generate-profile :convex 16 :peak 0.95d0 :depth 0.1d0))
    (:bittersweet . ,(generate-profile :concave 12 :peak 0.5d0 :depth 0.55d0))))

(defun generate-profile (type length &key (peak 0.5d0) (depth 0.5d0))
  "Generate a tension curve of given type and length.
   peak: maximum tension value, depth: minimum tension value."
  (let ((curve (make-list length)))
    (dotimes (i length)
      (let ((t (/ i (max 1 (1- length)))))  ; normalized position [0, 1]
        (setf (nth i curve)
              (ecase type
                (:ascending (+ depth (* (- peak depth) t)))
                (:descending (- peak (* (- peak depth) t)))
                (:convex
                 ;; Arch: rises to middle, then falls
                 (let ((arch (* 4 t (- 1 t))))  ; parabolic arch, peak at 0.5
                   (+ depth (* (- peak depth) arch))))
                (:concave
                 ;; Valley: falls to middle, then rises
                 (let ((valley (- 1 (* 4 t (- 1 t)))))
                  (+ depth (* (- peak depth) valley))))
                (:fluctuating
                 ;; Oscillating: sinusoidal
                 (+ (* 0.5d0 (+ peak depth))
                    (* 0.5d0 (- peak depth)
                       (sin (* 3 pi t)))))
                (:flat
                 (float (/ (+ peak depth) 2) 0.0d0))))))
    curve))

;;; Convenience accessors
(defun profile-ballad () (cdr (assoc :ballad *emotional-profiles*)))
(defun profile-bebop () (cdr (assoc :bebop *emotional-profiles*)))
(defun profile-melancholic () (cdr (assoc :melancholic *emotional-profiles*)))
(defun profile-uplifting () (cdr (assoc :uplifting *emotional-profiles*)))
(defun profile-yearning () (cdr (assoc :yearning *emotional-profiles*)))
(defun profile-noir () (cdr (assoc :noir *emotional-profiles*)))
(defun profile-neo-soul () (cdr (assoc :neo-soul *emotional-profiles*)))

(defun match-profile-to-progression (progression key profile)
  "Compute how well a progression matches a target emotional profile.
   Returns RMSE (root mean square error) — lower is better."
  (let* ((states (compute-tension-curve progression key))
         (actual (tension-curve-normalized states))
         (target profile)
         (n (min (length actual) (length target)))
         (mse (/ (loop for i below n
                       sum (expt (- (nth i actual) (nth i target)) 2))
                 n)))
    (sqrt mse)))
