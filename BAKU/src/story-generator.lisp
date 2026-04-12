;;; story-generator.lisp — ストーリー生成モジュール
(in-package :cl-user)

(defpackage :baku-story
  (:use :cl :baku-config :baku-word-pool :baku-mcp)
  (:export :generate-story
           :save-story
           :build-prompt))

(in-package :baku-story)

(defun build-prompt (themes)
  "選択されたテーマからプロンプトを構築"
  (format nil *prompt-template*
          (length themes)
          themes))

(defun save-story (story-text themes)
  "生成されたストーリーをファイルに保存"
  (let* ((timestamp (format nil "~4,'0D~2,'0D~2,'0D_~2,'0D~2,'0D~2,'0D"
                            (sb-unix::unix-time)))
         (filename (format nil "story_~A.txt" timestamp))
         (filepath (merge-pathnames filename *story-output-dir*)))
    (with-open-file (stream filepath
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (format stream "=== ショートショート（爆） ===~%")
      (format stream "生成日時: ~A~%~%" timestamp)
      (format stream "使用テーマ: ~{~A~^, ~}~%~%" themes)
      (format stream "~A~%" story-text))
    (format t "[STORY] 保存完了: ~A~%" filepath)
    filepath))

(defun generate-story (&key (noun-count *default-noun-count*)
                         (verb-count *default-verb-count*)
                         (adj-count *default-adj-count*)
                         (pools nil))
  "ストーリー生成のメインロジック"
  (unless pools
    (error "単語プールが設定されていません"))

  ;; 単語選択
  (let* ((nouns (gethash "nouns" pools))
         (verbs (gethash "verbs" pools))
         (adjs (gethash "adjectives" pools))
         (selected-nouns (select-words nouns noun-count))
         (selected-verbs (select-words verbs verb-count))
         (selected-adjs (select-words adjs adj-count))
         (all-themes (append selected-nouns selected-verbs selected-adjs)))

    (format t "[STORY] 選択テーマ: ~{~A~^, ~}~%" all-themes)

    ;; プロンプト構築
    (let ((prompt (build-prompt all-themes)))
      (format t "[STORY] プロンプト構築完了~%")

      ;; MCP経由で生成
      (connect-mcp *mcp-endpoint*)
      (send-prompt prompt)
      (let ((story (receive-response)))
        (disconnect-mcp)

        ;; 保存
        (when story
          (save-story story all-themes))

        (values story all-themes)))))
