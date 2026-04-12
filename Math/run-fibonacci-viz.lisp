;;; run-fibonacci-viz.lisp — Load and execute fibonacci viz generator
(load "fibonacci-viz-generator.lisp")

;; Generate and save the Fibonacci visualization - Mobile Phone Size
(baku-fibonacci-viz:save-fibonacci-html 
  :filename "fibonacci-spiral.html"
  :iterations 15
  :width 390
  :height 844
  :speed 100
  :rectangles t
  :psychedelic t)

(sb-ext:quit)
