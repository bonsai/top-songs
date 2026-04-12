;;; golden-ratio-proportion.lisp — Physical Proportion Visualization System
;;; Based on "Physical Proportion Theory: Golden Ratio & Fibonacci in Visual Art"
;;;
;;; Author: bonsai/qwen3.6-plus
;;; Email: onsen.bonsai@gmail.com
;;; Date: 2026-04-13
;;; License: MIT

(in-package :cl-user)

(defpackage :golden-proportion
  (:use :cl)
  (:export :*phi*
           :*phi-inverse*
           :fibonacci-fast
           :golden-split
           :golden-recursive-split
           :generate-golden-spiral
           :generate-proportion-network
           :generate-hsl-color
           :generate-proportion-html
           :save-proportion-html
           :golden-convergence
           :display-convergence
           :calculate-beauty-index
           :generate-color-harmony
           :fibonacci-rectangle-grid))

(in-package :golden-proportion)

;;; ============================================================
;;; 1. Core Mathematical Constants & Functions
;;; ============================================================

;; 黄金比の定義
(defparameter *phi* (/ (+ 1 (sqrt 5)) 2)
  "Golden ratio φ = (1 + √5) / 2 ≈ 1.6180339887...")

(defparameter *phi-inverse* (/ 1 *phi*)
  "Inverse golden ratio 1/φ = φ - 1 ≈ 0.6180339887...")

(defparameter *golden-angle* (/ (* 2 pi) (* *phi* *phi*))
  "Golden angle ≈ 137.508° in radians")

;;; ============================================================
;;; 2. Fibonacci Number Generation
;;; ============================================================

(defun fibonacci-fast (n)
  "Generate nth Fibonacci number using iterative method O(n)
   F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2)"
  (cond ((<= n 0) 0)
        ((= n 1) 1)
        (t
         (let ((a 0) (b 1))
           (loop for i from 2 to n do
             (psetf a b
                    b (+ a b)))
           b))))

(defun fibonacci-sequence (count)
  "Generate first COUNT Fibonacci numbers as a list"
  (loop for i from 1 to count
        collect (fibonacci-fast i)))

;;; ============================================================
;;; 3. Golden Split Algorithms
;;; ============================================================

(defun golden-split (width height &key (vertical t))
  "Split rectangle by golden ratio into two parts
   Returns: ((x1 y1 w1 h1) (x2 y2 w2 h2))"
  (if vertical
      (let ((split (* width *phi-inverse*)))
        (list (list 0 0 split height)
              (list split 0 (- width split) height)))
      (let ((split (* height *phi-inverse*)))
        (list (list 0 0 width split)
              (list 0 split width (- height split))))))

(defun golden-recursive-split (width height depth &key (x 0) (y 0))
  "Recursively split rectangle by golden ratio DEPTH times
   Returns: List of (x y width height) rectangles"
  (if (<= depth 0)
      (list (list x y width height))
      (let* ((vertical (> width height))
             (splits (golden-split width height :vertical vertical)))
        (if (= (length splits) 2)
            (let ((rect1 (first splits))
                  (rect2 (second splits)))
              (append (apply #'golden-recursive-split 
                            (append rect1 (list (- depth 1)) 
                                   (list :x x :y y)))
                      (let ((new-x (+ x (first rect2)))
                            (new-y (+ y (second rect2))))
                        (apply #'golden-recursive-split 
                              (append rect2 (list (- depth 1)) 
                                     (list :x new-x :y new-y))))))
            (list (list x y width height))))))

;;; ============================================================
;;; 4. Spiral Generation
;;; ============================================================

(defun generate-golden-spiral (iterations scale)
  "Generate golden spiral points based on Fibonacci numbers
   Returns: List of (x y fibonacci-number)"
  (loop for i from 1 to iterations
        for angle = 0 then (+ angle (/ pi 2))
        for fib = (fibonacci-fast i)
        for radius = (* fib scale)
        collect (list (* radius (cos angle))
                      (* radius (sin angle))
                      fib)))

(defun generate-phyllotaxis-spiral (count scale)
  "Generate phyllotaxis (leaf arrangement) spiral
   Using golden angle ≈ 137.508°"
  (loop for i from 0 to (- count 1)
        for angle = (* i *golden-angle*)
        for radius = (* scale (sqrt i))
        collect (list (* radius (cos angle))
                      (* radius (sin angle))
                      i)))

;;; ============================================================
;;; 5. Color Generation
;;; ============================================================

(defun generate-hsl-color (index total &key (golden t))
  "Generate HSL color string
   If GOLDEN is true, uses golden ratio for hue progression"
  (let* ((base-hue (* index (/ 360 total)))
         (hue (if golden
                  (mod (* base-hue *phi*) 360)
                  base-hue))
         (saturation 70)
         (lightness 60))
    (format nil "hsl(~D, ~D%, ~D%)" 
            (round hue) saturation lightness)))

(defun generate-color-harmony (base-hue &key (mode :golden))
  "Generate color harmony based on golden ratio
   Modes: :golden, :complementary, :triadic, :tetradic"
  (case mode
    (:golden
     (list base-hue
           (mod (* base-hue *phi*) 360)
           (mod (* base-hue *phi* *phi*) 360)))
    (:complementary
     (list base-hue (mod (+ base-hue 180) 360)))
    (:triadic
     (list base-hue 
           (mod (+ base-hue 120) 360)
           (mod (+ base-hue 240) 360)))
    (:tetradic
     (list base-hue
           (mod (+ base-hue 90) 360)
           (mod (+ base-hue 180) 360)
           (mod (+ base-hue 270) 360)))))

;;; ============================================================
;;; 6. Proportion Network Generation
;;; ============================================================

(defun generate-proportion-network (canvas-width canvas-height depth)
  "Generate complete proportion network data for visualization
   Returns: Property list with :rectangles, :spiral, :colors"
  (let* ((rects (golden-recursive-split canvas-width canvas-height depth))
         (spiral (generate-golden-spiral (length rects) 1.0))
         (colors (loop for i below (length rects)
                       collect (generate-hsl-color i (length rects)))))
    (list :rectangles rects
          :spiral spiral
          :colors colors)))

;;; ============================================================
;;; 7. Beauty Index Calculation
;;; ============================================================

(defun calculate-beauty-index (width height)
  "Calculate aesthetic beauty index based on golden ratio
   B(R) = 1 - |log(r) - log(φ)| / log(φ) where r = w/h
   Returns: Value between 0 and 1"
  (let* ((ratio (/ (max width height) (min width height)))
         (log-ratio (log ratio))
         (log-phi (log *phi*))
         (beauty (- 1 (/ (abs (- log-ratio log-phi)) log-phi))))
    (max 0.0 (min 1.0 beauty))))

(defun fibonacci-rectangle-grid (max-width max-height)
  "Generate grid of Fibonacci-sized rectangles
   Returns: List of (x y width height)"
  (loop with x = 0 and y = 0
        for i from 1
        for fib = (fibonacci-fast i)
        while (and (< x max-width) (< y max-height))
        for width = (min (* fib 10) (- max-width x))
        for height = (min (* fib 10) (- max-height y))
        collect (list x y width height)
        do (if (> width height)
               (incf x width)
               (incf y height))))

;;; ============================================================
;;; 8. Convergence Analysis
;;; ============================================================

(defun golden-convergence (n)
  "Calculate convergence of F(n+1)/F(n) to φ
   Returns: List of (n F(n) ratio difference)"
  (loop for i from 1 to n
        for fib-n = (fibonacci-fast i)
        for fib-next = (fibonacci-fast (+ i 1))
        for ratio = (if (> fib-n 0) (/ fib-next fib-n) 0)
        for diff = (abs (- ratio *phi*))
        collect (list i fib-n ratio diff)))

(defun display-convergence (n)
  "Display convergence table in console"
  (format t "|  n |  F(n) | F(n+1)/F(n)  | φとの差       |~%")
  (format t "|----|-------|--------------|---------------|~%")
  (loop for (i fib ratio diff) in (golden-convergence n)
        do (format t "| ~3D | ~5D | ~12,10F | ~12,10F |~%"
                   i fib ratio diff)))

;;; ============================================================
;;; 9. HTML/JavaScript Generation
;;; ============================================================

(defun generate-proportion-html (&key (width 1200) (height 800) (depth 8))
  "Generate complete HTML/JavaScript for golden proportion visualization"
  (let* ((network (generate-proportion-network width height depth))
         (rects (getf network :rectangles))
         (spiral (getf network :spiral))
         (colors (getf network :colors)))
    (format nil "<!DOCTYPE html>
<html lang=\"ja\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Golden Ratio Proportion Network - 黄金比例ネットワーク</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            font-family: 'Helvetica Neue', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            overflow: hidden;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        
        h1 {
            color: #fff;
            text-align: center;
            margin-bottom: 10px;
            font-size: 28px;
            font-weight: 300;
            letter-spacing: 2px;
        }
        
        .phi-display {
            color: #667eea;
            text-align: center;
            margin-bottom: 10px;
            font-size: 18px;
            font-family: 'Courier New', monospace;
        }
        
        .info {
            color: rgba(255, 255, 255, 0.7);
            text-align: center;
            margin-bottom: 20px;
            font-size: 14px;
        }
        
        #canvas {
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
            background: rgba(26, 26, 46, 0.8);
        }
        
        .controls {
            margin-top: 20px;
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        }
        
        button {
            padding: 10px 20px;
            border: none;
            border-radius: 25px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        button:hover {
            transform: scale(1.05);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
        }
        
        button:active {
            transform: scale(0.95);
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>黄金比例ネットワーク</h1>
        <div class=\"phi-display\">φ = ~,8F</div>
        <div class=\"info\">
            分割深度: ~D | 長方形数: ~D | フィボナッチ螺旋
        </div>
        <canvas id=\"canvas\" width=\"~D\" height=\"~D\"></canvas>
        <div class=\"controls\">
            <button onclick=\"toggleAnimation()\">⏯ アニメーション</button>
            <button onclick=\"increaseDepth()\">➕ 分割深化</button>
            <button onclick=\"decreaseDepth()\">➖ 分割簡素</button>
            <button onclick=\"toggleSpiral()\">🌀 螺旋表示</button>
            <button onclick=\"resetView()\">🔄 リセット</button>
        </div>
    </div>
    
    <script>
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        
        let currentDepth = ~D;
        let animationId = null;
        let time = 0;
        let showSpiral = true;
        
        // Rectangle data from Lisp
        const rectangles = ~A;
        const spiralPoints = ~A;
        const colors = ~A;
        
        function drawRectangles() {
            rectangles.forEach((rect, i) => {
                if (rect.length < 4) return;
                const [x, y, w, h] = rect;
                
                // Fill with golden color
                ctx.fillStyle = colors[i] || 'rgba(102, 126, 234, 0.3)';
                ctx.globalAlpha = 0.5 + Math.sin(time * 0.03 + i * 0.5) * 0.2;
                ctx.fillRect(x, y, w, h);
                
                // Border
                ctx.globalAlpha = 0.8;
                ctx.strokeStyle = 'rgba(255, 255, 255, 0.6)';
                ctx.lineWidth = 1.5;
                ctx.strokeRect(x, y, w, h);
                
                // Fibonacci label
                if (i < spiralPoints.length) {
                    ctx.fillStyle = '#fff';
                    ctx.font = '11px Helvetica Neue';
                    ctx.globalAlpha = 1.0;
                    ctx.fillText(`F(${i+1})`, x + 5, y + 15);
                }
            });
        }
        
        function drawSpiral() {
            if (!showSpiral || spiralPoints.length < 2) return;
            
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            
            // Draw spiral curve
            ctx.beginPath();
            ctx.moveTo(spiralPoints[0][0] + centerX, spiralPoints[0][1] + centerY);
            
            for (let i = 1; i < spiralPoints.length; i++) {
                ctx.lineTo(spiralPoints[i][0] + centerX, spiralPoints[i][1] + centerY);
            }
            
            ctx.strokeStyle = '#fff';
            ctx.lineWidth = 3;
            ctx.shadowColor = '#667eea';
            ctx.shadowBlur = 15;
            ctx.globalAlpha = 0.9;
            ctx.stroke();
            ctx.shadowBlur = 0;
            
            // Draw spiral points
            spiralPoints.forEach((point, i) => {
                ctx.beginPath();
                ctx.arc(point[0] + centerX, point[1] + centerY, 4, 0, Math.PI * 2);
                ctx.fillStyle = colors[i] || '#667eea';
                ctx.globalAlpha = 0.8;
                ctx.fill();
            });
        }
        
        function draw() {
            // Fade effect
            ctx.fillStyle = 'rgba(26, 26, 46, 0.15)';
            ctx.globalAlpha = 1.0;
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            
            drawRectangles();
            drawSpiral();
            
            if (animationId) {
                time++;
                animationId = requestAnimationFrame(draw);
            }
        }
        
        function toggleAnimation() {
            if (animationId) {
                cancelAnimationFrame(animationId);
                animationId = null;
            } else {
                time = 0;
                animationId = requestAnimationFrame(draw);
            }
        }
        
        function toggleSpiral() {
            showSpiral = !showSpiral;
            draw();
        }
        
        function increaseDepth() {
            currentDepth = Math.min(currentDepth + 1, 12);
            alert('Depth increased to ' + currentDepth + '. Regenerate needed.');
        }
        
        function decreaseDepth() {
            currentDepth = Math.max(currentDepth - 1, 2);
            alert('Depth decreased to ' + currentDepth + '. Regenerate needed.');
        }
        
        function resetView() {
            if (animationId) {
                cancelAnimationFrame(animationId);
                animationId = null;
            }
            time = 0;
            ctx.fillStyle = '#1a1a2e';
            ctx.globalAlpha = 1.0;
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            showSpiral = true;
            draw();
        }
        
        // Initial draw
        resetView();
    </script>
</body>
</html>"
              *phi*
              depth
              (length rects)
              width
              height
              depth
              (write-to-string rects)
              (write-to-string spiral)
              (write-to-string colors))))

(defun save-proportion-html (&key (filename "golden-ratio-proportion.html")
                                  (width 1200) (height 800) (depth 8))
  "Save the golden ratio proportion visualization to an HTML file"
  (let ((html-content (generate-proportion-html 
                       :width width 
                       :height height 
                       :depth depth)))
    (with-open-file (stream filename
                           :direction :output
                           :if-exists :supersede
                           :external-format :utf-8)
      (write-string html-content stream))
    (format t "Golden ratio proportion visualization saved to: ~A~%" filename)
    filename))

;;; ============================================================
;;; 10. Usage Examples
;;; ============================================================

;; Example 1: Generate Fibonacci sequence
;; (fibonacci-sequence 15)
;; => (1 1 2 3 5 8 13 21 34 55 89 144 233 377 610)

;; Example 2: Golden split
;; (golden-split 1000 618 :vertical t)
;; => ((0 0 618.0 618) (618.0 0 382.0 618))

;; Example 3: Recursive golden分割
;; (golden-recursive-split 1200 800 5)
;; => List of 32 rectangles

;; Example 4: Generate spiral
;; (generate-golden-spiral 10 1.0)
;; => List of (x y fib) points

;; Example 5: Convergence analysis
;; (display-convergence 15)
;; Shows table of F(n+1)/F(n) converging to φ

;; Example 6: Generate and save HTML visualization
;; (save-proportion-html :filename "golden.html" :depth 10)

;; Example 7: Beauty index
;; (calculate-beauty-index 1618 1000)
;; => Close to 1.0 (perfect golden ratio)

;; Example 8: Color harmony
;; (generate-color-harmony 200 :mode :golden)
;; => Three harmonious hues based on golden ratio

;;; ============================================================
;;; End of golden-ratio-proportion.lisp
;;; ============================================================
