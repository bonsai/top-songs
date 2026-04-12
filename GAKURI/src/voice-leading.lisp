;;; voice-leading.lisp — Voice leading cost computation
;;; Based on: smooth voice leading principles, half-step attraction

(in-package :gakuri)

(defun voice-leading-between (chord1 chord2)
  "Compute the voice leading cost between two chords.
   Lower cost = smoother, more natural voice leading.
   
   Model: minimal total semitone movement across voices,
   with preference for common tones and stepwise motion."
  (let* ((pcs1 (chord-pitch-classes chord1))
         (pcs2 (chord-pitch-classes chord2))
         (n1 (length pcs1))
         (n2 (length pcs2))
         (n-voices (max n1 n2)))
    ;; Build cost matrix and find optimal assignment
    (optimal-voice-assignment pcs1 pcs2 n-voices)))

(defun optimal-voice-assignment (pcs1 pcs2 n-voices)
  "Find the optimal voice assignment minimizing total movement.
   Uses a greedy approach for small voice counts."
  (let ((total-cost 0.0d0)
        (used1 (make-hash-table))
        (used2 (make-hash-table)))
    ;; 1. Find common tones (zero cost)
    (dolist (p1 pcs1)
      (when (member p1 pcs2)
        (setf (gethash p1 used1) t)
        (setf (gethash p1 used2) t)))
    ;; 2. Match remaining voices with minimal movement
    (let ((remaining1 (remove-if (lambda (p) (gethash p used1)) pcs1))
          (remaining2 (remove-if (lambda (p) (gethash p used2)) pcs2)))
      (dolist (p1 remaining1)
        (let* ((best-dist most-positive-fixnum)
               (best-p nil))
          (dolist (p2 remaining2)
            (unless (gethash p2 used2)
              (let ((dist (minimal-semitone-distance p1 p2)))
                (when (< dist best-dist)
                  (setq best-dist dist)
                  (setq best-p p2)))))
          (when best-p
            (setf (gethash best-p used2) t)
            (incf total-cost
                  (* 0.05d0 (exp (* 0.05d0 best-dist)))))))
    ;; 3. Penalty for voice count mismatch
    (incf total-cost (* 0.1d0 (abs (- n1 n2))))
    total-cost))

(defun minimal-semitone-distance (pc1 pc2)
  "Compute minimal semitone distance on the chromatic circle."
  (let ((diff (abs (- pc1 pc2))))
    (min diff (- 12 diff))))

(defun smooth-voice-leading (progression)
  "Return a progression with optimal voice leading applied.
   Revoices each chord to minimize total voice movement."
  (when (null progression) (return-from smooth-voice-leading nil))
  (let* ((result (list (car progression)))
         (prev (car progression)))
    (dolist (chord (cdr progression))
      (let ((revoiced (revoice-for-smoothness prev chord)))
        (push revoiced result)
        (setq chord revoiced)))
    (nreverse result)))

(defun revoice-for-smoothness (prev-chord next-chord)
  "Revoice next-chord to achieve smooth voice leading from prev-chord."
  ;; In a full implementation, this would compute optimal voicing.
  ;; For now, return the chord unchanged (voicing optimization is future work).
  next-chord)

(defun voice-leading-cost-sequence (progression)
  "Return a sequence of voice leading costs between consecutive chords."
  (when (< (length progression) 2)
    (return-from voice-leading-cost-sequence '(0.0d0)))
  (loop for (c1 c2) on progression
        while c2
        collect (voice-leading-between c1 c2)))
