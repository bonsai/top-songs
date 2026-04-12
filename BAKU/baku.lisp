;; ╔══════════════════════════════════════════════════════════╗
;; ║  DEPRECATED: use baku-mcp (Go) instead                  ║
;; ║  New MCP Server: MEGA/MCP/baku-mcp/                     ║
;; ║  This file is kept for reference only.                   ║
;; ║  See: MEGA/MCP/adr-baku-lisp-wrapper.md §5               ║
;; ╚══════════════════════════════════════════════════════════╝
;; baku.lisp — 爆（ショートショート生成エージェント）
;; Random Word Short Story Generator via MCP + Python
;; Python実装は別担当が担当／このファイルはSBCL用エントリーポイント

(in-package :cl-user)

(defpackage :baku
  (:use :cl)
  (:export :generate-story
           :load-word-pool
           :select-words
           :run-mcp-connector))

(in-package :baku)

;;; ========================================
;;; 設定
;;; ========================================

(defparameter *word-pool-dir*
  (merge-pathnames "word_pools/" *load-truename*)
  "単語リストが格納されたディレクトリ")

(defparameter *mcp-endpoint*
  "http://localhost:8765/mcp"
  "MCPサーバーのエンドポイント")

(defparameter *story-output-dir*
  (merge-pathnames "output/" *load-truename*)
  "生成されたショートショットの保存先")

;;; ========================================
;;; 単語プール読み込み
;;; ========================================

(defun load-word-pool (filename)
  "単語リストファイルを行単位で読み込み、リストとして返す"
  (let ((filepath (merge-pathnames filename *word-pool-dir*))
        (words '()))
    (with-open-file (stream filepath :direction :input :if-does-not-exist nil)
      (when stream
        (loop for line = (read-line stream nil nil)
              while line
              unless (string= line "")
                do (push (string-trim " " line) words))))
    (nreverse words)))

;;; ========================================
;;; ランダム単語選択
;;; ========================================

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
  (append (subseq list 0 index)
          (subseq list (1+ index))))

;;; ========================================
;;; MCPコネクタ（Python側と連携）
;;; ========================================

(defun run-mcp-connector (themes)
  "Python MCPコネクタを外部呼び出ししてストーリー生成"
  (let ((prompt (format nil "Create a short story using these ~D themes: ~{~A~^, ~}"
                        (length themes) themes)))
    ;; Pythonスクリプトを外部呼び出し
    (let ((script-path (merge-pathnames "scripts/story_generator.py"
                                        (directory-namestring *load-truename*))))
      (format t "~%[BAKU] MCPコネクタ起動: ~A~%" script-path)
      (format t "[BAKU] プロンプト: ~A~%" prompt)
      ;; 実際のMCP通信はPython側で実装
      (run-program "python" (list (namestring script-path)
                                  "--themes" (format nil "~{~A~^,~}" themes))
                   :output t
                   :wait t))))

;;; ========================================
;;; ストーリー生成（メイン）
;;; ========================================

(defun generate-story (&key (noun-count 3)
                         (verb-count 2)
                         (adj-count 1)
                         (output-file nil))
  "単語をランダム選択 → MCP経由でストーリー生成 → 保存"
  (format t "~%========================================~%")
  (format t " 爆（BAKU）— ショートショート生成~%")
  (format t "========================================~%~%")

  ;; 単語プール読み込み
  (let ((nouns (load-word-pool "nouns.txt"))
        (verbs (load-word-pool "verbs.txt"))
        (adjs  (load-word-pool "adjectives.txt")))

    (format t "[1/3] 単語プール読み込み完了: 名詞=~D, 動詞=~D, 形容詞=~D~%"
            (length nouns) (length verbs) (length adjs))

    ;; ランダム選択
    (let* ((selected-nouns (select-words nouns noun-count))
           (selected-verbs (select-words verbs verb-count))
           (selected-adjs  (select-words adjs adj-count))
           (all-themes (append selected-nouns selected-verbs selected-adjs)))

      (format t "[2/3] 選択されたテーマ: ~{~A~^, ~}~%" all-themes)

      ;; MCP経由でストーリー生成
      (run-mcp-connector all-themes)

      (format t "[3/3] 生成完了~%~%")
      (values all-themes)))))

;;; ========================================
;;; エントリーポイント
;;; ========================================

;; SBCL --script baku.lisp で直接実行可能
(defun main ()
  "コマンドラインからのエントリーポイント"
  (generate-story :noun-count 3
                  :verb-count 2
                  :adj-count 1))

;; 実行: sbcl --script baku.lisp
(main)
