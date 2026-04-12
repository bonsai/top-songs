;;; package.lisp
(defpackage :gakuri
  (:use :cl :alexandria :serapeum)
  (:export
   ;; Music theory
   #:*pitch-classes* #:*note-names* #:*scale-degrees*
   #:pitch-class #:note #:chord #:chord-type #:chord-inversion
   #:scale-degree #:key-signature #:mode
   #:build-chord #:parse-chord-notation #:chord->midi
   #:chord->tonal-interval-vector #:chord-dissonance
   #:tonal-distance #:key-distance
   ;; Tension model
   #:tension-state #:compute-tension
   #:tension-key #:tension-dissonance #:tension-voice-leading #:tension-hierarchical
   #:*tension-weights*
   ;; Voice leading
   #:voice-leading-cost #:optimal-voice-assignment
   #:smooth-voice-leading #:voice-leading-between
   ;; Progression generation
   #:generate-progression #:generate-ii-v-i-variations
   #:generate-tritone-substitutions #:generate-modal-interchange
   #:generate-altered-dominants #:generate-extended-progressions
   #:with-tension-profile #:progression-for-mood
   ;; Evaluation
   #:evaluate-progression #:emotional-score
   #:tension-curve #:tension-arc-type
   #:smoothness-score #:functional-coherence
   ;; Emotional profiles
   #:*emotional-profiles* #:profile-ballad #:profile-bebop
   #:profile-melancholic #:profile-uplifting #:profile-yearning
   #:profile-noir #:profile-neo-soul
   ;; Database
   #:*progression-db* #:save-progression #:load-progressions
   #:query-by-mood #:query-by-tension-arc #:top-rated
   ;; Generator facades
   #:generate-emotional-progression #:generate-batch
   #:analyze-and-rate #:export-progression-text))

;;; Test package
(defpackage :gakuri/tests
  (:use :cl :gakuri :rove))
