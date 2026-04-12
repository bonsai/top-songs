;;; unicode-japanese-analyzer.lisp — Analyzes Unicode possibilities for Japanese text processing
(in-package :cl-user)

(defpackage :unicode-jp-analyzer
  (:use :cl)
  (:export :analyze-unicode-ranges
           :evaluate-character-potential
           :generate-analysis-report
           :save-analysis-results))

(in-package :unicode-jp-analyzer)

;; Unicode ranges for Japanese characters
(defparameter *hiragana-range* '(#x3041 . #x309F))
(defparameter *katakana-range* '(#x30A1 . #x30FF))
(defparameter *katakana-halfwidth* '(#xFF65 . #xFF9F))
(defparameter *kanji-cjk-range* '(#x4E00 . #x9FFF))
(defparameter *kanji-cjk-ext-a* '(#x3400 . #x4DBF))
(defparameter *kanji-cjk-ext-b* '(#x20000 . #x2A6DF))
(defparameter *kanji-radicals* '(#x2E80 . #x2EFF))
(defparameter *japanese-punctuation* '(#x3000 . #x303F))
(defparameter *fullwidth-latin* '(#xFF01 . #xFF5E))
(defparameter *halfwidth-katakana* '(#xFF65 . #xFF9F))

(defun unicode-range-p (char range)
  "Check if character is within Unicode range"
  (let ((code (char-code char)))
    (and (>= code (car range))
         (<= code (cdr range)))))

(defun classify-japanese-char (char)
  "Classify a Japanese character by type"
  (cond
    ((unicode-range-p char *hiragana-range*) 'hiragana)
    ((unicode-range-p char *katakana-range*) 'katakana)
    ((unicode-range-p char *katakana-halfwidth*) 'katakana-halfwidth)
    ((unicode-range-p char *kanji-cjk-range*) 'kanji-cjk)
    ((unicode-range-p char *kanji-cjk-ext-a*) 'kanji-ext-a)
    ((unicode-range-p char *kanji-radicals*) 'kanji-radical)
    ((unicode-range-p char *japanese-punctuation*) 'punctuation)
    ((unicode-range-p char *fullwidth-latin*) 'fullwidth-latin)
    ((unicode-range-p char *halfwidth-katakana*) 'halfwidth-katakana)
    (t 'other)))

(defun analyze-unicode-ranges (&key (sample-text nil)
                                   (file-path nil)
                                   (max-chars 10000))
  "Analyze Unicode character distribution in Japanese text"
  (let ((text (if file-path
                  (with-open-file (stream file-path 
                                         :external-format :utf-8)
                    (let ((content ""))
                      (loop for line = (read-line stream nil nil)
                            while line do
                              (setf content (concatenate 'string content line #\Newline)))
                      content))
                  (or sample-text "")))
        (char-counts (make-hash-table))
        (type-counts (make-hash-table))
        (total-chars 0)
        (unique-chars 0))
    
    ;; Count characters
    (loop for char across text
          for count from 1 to max-chars
          while (<= count max-chars)
          do
            (incf total-chars)
            (let* ((char-type (classify-japanese-char char))
                   (current-count (gethash char char-counts 0)))
              (setf (gethash char char-counts) (1+ current-count))
              (let ((type-total (gethash char-type type-counts 0)))
                (setf (gethash char-type type-counts) (1+ type-total)))))
    
    ;; Calculate unique characters
    (maphash (lambda (k v) (declare (ignore k v)) (incf unique-chars)) char-counts)
    
    ;; Convert hash tables to alists
    (let ((char-alist '())
          (type-alist '()))
      (maphash (lambda (k v) (push (cons k v) char-alist)) char-counts)
      (maphash (lambda (k v) (push (cons k v) type-alist)) type-counts)
    
      ;; Generate statistics
      (let ((results `(:total-chars ,total-chars
                       :unique-chars ,unique-chars
                       :char-distribution ,char-alist
                       :type-distribution ,type-alist
                       :analysis-time ,(get-universal-time))))
        results))))

(defun evaluate-character-potential (&key (target-range 'kanji-cjk)
                                         (sample-size 1000)
                                         (complexity-threshold 3))
  "Evaluate the potential of Unicode ranges for Japanese processing"
  (let* ((range-spec (case target-range
                       ('hiragana *hiragana-range*)
                       ('katakana *katakana-range*)
                       ('kanji-cjk *kanji-cjk-range*)
                       ('kanji-ext-a *kanji-cjk-ext-a*)
                       ('punctuation *japanese-punctuation*)
                       (t *kanji-cjk-range*)))
         (start-code (car range-spec))
         (end-code (cdr range-spec))
         (total-available (- end-code start-code -1))
         (sample-chars '())
         (evaluation-metrics '()))
    
    ;; Sample characters from range
    (loop for i from 1 to (min sample-size total-available) do
      (let ((code (+ start-code (random total-available))))
        (push (code-char code) sample-chars)))
    
    ;; Evaluate complexity and usability
    (setf evaluation-metrics
          `(:range-name ,target-range
            :total-available ,total-available
            :sample-size ,(length sample-chars)
            :unicode-start ,(format nil "#x~X" start-code)
            :unicode-end ,(format nil "#x~X" end-code)
            :potential-score ,(/ (length sample-chars) total-available)
            :recommended-for ,(case target-range
                               ('hiragana "Basic Japanese text, beginner learning")
                               ('katakana "Foreign words, technical terms")
                               ('kanji-cjk "Standard Japanese writing, literature")
                               ('kanji-ext-a "Rare kanji, historical texts")
                               ('punctuation "Text formatting, readability")
                               (t "General Japanese processing"))))
    
    evaluation-metrics))

(defun generate-analysis-report (&key (input-file nil)
                                     (output-file "unicode-analysis-report.txt")
                                     (sample-text "日本語のUnicode文字評価システム。漢字、ひらがな、カタカナの可能性を分析します。")
                                     (detailed t))
  "Generate comprehensive analysis report"
  (let* ((analysis (analyze-unicode-ranges 
                    :sample-text sample-text
                    :file-path input-file))
         (evaluations (mapcar #'evaluate-character-potential
                             '(hiragana katakana kanji-cjk punctuation)))
         (report-lines '()))
    
    ;; Build report
    (push "========================================" report-lines)
    (push "Unicode Japanese Character Analysis Report" report-lines)
    (push "========================================" report-lines)
    (push "" report-lines)
    
    ;; Basic statistics
    (push (format nil "Analysis Time: ~A" (nth 5 analysis)) report-lines)
    (push (format nil "Total Characters Analyzed: ~D" (getf analysis :total-chars)) report-lines)
    (push (format nil "Unique Characters Found: ~D" (getf analysis :unique-chars)) report-lines)
    (push "" report-lines)
    
    ;; Type distribution
    (push "--- Character Type Distribution ---" report-lines)
    (dolist (type-stat (getf analysis :type-distribution))
      (push (format nil "~A: ~D characters" (car type-stat) (cdr type-stat)) report-lines))
    (push "" report-lines)
    
    ;; Unicode range evaluations
    (push "--- Unicode Range Potential Evaluation ---" report-lines)
    (dolist (eval evaluations)
      (push (format nil "~A:" (getf eval :range-name)) report-lines)
      (push (format nil "  Available Characters: ~D" (getf eval :total-available)) report-lines)
      (push (format nil "  Unicode Range: ~A - ~A" 
                    (getf eval :unicode-start) 
                    (getf eval :unicode-end)) report-lines)
      (push (format nil "  Potential Score: ~,4F" (getf eval :potential-score)) report-lines)
      (push (format nil "  Recommended For: ~A" (getf eval :recommended-for)) report-lines)
      (push "" report-lines))
    
    ;; Research implications
    (push "--- Research Implications ---" report-lines)
    (push "This analysis demonstrates the rich potential of Unicode" report-lines)
    (push "for Japanese text processing. The diverse character sets" report-lines)
    (push "enable sophisticated natural language processing applications" report-lines)
    (push "including automated story generation, linguistic analysis," report-lines)
    (push "and cross-cultural text mining." report-lines)
    
    ;; Reverse to get correct order
    (setf report-lines (nreverse report-lines))
    
    ;; Save to file
    (with-open-file (stream output-file 
                           :direction :output 
                           :if-exists :supersede
                           :external-format :utf-8)
      (dolist (line report-lines)
        (format stream "~A~%" line)))
    
    (format t "Analysis report saved to: ~A~%" output-file)
    (values analysis evaluations output-file)))

(defun save-analysis-results (&key (filename "unicode-jp-analysis.json")
                                  (sample-text "日本の言語処理におけるUnicodeの可能性。漢字文化圏の文字体系を評価する。")
                                  (include-evaluations t))
  "Save analysis results in JSON-like format"
  (let* ((analysis (analyze-unicode-ranges :sample-text sample-text))
         (evaluations (when include-evaluations
                       (mapcar #'evaluate-character-potential
                              '(hiragana katakana kanji-cjk punctuation))))
         (timestamp (get-universal-time)))
    
    (with-open-file (stream filename 
                           :direction :output 
                           :if-exists :supersede
                           :external-format :utf-8)
      (format stream "{~%")
      (format stream "  \"analysis_timestamp\": \"~A\",~%" timestamp)
      (format stream "  \"total_characters\": ~D,~%" (getf analysis :total-chars))
      (format stream "  \"unique_characters\": ~D,~%" (getf analysis :unique-chars))
      (format stream "  \"character_types\": {~%")
      
      ;; Output type distribution
      (let ((types (getf analysis :type-distribution)))
        (loop for i from 0 below (length types) do
          (let ((type (nth i types)))
            (format stream "    \"~A\": ~D~:[,~;~%~]" 
                    (car type) 
                    (cdr type)
                    (< i (1- (length types)))))))
      
      (format stream "  }~%")
      
      (when include-evaluations
        (format stream "  \"unicode_evaluations\": [~%")
        (loop for i from 0 below (length evaluations) do
          (let ((eval (nth i evaluations)))
            (format stream "    {~%")
            (format stream "      \"range\": \"~A\",~%" (getf eval :range-name))
            (format stream "      \"available_chars\": ~D,~%" (getf eval :total-available))
            (format stream "      \"potential_score\": ~,4F,~%" (getf eval :potential-score))
            (format stream "      \"recommended_use\": \"~A\"~%" (getf eval :recommended-for))
            (format stream "    }~:[,~;~%~]" 
                    (< i (1- (length evaluations))))))
        (format stream "  ]~%"))
      
      (format stream "}~%"))
    
    (format t "Analysis results saved to: ~A~%" filename)
    filename))

;; Example usage functions
(defun run-complete-analysis ()
  "Run complete Unicode Japanese analysis"
  (format t "Starting Unicode Japanese Character Analysis...~%")
  
  ;; Generate detailed report
  (generate-analysis-report 
   :sample-text "自然言語処理における日本語Unicode文字の可能性評価。漢字、ひらがな、カタカナ、記号類の包括的分析を通じて、次世代の言語処理システムの基盤を構築する。"
   :output-file "japanese-unicode-analysis.txt"
   :detailed t)
  
  ;; Save structured results
  (save-analysis-results 
   :filename "unicode-analysis-results.json"
   :sample-text "機械学習とUnicode日本語処理の融合。多様な文字体系を活用した高度なテキスト解析。"
   :include-evaluations t)
  
  (format t "Analysis complete! Check generated files for detailed results.~%"))

;; Run analysis when loaded
(run-complete-analysis)
