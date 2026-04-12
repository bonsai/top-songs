;;; mcp-connector.lisp — MCP接続モジュール
(in-package :cl-user)

(defpackage :baku-mcp
  (:use :cl)
  (:export :connect-mcp
           :send-prompt
           :receive-response
           :disconnect-mcp))

(in-package :baku-mcp)

(defparameter *mcp-process* nil
  "MCPプロセスのハンドル")

(defun connect-mcp (endpoint)
  "MCPサーバーに接続"
  (format t "[MCP] 接続中: ~A~%" endpoint)
  ;; Python MCPコネクタを起動
  (let ((script-path (merge-pathnames "scripts/story_generator.py"
                                      (directory-namestring *load-truename*))))
    (when (probe-file script-path)
      (setf *mcp-process*
            (run-program "python" (list (namestring script-path) "--mode" "server")
                         :output :stream
                         :input :stream
                         :wait nil))
      (format t "[MCP] 接続完了~%")
      t)
    (format t "[MCP] スクリプトが見つかりません: ~A~%" script-path)
    nil))

(defun send-prompt (prompt-text)
  "MCPサーバーにプロンプトを送信"
  (format t "[MCP] プロンプト送信: ~A 文字~%" (length prompt-text))
  (when *mcp-process*
    (let ((input (process-input *mcp-process*)))
      (format input "~A~%" prompt-text)
      (force-output input)))
  t)

(defun receive-response ()
  "MCPサーバーからのレスポンスを受信"
  (when *mcp-process*
    (let ((output (process-output *mcp-process*)))
      (loop for line = (read-line output nil nil)
            while line
            collect line into lines
            finally (return (format nil "~{~A~^~%~}" lines)))))
  nil)

(defun disconnect-mcp ()
  "MCPサーバーから切断"
  (when *mcp-process*
    (ignore-errors (close *mcp-process*))
    (setf *mcp-process* nil)
    (format t "[MCP] 切断完了~%"))
  t)
