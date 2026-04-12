# GAKURI (楽理) — Emotional Jazz Chord Progression Generator

> 論文ドリブン — Paper-driven Common Lisp framework for generating エモい (emotionally resonant) jazz chord progressions

**SAKURA Lab (音ラボ) — Zappa**

---

## Overview

GAKURI generates jazz chord progressions optimized for emotional impact across **10 mood profiles**:

| Mood | Tension Arc | Vibe |
|------|------------|------|
| `:ballad` | Descending | Warm, resolving |
| `:bebop` | Fluctuating | Energetic, complex |
| `:melancholic` | Concave | Introspective, minor |
| `:uplifting` | Ascending | Hopeful, bright |
| `:yearning` | Convex | Arch — peak then resolve |
| `:noir` | Ascending (extreme) | Dark, brooding |
| `:neo-soul` | Fluctuating (moderate) | Smooth, unexpected |
| `:peaceful` | Descending (gentle) | Calm, sparse |
| `:dramatic` | Convex (extreme) | High contrast, cinematic |
| `:bittersweet` | Concave (moderate) | Joy + sadness |

---

## Quick Start

```lisp
;; Load
(asdf:load-system :gakuri)
(use-package :gakuri)

;; Generate a yearning progression in C major (10 chords)
(generate-emotional-progression 0 :mood :yearning :length 10)
;; => (:PROGRESSION (#<CHORD Dm9> #<CHORD G7#11> ...)
;;     :EVALUATION #<EVALUATION-RESULT ...>
;;     :TENSION-CURVE (0.32 0.78 0.15 ...)
;;     :MATCH-SCORE 0.08)

;; Batch: 5 progressions × 4 moods in C major
(generate-batch 0 :moods '(:ballad :noir :neo-soul :bittersweet)
                  :per-mood 5 :length 12)

;; Export as Roman numerals
(export-progression-text progression
                         (make-key-signature :root 0 :mode :major)
                         :format :roman)
;; => ("ii9" "V7#11" "Imaj9" "iii7" "vi9" "ii7" "V13" "I6/9")
```

---

## Architecture

```
music-theory.lisp    → Pitch classes, chords, TIS (DFT-based representation)
tension-model.lisp   → 4-component tension (Herremans & Chuan 2020)
voice-leading.lisp   → Optimal voice assignment, smoothness scoring
progression-gen.lisp → Markov chains, tritone subs, modal interchange, altered dominants
evaluator.lisp       → 6-metric evaluation (smoothness, coherence, arc, emotion, complexity, novelty)
emotional-profiles   → 10 target tension curves
database.lisp        → In-memory storage & retrieval
```

---

## Academic Paper

See [`paper.md`](paper.md) for the full academic paper with 26 references covering:
- Computational models of tonal tension
- Jazz harmony theory
- Algorithmic chord generation
- Emotional perception of music
- Voice leading & harmony

---

## Dependencies

- **SBCL** 2.0+ (or any modern Common Lisp implementation)
- **ASDF** 3 (build system)
- **Alexandria** (utility library)
- **Serapeum** (extended utilities)
- **Rove** (testing framework)

```lisp
(ql:quickload :alexandria)
(ql:quickload :serapeum)
(ql:quickload :rove)
```

---

## Running Tests

```lisp
(asdf:test-system :gakuri)
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Common Lisp** | Symbolic manipulation, macro system, interactive development |
| **TIS-based tension** | Empirically validated (ρ = 0.750 with human perception) |
| **Generate-and-test (50 candidates)** | Simple, effective, no hyperparameter tuning needed |
| **6 evaluation metrics** | Orthogonal dimensions of emotional quality |
| **10 emotional profiles** | Covers jazz idioms from ballad to noir |

---

## 🎧 How to Listen

### Option 1: HTML Player (Easiest — No Install)

Open [`player.html`](player.html) in your browser. Click any mood card to hear the progression:

| Feature | Detail |
|---------|--------|
| **10 moods** | Ballad, Bebop, Yearning, Noir, Neo-Soul, etc. |
| **Audio** | Web Audio API synthesized chords (triangle + sine harmonics) |
| **Visual** | Real-time chord highlighting, tension curve display |

### Option 2: Python MIDI Player

```bash
# Install dependencies (pick one)
pip install pygame              # Basic playback
pip install pyfluidsynth        # Better quality (needs SoundFont)
pip install pretty_midi         # For analysis

# Play
python play_midi.py --demo                    # Demo mode
python play_midi.py midi-output/gakuri-yearning.mid  # Specific file
python play_midi.py --batch                   # Play all generated
python play_midi.py --analyze file.mid        # Show analysis
python play_midi.py --list-instruments        # List MIDI instruments
```

### Option 3: From Common Lisp (Full GAKURI pipeline)

```lisp
(asdf:load-system :gakuri)
(use-package :gakuri)

;; Generate + export MIDI
(let* ((key (make-key-signature :root 0 :mode :major))
       (result (progression-for-mood key :mood :yearning :length 8))
       (prog (getf result :progression)))
  (progression-to-midi prog :output-file "yearning.mid"
                            :tempo 600000   ; 100 BPM
                            :program 0      ; Piano
                            :octave 3))
```

Then play: `python play_midi.py yearning.mid`

### Recommended Instruments for Jazz

| Program | Name | Vibe |
|---------|------|------|
| 0 | Acoustic Grand Piano | Classic |
| 4 | Electric Piano (Rhodes) | Smooth jazz |
| 11 | Vibraphone | Cool jazz |
| 26 | Electric Guitar (jazz) | Guitar trio |
| 48 | String Ensemble | Lush ballads |
| 66 | Tenor Sax | Bebop lead |

---

## License

MIT
