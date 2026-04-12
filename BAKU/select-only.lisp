;; select-only.lisp — 単語選択のみを行うSBCLスクリプト
;; Usage: sbcl --script select-only.lisp -- <word-pool-dir> <noun-count> <verb-count> <adj-count>
;; Output: JSON on stdout
;;   {"nouns":["...","..."],"verbs":["...","..."],"adjectives":["..."]}

(in-package :cl-user)

;; baku.lisp を読み込み
(load #p"baku.lisp")

(in-package :baku)

(defun main ()
  (let* ((args *posix-argv*)
         ;; *posix-argv* => ("sbcl" "--script" "select-only.lisp" "--" "dir" "3" "2" "1")
         (dir-start (position "--" args :test #'string=))
         (word-pool-dir (if dir-start (nth (1+ dir-start) args) nil))
         (noun-count  (if dir-start (parse-integer (nth (+ 2 dir-start) args) :junk-allowed t) 3))
         (verb-count  (if dir-start (parse-integer (nth (+ 3 dir-start) args) :junk-allowed t) 2))
         (adj-count   (if dir-start (parse-integer (nth (+ 4 dir-start) args) :junk-allowed t) 1)))

    (unless word-pool-dir
      (format *error-output* "Usage: sbcl --script select-only.lisp -- <word-pool-dir> [noun-count] [verb-count] [adj-count]~%")
      (sb-ext:exit :code 1))

    ;; 単語プールディレクトリを設定
    (setf *word-pool-dir* (merge-pathnames (make-pathname :directory (pathname-directory word-pool-dir))
                                           (make-pathname :directory (pathname-relative-directory word-pool-dir))))

    ;; 各カテゴリの単語を読み込み
    (let* ((nouns (load-word-pool "nouns.txt"))
           (verbs (load-word-pool "verbs.txt"))
           (adjs  (load-word-pool "adjectives.txt"))
           (selected-nouns (select-words nouns noun-count))
           (selected-verbs (select-words verbs verb-count))
           (selected-adjs  (select-words adjs adj-count)))

      ;; JSON出力（手抜きJSONシリアライズ）
      (format t "{")
      (format t "\"nouns\":[~{~S~^,~}]," selected-nouns)
      (format t "\"verbs\":[~{~S~^,~}]," selected-verbs)
      (format t "\"adjectives\":[~{~S~^,~}]" selected-adjs)
      (format t "}~%")
      (force-output t))))

(main)
