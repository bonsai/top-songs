;;; baku.asd — ASDF システム定義
(in-package :cl-user)

(defpackage :baku-system
  (:use :cl :asdf))

(in-package :baku-system)

(defsystem :baku
  :name "baku"
  :version "0.2.0"
  :description "Random Word Short Story Generator via MCP"
  :author "BAKU Agent"
  :license "MIT"
  :depends-on (:sb-posix :uiop)
  :pathname "src/"
  :components ((:file "config")
               (:file "word-pool" :depends-on ("config"))
               (:file "mcp-connector" :depends-on ("config"))
               (:file "story-generator" :depends-on ("config" "word-pool" "mcp-connector"))
               (:file "pool-generator" :depends-on ("config"))
               (:file "main" :depends-on ("config" "word-pool" "mcp-connector" "story-generator" "pool-generator")))
  :entry-point "baku-main:cli-main")
