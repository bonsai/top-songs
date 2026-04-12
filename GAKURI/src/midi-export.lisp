;;; midi-export.lisp — MIDI file generation for GAKURI progressions
;;; Outputs Standard MIDI Format 0 files that can be played with any MIDI player

(in-package :gakuri)

;;; ── MIDI File Format Utilities ──────────────────────────────────────

(defun write-midi-variable-length (stream value)
  "Write a variable-length quantity to the MIDI stream."
  (let ((buffer 0)
        (v value))
    (loop
      (setf (ldb (byte 7 0) buffer) (logand v #x7F))
      (setf v (ash v -7))
      (if (plusp v)
          (setf (ldb (byte 1 7) buffer) 1)
          (setf (ldb (byte 1 7) buffer) 0))
      (write-byte buffer stream)
      (when (zerop v) (return)))))

(defun write-midi-header (stream num-tracks division)
  "Write MIDI MThd header."
  (write-string "MThd" stream)
  (write-byte 0 stream) (write-byte 0 stream)
  (write-byte 0 stream) (write-byte 6 stream)  ; header length = 6
  ;; Format 0
  (write-byte 0 stream) (write-byte 0 stream)
  ;; Number of tracks
  (write-byte (ldb (byte 8 8) num-tracks) stream)
  (write-byte (ldb (byte 8 0) num-tracks) stream)
  ;; Division (ticks per quarter note)
  (write-byte (ldb (byte 8 8) division) stream)
  (write-byte (ldb (byte 8 0) division) stream))

(defun write-midi-track-header (stream length)
  "Write MIDI MTrk header."
  (write-string "MTrk" stream)
  (write-byte (ldb (byte 8 24) length) stream)
  (write-byte (ldb (byte 8 16) length) stream)
  (write-byte (ldb (byte 8 8) length) stream)
  (write-byte (ldb (byte 8 0) length) stream))

(defun write-midi-event (stream delta-time status data1 &optional (data2 0))
  "Write a MIDI event with delta time."
  (write-midi-variable-length stream delta-time)
  (write-byte status stream)
  (write-byte data1 stream)
  (when (and (/= status #xC0) (/= status #xD0))  ; Program Change & Channel Pressure have 1 data byte
    (write-byte data2 stream)))

(defun write-midi-note-on (stream delta-time channel note velocity)
  (write-midi-event stream delta-time (logior #x90 channel) note velocity))

(defun write-midi-note-off (stream delta-time channel note velocity)
  (write-midi-event stream delta-time (logior #x80 channel) note velocity))

(defun write-midi-tempo (stream delta-time tempo)
  "Set tempo in microseconds per quarter note."
  (write-midi-variable-length stream delta-time)
  (write-byte #xFF stream)  ; Meta event
  (write-byte #x51 stream)  ; Tempo
  (write-byte 3 stream)     ; Length
  (write-byte (ldb (byte 8 16) tempo) stream)
  (write-byte (ldb (byte 8 8) tempo) stream)
  (write-byte (ldb (byte 8 0) tempo) stream))

(defun write-midi-time-sig (stream delta-time numerator denominator)
  "Set time signature."
  (write-midi-variable-length stream delta-time)
  (write-byte #xFF stream)
  (write-byte #x58 stream)
  (write-byte 4 stream)
  (write-byte numerator stream)
  (write-byte (integer-length denominator) stream)  ; log2
  (write-byte 24 stream)  ; MIDI clocks per metronome click
  (write-byte 8 stream))  ; 32nd notes per MIDI quarter

(defun write-midi-end-of-track (stream delta-time)
  (write-midi-variable-length stream delta-time)
  (write-byte #xFF stream)
  (write-byte #x2F stream)
  (write-byte 0 stream))

(defun write-midi-program-change (stream delta-time channel program)
  (write-midi-event stream delta-time (logior #xC0 channel) program))

;;; ── Chord to MIDI Notes ─────────────────────────────────────────────

(defun chord-to-midi-notes (chord &key (octave 3) (duration 480))
  "Convert a chord struct to a list of (note-number, start-time, duration, velocity) tuples.
   Default: quarter note duration at 480 ticks/quarter."
  (let* ((root (chord-root chord))
         (base-intervals (cdr (assoc (chord-type chord) *chord-intervals*)))
         (all-intervals (copy-seq base-intervals))
         (notes nil))
    ;; Add extensions
    (dolist (ext (chord-extensions chord))
      (let ((interval (cdr (assoc ext *jazz-extensions*))))
        (when interval (push interval all-intervals))))
    ;; Add alterations
    (dolist (alt (chord-alterations chord))
      (let ((interval (cdr (assoc alt *jazz-extensions*))))
        (when interval (push interval all-intervals))))
    ;; Normalize and create MIDI notes
    (let* ((unique-pcs (remove-duplicates all-intervals))
           (velocity (case (chord-type chord)
                       (:major-seventh 80)
                       (:minor-seventh 75)
                       (:dominant 85)
                       (:half-diminished 70)
                       (:fully-diminished 65)
                       (t 78))))
      (dolist (interval (sort unique-pcs #'<))
        (let* ((midi-note (+ (* (1+ octave) 12) (mod (+ root interval) 12))))
          (push (list midi-note 0 duration velocity) notes))))
    (nreverse notes)))

;;; ── Progression to MIDI Track ───────────────────────────────────────

(defun progression-to-midi (progression &key
                            (tempo 500000)        ; 120 BPM (microseconds per quarter)
                            (ticks-per-quarter 480)
                            (channel 0)
                            (program 0)           ; 0 = Acoustic Grand Piano
                            (note-duration nil)   ; nil = auto, or ticks
                            (output-file "gakuri-output.mid")
                            (octave 3))
  "Export a chord progression to a Standard MIDI Format 0 file.
   
   tempo: microseconds per quarter note (500000 = 120 BPM, 600000 = 100 BPM, 750000 = 80 BPM)
   program: MIDI instrument (0 = Piano, 25 = Guitar, 41 = Viola, 49 = Strings)
   
   Returns the output file path."
  (let* ((ticks (or note-duration ticks-per-quarter))
         (events nil)
         (total-ticks 0))
    ;; Collect all MIDI events
    (dolist (chord progression)
      (let ((notes (chord-to-midi-notes chord :octave octave :duration ticks)))
        (dolist (note-info notes)
          (destructuring-bind (note start dur vel) note-info
            ;; Note On
            (push (list 0 'note-on note vel) events)
            ;; Note Off
            (push (list dur 'note-off note 0) events)))
        (incf total-ticks ticks)))
    ;; Sort events by time
    (setf events (sort events #'< :key #'first))
    
    ;; Build track data in a byte array
    (let ((track-data (make-array 0 :element-type '(unsigned-byte 8) :fill-pointer 0 :adjustable t)))
      ;; Program change
      (vector-push-extend 0 track-data)  ; delta = 0
      (vector-push-extend (logior #xC0 channel) track-data)
      (vector-push-extend program track-data)
      
      ;; Tempo
      (vector-push-extend 0 track-data)
      (vector-push-extend #xFF track-data)
      (vector-push-extend #x51 track-data)
      (vector-push-extend 3 track-data)
      (vector-push-extend (ldb (byte 8 16) tempo) track-data)
      (vector-push-extend (ldb (byte 8 8) tempo) track-data)
      (vector-push-extend (ldb (byte 8 0) tempo) track-data)
      
      ;; Time signature 4/4
      (vector-push-extend 0 track-data)
      (vector-push-extend #xFF track-data)
      (vector-push-extend #x58 track-data)
      (vector-push-extend 4 track-data)
      (vector-push-extend 4 track-data)
      (vector-push-extend 2 track-data)
      (vector-push-extend 24 track-data)
      (vector-push-extend 8 track-data)
      
      ;; Events
      (let (prev-time)
        (dolist (event events)
          (destructuring-bind (time type note vel) event
            (let ((delta (if prev-time (- time prev-time) 0)))
              (write-midi-variable-length-to-vector track-data delta)
              (ecase type
                (note-on
                 (vector-push-extend (logior #x90 channel) track-data)
                 (vector-push-extend note track-data)
                 (vector-push-extend vel track-data))
                (note-off
                 (vector-push-extend (logior #x80 channel) track-data)
                 (vector-push-extend note track-data)
                 (vector-push-extend 0 track-data)))
              (setq prev-time time)))))
      
      ;; End of track
      (vector-push-extend 0 track-data)
      (vector-push-extend #xFF track-data)
      (vector-push-extend #x2F track-data)
      (vector-push-extend 0 track-data)
      
      ;; Write to file
      (with-open-file (stream output-file
                              :direction :output
                              :element-type '(unsigned-byte 8)
                              :if-exists :supersede)
        ;; Header
        (write-string "MThd" stream)
        (write-byte 0 stream) (write-byte 0 stream)
        (write-byte 0 stream) (write-byte 6 stream)
        (write-byte 0 stream) (write-byte 0 stream)  ; Format 0
        (write-byte 0 stream) (write-byte 1 stream)  ; 1 track
        (write-byte (ldb (byte 8 8) ticks-per-quarter) stream)
        (write-byte (ldb (byte 8 0) ticks-per-quarter) stream)
        ;; Track
        (write-string "MTrk" stream)
        (let ((len (length track-data)))
          (write-byte (ldb (byte 8 24) len) stream)
          (write-byte (ldb (byte 8 16) len) stream)
          (write-byte (ldb (byte 8 8) len) stream)
          (write-byte (ldb (byte 8 0) len) stream))
        (write-sequence track-data stream))
      
      output-file)))

(defun write-midi-variable-length-to-vector (vector value)
  "Write a variable-length quantity to a vector."
  (let ((buffer 0)
        (v value)
        (bytes nil))
    (loop
      (setf (ldb (byte 7 0) buffer) (logand v #x7F))
      (setf v (ash v -7))
      (if (plusp v)
          (setf (ldb (byte 1 7) buffer) 1)
          (setf (ldb (byte 1 7) buffer) 0))
      (push buffer bytes)
      (when (zerop v) (return)))
    (dolist (b bytes)
      (vector-push-extend b vector))))

;;; ── High-Level MIDI Export ──────────────────────────────────────────

(defun export-progression-midi (progression key &key
                               (mood :ballad)
                               (output-dir "./midi-output/")
                               (instruments nil))
  "High-level MIDI export: generates progression and exports to MIDI.
   
   mood: affects tempo and instrument choice
   instruments: list of MIDI program numbers (default: auto-select by mood)
   
   Returns list of generated MIDI file paths."
  (ensure-directories-exist output-dir)
  
  (let* ((tempo (case mood
                  (:ballad 750000)      ; ~80 BPM
                  (:bebop 300000)       ; ~200 BPM
                  (:melancholic 600000) ; ~100 BPM
                  (:uplifting 500000)   ; ~120 BPM
                  (:yearning 600000)    ; ~100 BPM
                  (:noir 545000)        ; ~110 BPM
                  (:neo-soul 600000)    ; ~100 BPM
                  (:peaceful 750000)    ; ~80 BPM
                  (:dramatic 480000)    ; ~125 BPM
                  (:bittersweet 600000) ; ~100 BPM
                  (t 600000)))
         (program (or (car instruments)
                      (case mood
                        (:ballad 0)     ; Acoustic Grand Piano
                        (:bebop 0)
                        (:melancholic 25) ; Acoustic Guitar (nylon)
                        (:uplifting 49) ; String Ensemble 1
                        (:yearning 41)  ; Viola
                        (:noir 49)
                        (:neo-soul 4)   ; Electric Piano 1
                        (:peaceful 0)
                        (:dramatic 49)
                        (:bittersweet 25)
                        (t 0))))
         (filename (format nil "~Agakuri-~A.mid" output-dir (string-downcase (symbol-name mood)))))
    (progression-to-midi progression
                         :tempo tempo
                         :program program
                         :output-file filename)
    (list :file filename :tempo tempo :program program)))
