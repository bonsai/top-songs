;;; database.lisp — Progression storage and retrieval

(in-package :gakuri)

(defparameter *progression-db* nil
  "In-memory database of generated progressions with evaluations.")

(defstruct progression-entry
  "A stored progression with metadata."
  (id 0 :type integer)
  (progression nil)
  (key nil)
  (mood nil)
  (evaluation nil)
  (timestamp nil)
  (tags nil)
  (rating 0.0d0))

(defun save-progression (entry &key (db *progression-db*))
  "Save a progression entry to the database."
  (push entry db)
  (setf *progression-db* db)
  entry)

(defun load-progressions (&key (db *progression-db*))
  "Return all stored progressions."
  db)

(defun query-by-mood (mood &key (db *progression-db*))
  "Find all progressions tagged with a given mood."
  (remove-if-not (lambda (entry) (eq (progression-entry-mood entry) mood))
                 db))

(defun query-by-tension-arc (arc-type &key (db *progression-db*))
  "Find all progressions with a given tension arc type."
  (remove-if-not (lambda (entry)
                   (let ((eval (progression-entry-evaluation entry)))
                     (when eval
                       (eq (evaluation-result-tension-arc eval) arc-type))))
                 db))

(defun top-rated (&key (n 10) (db *progression-db*))
  "Return the top N rated progressions."
  (subseq (sort (copy-list db) #'> :key #'progression-entry-rating)
          0 (min n (length db))))

(defun store-evaluated-progression (progression key mood evaluation &key (tags nil))
  "Convenience: evaluate and store a progression."
  (let* ((id (if *progression-db*
                 (1+ (progression-entry-id (first *progression-db*)))
                 1))
         (entry (make-progression-entry
                 :id id
                 :progression progression
                 :key key
                 :mood mood
                 :evaluation evaluation
                 :timestamp (get-universal-time)
                 :tags tags
                 :rating (evaluation-result-overall evaluation))))
    (save-progression entry)))
