;;; word-pool.lisp — 単語プール管理モジュール
(in-package :cl-user)

(defpackage :baku-word-pool
  (:use :cl)
  (:export :load-word-pool
           :load-all-pools
           :select-words
           :remove-at
           :get-pool-stats))

(in-package :baku-word-pool)

(defun load-word-pool (filepath)
  "単語リストファイルを行単位で読み込み、リストとして返す"
  (let ((words '()))
    (with-open-file (stream filepath :direction :input :if-does-not-exist nil)
      (when stream
        (loop for line = (read-line stream nil nil)
              while line
              unless (string= line "")
                do (push (string-trim '(#\Space #\Tab #\Return #\Linefeed) line) words))))
    (nreverse words)))

(defun load-all-pools (pool-dir &key (noun-file "nouns.txt")
                                    (verb-file "verbs.txt")
                                    (adj-file "adjectives.txt")
                                    (setting-file "settings.txt")
                                    (emotion-file "emotions.txt"))
  "全ての単語プールを一括読み込み"
  (let ((pools (make-hash-table :test 'equal)))
    (dolist (pair (list (cons "nouns" noun-file)
                        (cons "verbs" verb-file)
                        (cons "adjectives" adj-file)
                        (cons "settings" setting-file)
                        (cons "emotions" emotion-file)))
      (let* ((category (car pair))
             (filename (cdr pair))
             (filepath (merge-pathnames filename pool-dir))
             (words (load-word-pool filepath)))
        (setf (gethash category pools) words)
        (format t "[WORD-POOL] ~A: ~D 単語読み込み~%" category (length words))))
    pools))

(defun select-words (pool &optional (count 3))
  "単語プールからランダムにcount個の単語を選択（重複なし）"
  (let* ((available (copy-list pool))
         (n (min count (length available)))
         (selected '()))
    (loop repeat n do
      (let ((idx (random (length available))))
        (push (nth idx available) selected)
        (setf available (remove-at available idx))))
    (nreverse selected)))

(defun remove-at (list index)
  "リストから指定インデックスの要素を削除"
  (append (subseq list 0 index)
          (subseq list (1+ index))))

(defun get-pool-stats (pools)
  "単語プールの統計情報を返す"
  (let ((stats '()))
    (maphash (lambda (key value)
               (push (cons key (length value)) stats))
             pools)
    stats))
