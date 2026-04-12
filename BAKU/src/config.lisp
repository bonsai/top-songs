;;; config.lisp — BAKU 設定モジュール
(in-package :cl-user)

(defpackage :baku-config
  (:use :cl)
  (:export *word-pool-dir*
           *mcp-endpoint*
           *story-output-dir*
           *default-noun-count*
           *default-verb-count*
           *default-adj-count*
           *prompt-template*
           :init-config))

(in-package :baku-config)

(defparameter *word-pool-dir* nil
  "単語リストが格納されたディレクトリ")

(defparameter *mcp-endpoint* "http://localhost:8765/mcp"
  "MCPサーバーのエンドポイント")

(defparameter *story-output-dir* nil
  "生成されたショートショットの保存先")

(defparameter *default-noun-count* 3
  "デフォルトの名詞選択数")

(defparameter *default-verb-count* 2
  "デフォルトの動詞選択数")

(defparameter *default-adj-count* 1
  "デフォルトの形容詞選択数")

(defparameter *prompt-template*
  "Create a short story using these ~D themes: ~{~A~^, ~}

Style: Short short fiction (flash fiction)
Length: 200-500 words
Language: Japanese
Tone: Literary, evocative"
  "ストーリー生成用のプロンプトテンプレート")

(defun init-config (base-dir)
  "設定を初期化"
  (setf *word-pool-dir* (merge-pathnames "word_pools/" base-dir)
        *story-output-dir* (merge-pathnames "output/" base-dir))
  
  ;; ディレクトリが存在しない場合は作成
  (unless (probe-file *word-pool-dir*)
    (ensure-directories-exist *word-pool-dir*))
  (unless (probe-file *story-output-dir*)
    (ensure-directories-exist *story-output-dir*))
  
  (format t "[CONFIG] 設定初期化完了~%")
  (format t "[CONFIG] 単語プール: ~A~%" *word-pool-dir*)
  (format t "[CONFIG] 出力先: ~A~%" *story-output-dir*))
