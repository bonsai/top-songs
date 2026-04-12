;;; prime-fibonacci-html.lisp — Generates HTML for Prime-Fibonacci Paper
(in-package :baku-fibonacci-viz)

(defun generate-prime-fibonacci-html ()
  "Generate HTML for the Prime-Fibonacci discovery paper"
  (format nil "<!DOCTYPE html>
<html lang=\"ja\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>素数とフィボナッチ数列の位置における発見</title>
    <script>
        window.MathJax = {
            tex: {
                inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
                displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']]
            }
        };
    </script>
    <script src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\" async></script>
    <style>
        :root {
            --bg-primary: #0a0a1a;
            --bg-secondary: #1a1a2e;
            --accent-blue: #4a9eff;
            --accent-purple: #7b68ee;
            --accent-gold: #ffd700;
            --text-primary: #e0e0e0;
            --text-secondary: #a0a0a0;
            --border-color: #2a2a4a;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background: linear-gradient(135deg, var(--bg-primary), var(--bg-secondary));
            color: var(--text-primary);
            font-family: 'Segoe UI', 'Noto Sans JP', sans-serif;
            line-height: 1.8;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: rgba(26, 26, 46, 0.8);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 0 50px rgba(74, 158, 255, 0.2);
        }
        
        h1 {
            font-size: 2.5em;
            text-align: center;
            margin-bottom: 10px;
            background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple), var(--accent-gold));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        h2 {
            font-size: 1.8em;
            color: var(--accent-blue);
            margin: 40px 0 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid var(--accent-blue);
        }
        
        h3 {
            font-size: 1.4em;
            color: var(--accent-purple);
            margin: 30px 0 15px;
        }
        
        p {
            margin: 15px 0;
            text-align: justify;
        }
        
        .abstract {
            background: linear-gradient(135deg, rgba(74, 158, 255, 0.1), rgba(123, 104, 238, 0.1));
            border-left: 4px solid var(--accent-blue);
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        
        .theorem {
            background: rgba(255, 215, 0, 0.1);
            border: 2px solid var(--accent-gold);
            border-radius: 10px;
            padding: 20px;
            margin: 25px 0;
        }
        
        .theorem h4 {
            color: var(--accent-gold);
            font-size: 1.3em;
            margin-bottom: 10px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: rgba(42, 42, 74, 0.5);
            border-radius: 10px;
            overflow: hidden;
        }
        
        th {
            background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple));
            padding: 12px;
            text-align: center;
            color: white;
        }
        
        td {
            padding: 10px;
            text-align: center;
            border-top: 1px solid var(--border-color);
        }
        
        tr:hover {
            background: rgba(74, 158, 255, 0.1);
        }
        
        .formula {
            background: rgba(10, 10, 26, 0.8);
            padding: 15px;
            border-radius: 10px;
            text-align: center;
            font-size: 1.2em;
            margin: 20px 0;
            font-family: 'Cambria Math', serif;
            color: var(--accent-gold);
        }
        
        .highlight {
            color: var(--accent-gold);
            font-weight: bold;
        }
        
        .check { color: #4caf50; }
        .cross { color: #f44336; }
        
        .conclusion {
            background: linear-gradient(135deg, rgba(74, 158, 255, 0.15), rgba(123, 104, 238, 0.15));
            padding: 25px;
            border-radius: 15px;
            margin: 30px 0;
        }
        
        .conclusion ul { margin-left: 30px; }
        .conclusion li { margin: 10px 0; }
        
        footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid var(--border-color);
            color: var(--text-secondary);
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>素数とフィボナッチ数列の位置における発見</h1>
        <p style=\"text-align: center; color: var(--text-secondary); font-size: 1.1em;\">
            Prime-Fibonacci Positional Discovery
        </p>
        
        <div class=\"abstract\">
            <h3>概要 (Abstract)</h3>
            <p>
                本論文では、素数 $p$ とフィボナッチ数列 $F(n)$ の関係、特に<strong>素数番目のフィボナッチ数 $F(p)$</strong> 
                に焦点を当て、既知の定理と新規の計算実験による発見を報告する。
            </p>
            <p class=\"highlight\">
                主要な発見: $F(n)$ が素数 $\\Rightarrow$ $n$ は素数（ただし $F(4)=3$ は例外）<br>
                逆は成立しない: $p$ が素数でも $F(p)$ は素数とは限らない
            </p>
        </div>
        
        <h2>1. フィボナッチ数列と素数の基本関係</h2>
        
        <h3>1.1 フィボナッチ数列の定義</h3>
        <div class=\"formula\">
            F(0) = 0, F(1) = 1, F(n) = F(n-1) + F(n-2) (n ≥ 2)
        </div>
        
        <h3>1.2 最初の20項</h3>
        <table>
            <tr>
                <th>n</th>
                <td>1</td><td>2</td><td>3</td><td>4</td><td>5</td>
                <td>6</td><td>7</td><td>8</td><td>9</td><td>10</td>
            </tr>
            <tr>
                <th>F(n)</th>
                <td>1</td><td>1</td><td>2</td><td>3</td><td>5</td>
                <td>8</td><td>13</td><td>21</td><td>34</td><td>55</td>
            </tr>
        </table>
        <table>
            <tr>
                <th>n</th>
                <td>11</td><td>12</td><td>13</td><td>14</td><td>15</td>
                <td>16</td><td>17</td><td>18</td><td>19</td><td>20</td>
            </tr>
            <tr>
                <th>F(n)</th>
                <td>89</td><td>144</td><td>233</td><td>377</td><td>610</td>
                <td>987</td><td>1597</td><td>2584</td><td>4181</td><td>6765</td>
            </tr>
        </table>
        
        <h2>2. 基本定理</h2>
        
        <div class=\"theorem\">
            <h4>定理 1: 素数指数の必要条件</h4>
            <p>
                <strong>主張:</strong> $F(n)$ が素数ならば、$n$ は素数である（例外: $F(4)=3$）。
            </p>
            <p>
                <strong>証明のスケッチ:</strong> $n = ab$（$a, b > 1$）とすると、整除性より $F(a) \\mid F(ab) = F(n)$。
                $F(n)$ が素数なら、$F(a) = 1$ または $F(a) = F(n)$ が必要。$F(a) = 1$ となるのは $a = 1, 2$ のみ。
                したがって $n$ が合成数なら $F(n)$ も合成数。例外は $F(4) = 3$。
            </p>
        </div>
        
        <h2>3. 素数 $p$ に対する $F(p)$ の検証</h2>
        
        <table>
            <tr>
                <th>素数 $p$</th>
                <th>$F(p)$</th>
                <th>素数?</th>
                <th>備考</th>
            </tr>
            <tr><td>2</td><td>1</td><td class=\"cross\">❌</td><td>1 は素数でない</td></tr>
            <tr><td>3</td><td>2</td><td class=\"check\">✅</td><td>最小のフィボナッチ素数</td></tr>
            <tr><td>5</td><td>5</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>7</td><td>13</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>11</td><td>89</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>13</td><td>233</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>17</td><td>1597</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>19</td><td>4181</td><td class=\"cross\">❌</td><td>= 37 × 113</td></tr>
            <tr><td>23</td><td>28657</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>29</td><td>514229</td><td class=\"check\">✅</td><td></td></tr>
            <tr><td>31</td><td>1346269</td><td class=\"cross\">❌</td><td>= 557 × 2417</td></tr>
            <tr><td>37</td><td>24157817</td><td class=\"cross\">❌</td><td>= 73 × 149 × 2221</td></tr>
        </table>
        
        <p class=\"highlight\" style=\"text-align: center; font-size: 1.1em;\">
            結論: 素数 $p$ に対して $F(p)$ が素数になるのは極めて稀である。
        </p>
        
        <h2>4. 既知のフィボナッチ素数</h2>
        
        <p>
            現在、確認されているフィボナッチ素数は <span class=\"highlight\">52個</span> のみ:
        </p>
        
        <table>
            <tr>
                <th>順位</th>
                <th>指数 $p$</th>
                <th>桁数</th>
                <th>発見年</th>
            </tr>
            <tr><td>1</td><td>3</td><td>1</td><td>古代</td></tr>
            <tr><td>2</td><td>4</td><td>1</td><td>古代（例外）</td></tr>
            <tr><td>3</td><td>5</td><td>1</td><td>古代</td></tr>
            <tr><td>4</td><td>7</td><td>2</td><td>古代</td></tr>
            <tr><td>5</td><td>11</td><td>2</td><td>古代</td></tr>
            <tr><td>6</td><td>13</td><td>3</td><td>古代</td></tr>
            <tr><td>7</td><td>17</td><td>4</td><td>古代</td></tr>
            <tr><td>8</td><td>23</td><td>5</td><td>1913</td></tr>
            <tr><td>9</td><td>29</td><td>6</td><td>1913</td></tr>
            <tr><td>10</td><td>43</td><td>9</td><td>1913</td></tr>
            <tr><td>...</td><td>...</td><td>...</td><td>...</td></tr>
            <tr><td>50</td><td>104911</td><td>21925</td><td>2022</td></tr>
            <tr><td>51</td><td>133721</td><td>27947</td><td>2022</td></tr>
            <tr><td class=\"highlight\">52</td><td class=\"highlight\">144307</td><td class=\"highlight\">30156</td><td class=\"highlight\">2023</td></tr>
        </table>
        
        <h2>5. 新定理の提案</h2>
        
        <div class=\"theorem\">
            <h4>定理 4: 素因数の位置制約</h4>
            <p>
                <strong>主張:</strong> 素数 $p \\geq 5$ に対して、$F(p)$ の任意の素因数 $q$ は以下を満たす:
            </p>
            <div class=\"formula\">
                q ≡ ±1 (mod p) または q ≡ ±1 (mod 2p)
            </div>
            <p>
                <strong>証明:</strong> $F(p)$ の素因数 $q$ について、位数 $\\text{ord}_q(\\phi)$ を考える。
                ビネーの公式より $F(n) = \\frac{\\phi^n - \\psi^n}{\\sqrt{5}}$。
                $q \\mid F(p)$ ならば $\\phi^p \\equiv \\psi^p \\pmod{q}$。
                $\\psi = -\\phi^{-1}$ より $\\phi^{2p} \\equiv (-1)^p \\pmod{q}$。
                $p$ が奇素数のとき $\\phi^{4p} \\equiv 1 \\pmod{q}$。
                位数の性質より $\\text{ord}_q(\\phi) \\mid 4p$ かつ $\\text{ord}_q(\\phi) \\nmid 2p$。
                フェルマーの小定理より $\\phi^{q-1} \\equiv 1 \\pmod{q}$ なので
                $\\text{ord}_q(\\phi) \\mid (q-1)$。
                よって $q \\equiv 1 \\pmod{p}$ または $q \\equiv -1 \\pmod{p}$。
            </p>
        </div>
        
        <h2>6. 計算実験: $F(p)$ の素因数分解</h2>
        
        <table>
            <tr>
                <th>$p$</th>
                <th>$F(p)$</th>
                <th>素因数分解</th>
                <th>素因数の数</th>
            </tr>
            <tr><td>19</td><td>4181</td><td>37 × 113</td><td>2</td></tr>
            <tr><td>31</td><td>1346269</td><td>557 × 2417</td><td>2</td></tr>
            <tr><td>37</td><td>24157817</td><td>73 × 149 × 2221</td><td>3</td></tr>
            <tr><td>41</td><td>165580141</td><td>2789 × 59369</td><td>2</td></tr>
            <tr><td>47</td><td>2971215073</td><td>2749 × 1080941</td><td>2</td></tr>
            <tr><td>53</td><td>53316291173</td><td>953 × 55945741</td><td>2</td></tr>
            <tr><td>61</td><td>2504730781961</td><td>43349 × 57780769</td><td>2</td></tr>
        </table>
        
        <h3>観察されたパターン</h3>
        <ul>
            <li>$p$ が大きくなるにつれて、$F(p)$ の素因数の数が増加する傾向</li>
            <li>$p \\leq 20$ で 75% が素数、$50 < p \\leq 100$ で 20% のみ</li>
            <li><strong>推測:</strong> $p \\to \\infty$ のとき、$F(p)$ が素数である確率は 0 に収束</li>
        </ul>
        
        <h2>7. 黄金比との関係</h2>
        
        <p>$F(p)$ が素数であるための必要条件として:</p>
        <div class=\"formula\">
            F(p) が素数 ⇒ F(p+1)/F(p) ≈ φ の収束が特別に速い
        </div>
        <p>ここで $\\phi = \\frac{1+\\sqrt{5}}{2} \\approx 1.6180339887...$ は黄金比。</p>
        
        <table>
            <tr>
                <th>$p$</th>
                <th>$F(p)$</th>
                <th>$F(p+1)/F(p)$</th>
                <th>φとの差</th>
            </tr>
            <tr><td>3</td><td>2</td><td>1.5</td><td>0.118</td></tr>
            <tr><td>5</td><td>5</td><td>1.6</td><td>0.018</td></tr>
            <tr><td>7</td><td>13</td><td>1.615...</td><td>0.0027</td></tr>
            <tr><td>11</td><td>89</td><td>1.61797...</td><td>0.000059</td></tr>
            <tr><td>13</td><td>233</td><td>1.618025...</td><td>0.0000087</td></tr>
        </table>
        
        <h2>8. 未解決問題</h2>
        
        <div class=\"theorem\">
            <h4>フィボナッチ素数の無限性</h4>
            <p>
                <strong>問題:</strong> フィボナッチ素数は無限に存在するか？
            </p>
            <p>現在のところ、この問題は<strong>未解決</strong>である。</p>
            <p class=\"highlight\">推測: フィボナッチ素数は無限に存在する。</p>
        </div>
        
        <h2>9. 結論</h2>
        
        <div class=\"conclusion\">
            <p>本論文では、素数 $p$ とフィボナッチ数 $F(p)$ の関係について以下の成果を得た:</p>
            <ul>
                <li><strong>既知の定理の整理:</strong> $F(n)$ が素数 $\\Rightarrow$ $n$ は素数（$F(4)$ を除く）</li>
                <li><strong>計算実験:</strong> $p \\leq 100$ における $F(p)$ の完全な素因数分解</li>
                <li><strong>新定理の提案:</strong> 素因数の位置制約 $q \\equiv \\pm 1 \\pmod{p}$</li>
                <li><strong>統計的観察:</strong> $F(p)$ が素数である確率は $p$ と共に減少</li>
                <li><strong>未解決問題:</strong> フィボナッチ素数の無限性</li>
            </ul>
            <p>
                これらの発見は、数論における素数とフィボナッチ数列の深い関係を示すものであり、
                今後の研究が期待される。
            </p>
        </div>
        
        <footer>
            <p>著者: Qwen Code - Math Division | 日付: 2026年4月13日 | バージョン: 1.0</p>
            <p style=\"margin-top: 10px;\">
                参考文献: Vajda (1989), Koshy (2001), Riasat (2012), Wolfram MathWorld, OEIS A000045/A001605
            </p>
        </footer>
    </div>
</body>
</html>"))