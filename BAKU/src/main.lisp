;;; main.lisp — BAKU メインエントリーポイント
(in-package :cl-user)

(defpackage :baku-main
  (:use :cl :baku-config :baku-word-pool :baku-mcp :baku-story)
  (:export :run
           :run-batch))

(in-package :baku-main)

(defun run (&key (noun-count 3)
              (verb-count 2)
              (adj-count 1)
              (pool-dir nil)
              (batch-count 1))
  "BAKU ショートショート生成 — 単一実行"
  (format t "~%")
  (format t "========================================~%")
  (format t " 爆（BAKU）— ショートショート生成~%")
  (format t "========================================~%~%")

  ;; 設定初期化
  (let ((base-dir (or pool-dir *default-pathname-defaults*)))
    (init-config base-dir)

    ;; 単語プール読み込み
    (let ((pools (load-all-pools *word-pool-dir*)))
      (format t "~%")

      ;; 単一 or バッチ実行
      (if (> batch-count 1)
          (run-batch :pools pools
                     :noun-count noun-count
                     :verb-count verb-count
                     :adj-count adj-count
                     :count batch-count)
          (let ((result (generate-story :pools pools
                                       :noun-count noun-count
                                       :verb-count verb-count
                                       :adj-count adj-count)))
            (format t "~%[BAKU] 生成完了~%")
            result)))))

(defun run-batch (&key pools noun-count verb-count adj-count (count 3))
  "バッチ実行モード"
  (format t "[BAKU] バッチモード: ~D 件のストーリーを生成~%~%" count)
  (loop for i from 1 to count do
    (format t "--- バッチ ~D/~D ---~%" i count)
    (generate-story :pools pools
                    :noun-count noun-count
                    :verb-count verb-count
                    :adj-count adj-count)
    (format t "~%"))
  (format t "[BAKU] バッチ処理完了: ~D 件~%" count))

;;; ========================================
;;; CLI エントリーポイント
;;; ========================================

;; sbcl --script main.lisp [-- noun-count verb-count adj-count batch-count]
(defun cli-main ()
  "コマンドライン引数を処理"
  (let* ((args sb-ext:*posix-argv*)
         (noun-count (parse-integer (or (nth 1 args) "3") :junk-allowed t))
         (verb-count (parse-integer (or (nth 2 args) "2") :junk-allowed t))
         (adj-count (parse-integer (or (nth 3 args) "1") :junk-allowed t))
         (batch-count (parse-integer (or (nth 4 args) "1") :junk-allowed t)))
    (run :noun-count (or noun-count 3)
         :verb-count (or verb-count 2)
         :adj-count (or adj-count 1)
         :batch-count (or batch-count 1))))

;; 直接実行時
(cli-main)
