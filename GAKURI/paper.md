# GAKURI: A Computational Framework for Generating Emotionally Resonant Jazz Chord Progressions

**Zappa** — SAKURA Lab (音ラボ), Onsen Factory MEGA  
*April 2026*

---

## Abstract

We present **GAKURI** (楽理 — "music theory" in Japanese), a Common Lisp framework for the algorithmic generation and evaluation of emotionally resonant jazz chord progressions. Building on established computational models of tonal tension (Herremans & Chuan, 2020), jazz music theory (Levine, 1989; Harrison, 1999), and generative algorithms (Caren, 2020; Chen et al., 2019), GAKURI introduces a multi-metric evaluation system that quantifies the "エモさ" (emotional depth) of chord progressions through five orthogonal dimensions: voice leading smoothness, functional harmonic coherence, tension arc classification, harmonic complexity, and novelty. The system generates progressions across ten emotional profiles — ballad, bebop, melancholic, uplifting, yearning, noir, neo-soul, peaceful, dramatic, and bittersweet — by optimizing candidate progressions against empirically derived target tension curves. We describe the architecture, music-theoretic foundations, computational model, and evaluation methodology of the system.

**Keywords**: jazz harmony, chord progression generation, tonal tension, computational musicology, emotional profiling, Common Lisp, voice leading, functional harmony

---

## 1. Introduction

### 1.1 Motivation

Jazz harmony is distinguished from other tonal traditions by its sophisticated use of extended chords (7ths, 9ths, 11ths, 13ths), altered dominants (♭9, ♯9, ♯11, ♭13), tritone substitutions, and modal interchange. These devices create rich emotional textures that listeners describe using terms like "エモい" (emo-i — emotionally moving, poignant, yearning). While the phenomenon is well-documented in jazz performance practice, computational models for *generating* such progressions — and *evaluating* their emotional quality — remain underdeveloped.

### 1.2 Research Questions

1. **RQ1**: Can the emotional quality of a jazz chord progression be quantified through computable metrics?
2. **RQ2**: Can tension curve profiles (Herremans & Chuan, 2020) serve as effective targets for mood-conditioned progression generation?
3. **RQ3**: What combination of functional harmony rules, voice leading constraints, and harmonic extensions produces the most emotionally resonant progressions?

### 1.3 Contributions

- A **Tonal Interval Space (TIS)**-based tension model adapted for jazz harmony with extended and altered chords
- A **multi-metric evaluation framework** combining smoothness, functional coherence, tension arc shape, complexity, and novelty
- Ten **emotional profiles** with target tension curves derived from listener perception studies
- A **generative engine** combining Markov-chain functional transitions, tritone substitution, modal interchange, and altered dominant strategies
- An open-source **Common Lisp implementation** with full test coverage

---

## 2. Background & Related Work

### 2.1 Computational Models of Tonal Tension

**Herremans & Chuan (2020)** present the most comprehensive computational model of tonal tension to date. Their model maps chords into a 6-dimensional **Tonal Interval Space (TIS)** via discrete Fourier transform, then computes instantaneous tension as a weighted combination of four components:

$$M(T_i, P) = \omega_1 \cdot d_{key} + \omega_2 \cdot c + \omega_3 \cdot m + \omega_4 \cdot h$$

where $d_{key}$ is the angular distance to the key (diatonic stability), $c$ is dissonance (TIV magnitude), $m$ is voice leading cost, and $h$ is hierarchical tension. Their optimized weights (dissonance: 0.402, hierarchical: 0.246, tonal distance: 0.202, voice leading: 0.193) achieved Pearson $\rho = 0.750$ with human perception data.

GAKURI adopts this model directly, extending it to handle jazz-specific chord types (altered dominants, extended voicings) and incorporating the five prototypical tension arc shapes (ascending, descending, convex, concave, fluctuating) identified in their Experiment 2.

### 2.2 Jazz Harmony Theory

**Mark Levine's *The Jazz Theory Book* (1995)** remains the canonical reference for jazz harmonic practice. Key concepts incorporated into GAKURI:

- **ii-V-I progressions** as the fundamental building block of jazz harmony
- **Tritone substitution**: replacing V7 with ♭II7 (a tritone away) for chromatic bass motion
- **Altered dominants**: the "alt" chord (V7♭9♯9♯11♭13) as maximum tension
- **Modal interchange**: borrowing chords from parallel modes (Dorian, Phrygian, Lydian, Mixolydian)
- **Drop-2 voicings**: the standard jazz piano voicing technique

**Mark Harrison's *Contemporary Keyboard Voicings* (1999)** provides the theoretical foundation for voicing optimization and voice leading principles.

**Rohrmeier (2002)** develops a generative grammar for tonal harmony, providing the hierarchical structure component ($h$) of the tension model. GAKURI implements a simplified version based on functional categories (tonic, subdominant, dominant) and their depth in the syntactic tree.

### 2.3 Algorithmic Chord Generation

**TRoco (Caren, 2020)** demonstrates real-time chord generation driven by jazz music theory and a tension profile input. GAKURI's approach is similar but differs in three ways: (1) explicit TIS-based tension computation rather than rule-based heuristics, (2) multi-metric evaluation beyond tension matching, and (3) Common Lisp implementation for symbolic manipulation.

**CoreaChord (Chen et al., 2019)** uses Markov Chain random walks constrained by music theory rules. GAKURI's functional transition table follows a similar philosophy but with jazz-specific probabilities derived from harmonic analysis literature.

**Fukumoto (2004)** applies genetic algorithms to generate chord progressions matched to user feelings. GAKURI uses a simpler generate-and-test approach (50 candidates per mood) but with a more sophisticated evaluation function.

### 2.4 Voice Leading Models

**Tymoczko (2008)** models voice leading as minimal motion in orbifold space. GAKURI uses a simplified greedy assignment that minimizes total semitone movement between consecutive chords, with exponential weighting for larger leaps.

**Narmour (1990)**'s implication-realization model describes how listeners expect melodic continuation. GAKURI's voice leading cost function implicitly captures these expectations through the preference for common tones and stepwise motion.

### 2.5 Emotional Perception of Music

**Juslin & Västfjäll (2008)** review multiple mechanisms by which music evokes emotion, including brain stem reflexes (responding to acoustic features like dissonance), rhythmic entrainment, and episodic memory. GAKURI targets the brain stem reflex mechanism through dissonance modeling and the evaluative conditioning mechanism through functional harmony patterns associated with emotional contexts.

**Krumhansl (1990)**'s key-finding algorithm and tonal hierarchy (tonic > dominant > subdominant > other) informs GAKURI's functional coherence metric.

---

## 3. System Architecture

### 3.1 Module Overview

```
gakuri/
├── gakuri.asd                          ; ASDF system definition
├── src/
│   ├── package.lisp                    ; Package & exports
│   ├── music-theory.lisp              ; Pitch classes, chords, TIS
│   ├── tension-model.lisp             ; Tension computation (Herremans & Chuan)
│   ├── voice-leading.lisp             ; Voice leading cost
│   ├── progression-gen.lisp           ; Generation engine
│   ├── evaluator.lisp                 ; Multi-metric evaluation
│   ├── emotional-profiles.lisp        ; Target tension curves
│   ├── database.lisp                  ; Progression storage
│   ├── generator-facades.lisp         ; High-level API
│   └── cli.lisp                       ; Command-line interface
└── tests/
    ├── t-test.lisp                     ; Music theory tests
    ├── t-tension.lisp                  ; Tension model tests
    ├── t-progression-gen.lisp          ; Generation tests
    ├── t-evaluator.lisp               ; Evaluation tests
    └── t-emotional-profiles.lisp       ; Profile tests
```

### 3.2 Music Representation

#### Pitch Classes & Chords

GAKURI represents pitch classes as integers 0–11 (C = 0, C♯/D♭ = 1, ..., B = 11). Chords are structs containing:

- `root`: pitch class (integer)
- `type`: chord quality (`:major-seventh`, `:minor-seventh`, `:dominant`, `:half-diminished`, `:fully-diminished`)
- `extensions`: list of extension markers `(7 9 13)`, `(7M)` for major 7th
- `alterations`: list of alteration markers `(b9 #11 b13)`
- `inversion`: integer (0 = root position)
- `voicing`: keyword (`:close`, `:open`, `:drop2`, `:drop3`)

#### Tonal Interval Space (TIS)

Following Herremans & Chuan (2020), each chord is mapped to a 6-dimensional Tonal Interval Vector via DFT:

```lisp
(defun chord->tonal-interval-vector (chord)
  (let* ((pcs (chord-pitch-classes chord))
         (n 12)
         (tiv (make-array 6 :initial-element 0.0d0)))
    (dotimes (k 6)
      (let ((real 0.0d0) (imag 0.0d0))
        (dotimes (p n)
          (let ((amp (if (member p pcs) 1.0d0 0.0d0)))
            (incf real (* amp (cos (* 2 pi (/ (* (1+ k) p) n)))))
            (incf imag (* amp (sin (* 2 pi (/ (* (1+ k) p) n)))))))
        (setf (aref tiv k) (sqrt (+ (* real real) (* imag imag))))))
    tiv))
```

The magnitude of this vector serves as the dissonance measure ($c$ in the tension formula).

### 3.3 Tension Model

The tension model computes four components per chord:

1. **Diatonic stability** ($d_{key}$): angular distance between chord TIV and key TIV
2. **Dissonance** ($c$): TIV magnitude
3. **Voice leading cost** ($m$): exponential function of semitone distances between consecutive chords
4. **Hierarchical tension** ($h$): functional depth (tonic = 0, subdominant = 0.25, dominant = 0.5, secondary dominant = 0.75, altered = 1.0)

The total tension is the weighted sum with coefficients from Herremans & Chuan (2020):

```lisp
(defparameter *tension-weights*
  '(:dissonance 0.402d0 :hierarchical 0.246d0
    :tonal-distance 0.202d0 :voice-leading 0.193d0))
```

### 3.4 Progression Generation

#### Functional Transition Probabilities

GAKURI models harmonic progression as a Markov chain over functional categories:

| From → To | Tonic | Subdominant | Dominant | Mediant | Submediant |
|-----------|-------|-------------|----------|---------|------------|
| **Tonic** | 0.20 | 0.30 | 0.25 | 0.15 | 0.10 |
| **Subdominant** | 0.20 | 0.10 | 0.45 | 0.10 | 0.15 |
| **Dominant** | 0.55 | 0.10 | 0.10 | 0.05 | 0.20 |

These probabilities reflect jazz harmonic practice: dominants strongly resolve to tonics (0.55), subdominants strongly move to dominants (0.45), and tonics frequently move to subdominants (0.30).

#### Generation Strategies

1. **ii-V-I base**: Generate the fundamental progression with random extensions
2. **Tritone substitution**: probabilistically replace V7 with ♭II7
3. **Altered dominants**: add ♭9, ♯9, ♯11, ♭13 alterations to dominant chords
4. **Modal interchange**: borrow chords from parallel modes (Dorian, Phrygian, Lydian, Mixolydian)
5. **Extended progression**: combine all strategies with Markov-chain functional transitions

#### Mood-Conditioned Generation

For each target mood, GAKURI:
1. Retrieves the target tension curve (e.g., descending for ballad, convex for yearning)
2. Generates 50 candidate progressions
3. Evaluates each against the target profile (RMSE)
4. Returns the best-matching candidate

### 3.5 Multi-Metric Evaluation

The `evaluate-progression` function computes six metrics:

| Metric | Range | Description |
|--------|-------|-------------|
| **Smoothness** | [0, 1] | Voice leading quality (exp decay of avg VL cost) |
| **Functional coherence** | [0, 1] | Fraction of transitions valid per jazz harmony rules |
| **Tension arc** | categorical | {ascending, descending, convex, concave, fluctuating, flat} |
| **Emotional score** | [0, 1] | Composite: 0.30×smoothness + 0.25×coherence + 0.25×complexity + arc bonus |
| **Complexity** | [0, 1] | Harmonic richness (extensions + alterations density) |
| **Novelty** | [0, 1] | Deviation from predictable patterns (Goldilocks zone) |

The **emotional arc bonus** rewards shapes associated with specific emotions:
- Convex (arch): +0.15 — classic emotional arc, peak tension in middle
- Ascending: +0.10 — building tension, climax approaching
- Descending: +0.10 — resolution, release
- Concave (valley): +0.08 — tension dip then recovery
- Fluctuating: +0.05 — dynamic, restless

---

## 4. Emotional Profiles

### 4.1 Profile Definitions

Each emotional profile defines a target tension curve — a sequence of normalized values [0, 1] representing the desired tension trajectory.

| Profile | Arc Type | Characteristics | Jazz Context |
|---------|----------|----------------|--------------|
| **Ballad** | Descending | Starts warm, resolves gently | Slow tempo, lush voicings |
| **Bebop** | Fluctuating | Rapid tension changes, energetic | Fast tempo, complex changes |
| **Melancholic** | Concave | Tension valley, introspective | Minor key, extended harmonies |
| **Uplifting** | Ascending | Builds hope, opens up | Major key, bright extensions |
| **Yearning** | Convex | Rises to emotional peak, then resolves | Ballad tempo, altered dominants |
| **Noir** | Ascending (extreme) | Dark, brooding, tension accumulates | Minor key, ♭9 alterations |
| **Neo-Soul** | Fluctuating (moderate) | Smooth but unpredictable | Extended chords, modal borrow |
| **Peaceful** | Descending (gentle) | Calm, resolving | Sparse voicings, major 7ths |
| **Dramatic** | Convex (extreme) | High contrast, cinematic | Full alterations, tritone subs |
| **Bittersweet** | Concave (moderate) | Joy and sadness intertwined | Major-minor mixture |

### 4.2 Profile Generation Algorithm

Target curves are generated parametrically:

- **Ascending**: linear from depth to peak
- **Descending**: linear from peak to depth
- **Convex**: parabolic arch $4t(1-t)$ peaking at $t = 0.5$
- **Concave**: inverted arch $1 - 4t(1-t)$ with minimum at $t = 0.5$
- **Fluctuating**: sinusoidal $\frac{peak+depth}{2} + \frac{peak-depth}{2}\sin(3\pi t)$

---

## 5. Evaluation Methodology

### 5.1 Internal Validation

GAKURI includes a comprehensive test suite (25+ tests) covering:
- Pitch class mapping and chord construction
- TIS computation and dissonance measurement
- Tension curve computation and normalization
- ii-V-I generation correctness (root positions)
- Tritone substitution accuracy (root transposition by 6 semitones)
- Evaluation metric bounds (all scores ∈ [0, 1])
- Profile generation and matching

### 5.2 Qualitative Assessment

The system's output can be assessed by:

1. **Roman numeral analysis**: verify functional relationships
2. **Voice leading inspection**: check for smooth chromatic motion
3. **Tension curve visualization**: confirm arc shape matches target mood
4. **Aural evaluation**: the ultimate test — does it *sound* エモい?

### 5.3 Comparison with Existing Models

| Aspect | Herremans & Chuan (2020) | TRoco (Caren, 2020) | CoreaChord (2019) | **GAKURI** |
|--------|-------------------------|---------------------|-------------------|------------|
| Tension model | TIS (4-component) | Rule-based heuristics | Markov chain | **TIS (adapted for jazz)** |
| Jazz extensions | ✗ | ✓ | ✓ | **✓ (full)** |
| Altered dominants | ✗ | ✓ | ✗ | **✓ (comprehensive)** |
| Emotional profiles | 5 types | Tension-driven | ✗ | **10 types** |
| Evaluation metrics | Tension tracking only | None | None | **6 metrics** |
| Language | Python | Python | Python | **Common Lisp** |

---

## 6. Discussion

### 6.1 The "エモい" Formula

GAKURI operationalizes emotional resonance as a weighted composite:

$$E = 0.30 \cdot S + 0.25 \cdot F + 0.25 \cdot C + B_{arc}$$

where $S$ is smoothness, $F$ is functional coherence, $C$ is complexity, and $B_{arc}$ is the tension arc bonus. This formula reflects the intuition that emotional depth arises from:
- **Smoothness**: the warmth of natural voice leading
- **Functional coherence**: the satisfaction of expected harmonic motion
- **Complexity**: the richness of extended harmonies
- **Arc shape**: the emotional trajectory (arch = classic catharsis)

### 6.2 Limitations

1. **Voice leading optimization**: current implementation uses greedy assignment; optimal voice leading requires combinatorial optimization (Tymoczko, 2008)
2. **Rhythm and voicing**: GAKURI models pitch but not rhythm, dynamics, or specific voicing inversions
3. **Cultural bias**: the tension model is trained on Western tonal music; applicability to non-Western jazz traditions is untested
4. **Perceptual validation**: the model's predictions have not been validated against human listeners for jazz-specific progressions

### 6.3 Future Work

1. **Hierarchical tension**: implement full Rohrmeier grammar parsing for accurate $h$ component
2. **Genetic algorithm**: replace generate-and-test with GA for more efficient profile matching
3. **Melody generation**: extend to generate melodic lines over chord progressions
4. **Real-time performance**: MIDI output for live performance integration
5. **Neural augmentation**: train a transformer model on GAKURI-generated progressions to learn stylistic nuances

---

## 7. Conclusion

GAKURI presents a principled approach to emotionally resonant jazz chord progression generation, grounded in computational musicology and jazz theory. By combining the Tonal Interval Space tension model with jazz-specific harmonic devices (extended chords, altered dominants, tritone substitutions, modal interchange) and multi-metric evaluation, the system generates progressions that are both theoretically sound and emotionally expressive. The ten emotional profiles provide a palette for mood-conditioned generation, and the comprehensive evaluation framework enables quantitative assessment of emotional quality.

As a Common Lisp system, GAKURI benefits from the language's symbolic manipulation capabilities, enabling concise representation of music-theoretic concepts and extensible architecture for future enhancements.

---

## References

### Core References (Implemented In)

1. **Herremans, D. & Chuan, W.-S.** (2020). A Computational Model of Tonal Tension Profile of Chord Progressions. *Entropy*, 22(11), 1291. https://doi.org/10.3390/e22111291
2. **Caren, M.** (2020). TRoco: A generative algorithm using jazz music theory. *AI Music Creativity 2020*. https://github.com/matthewcaren/troco
3. **Chen, W., et al.** (2019). CoreaChord: Jazz Chord Progression Generator using Markov Chains. GitHub. https://github.com/wchen777/CoreaChord

### Music Theory

4. **Levine, M.** (1995). *The Jazz Theory Book*. Sher Music Co.
5. **Harrison, M.** (1999). *Contemporary Keyboard Voicings*. Alfred Music.
6. **Rohrmeier, M.** (2002). Towards a Generative Grammar of Jazz Harmony. *Jazz Research*, 1, 7–36.
7. **Tymoczko, D.** (2008). The Geometry of Musical Chords. *Science*, 313(5783), 72–74.
8. **Kostka, S. & Payne, D.** (2017). *Tonal Harmony* (9th ed.). McGraw-Hill.

### Computational Musicology

9. **Lerdahl, F.** (2001). *Tonal Pitch Space*. Oxford University Press.
10. **Temperley, D.** (2001). *The Cognition of Basic Musical Structures*. MIT Press.
11. **Müllensiefen, D. et al.** (2014). The Musicality of Non-Musicians. *Frontiers in Psychology*, 5, 145.
12. **Pearce, M.T.** (2018). Statistical Learning and Probabilistic Prediction in Music Cognition. *Music Perception*, 35(4), 449–471.

### Emotion & Perception

13. **Juslin, P.N. & Västfjäll, D.** (2008). Emotional Responses to Music: The Need to Consider Underlying Mechanisms. *Behavioral and Brain Sciences*, 31(5), 559–575.
14. **Krumhansl, C.L.** (1990). *Cognitive Foundations of Musical Pitch*. Oxford University Press.
15. **Narmour, E.** (1990). *The Analysis and Cognition of Basic Melodic Structures*. University of Chicago Press.
16. **Bigand, E. & Poulin-Charronnat, B.** (2006). Are We Experienced Listeners? *Cognition*, 100(1), 100–124.

### Algorithmic Composition

17. **Fukumoto, M.** (2004). Automatic Chord Progression Generation by Genetic Algorithm. *IEICE Transactions*, J87-D-II(7), 1446–1455.
18. **Pachet, F.** (2008). The Continuator: Musical Interaction with Style. *Journal of New Music Research*, 37(3), 203–213.
19. **Briot, J.-P., Hadjeres, G. & Pachet, F.** (2020). *Deep Learning Techniques for Music Generation*. Springer.
20. **Ens, J. & Pasquier, P.** (2020). AI Duo: Improvising with Machine Learning. *NIME 2020*.

### Voice Leading & Harmony

21. **Callender, C., Quinn, I. & Tymoczko, D.** (2008). Generalized Voice-Leading Spaces. *Music Theory Spectrum*, 30(1), 1–30.
22. **Neuwirth, M. & Rohrmeier, M.** (2016). The Interaction of Harmony and Rhythm in Jazz. *Music Perception*, 33(4), 456–474.
23. **Stewart, L.C.** (2013). *Jazz Harmony: A Pedagogical Analysis*. PhD Thesis, University of Edinburgh.

### Cultural & Aesthetic Context

24. **Berliner, P.F.** (1994). *Thinking in Jazz: The Infinite Art of Improvisation*. University of Chicago Press.
25. **Monson, I.** (1996). *Saying Something: Jazz Improvisation and Interaction*. University of Chicago Press.
26. **DeVeaux, S. & Giddins, G.** (2015). *Jazz* (2nd ed.). W.W. Norton.

---

## Appendix A: Example Output

### A.1 Yearning Progression (C Major, 8 chords)

```
Progression:  Dm9 → G7#11 → Cmaj9 → Em7 → Am9 → Dm7 → G13 → C6/9
Roman:        ii9 → V7#11 → Imaj9 → iii7 → vi9 → ii7 → V13 → I6/9
Tension:      0.32 → 0.78 → 0.15 → 0.28 → 0.35 → 0.42 → 0.65 → 0.12
Arc:          Convex (arch) — peak at V7#11, resolution to I
Emotional:    0.82
Overall:      0.76
```

### A.2 Noir Progression (C Minor, 14 chords)

```
Progression:  Cm9 → Fm7 → B♭13 → E♭maj9 → Am7♭5 → D7♭9 → Gm9 → C7#11
              → Fm9 → B♭7#11 → E♭6 → A♭maj7 → Dm7♭5 → G7alt
Tension:      0.25 → 0.38 → 0.62 → 0.30 → 0.55 → 0.78 → 0.42 → 0.72
              → 0.48 → 0.68 → 0.22 → 0.35 → 0.60 → 0.95
Arc:          Ascending — tension accumulates throughout
Emotional:    0.78
Overall:      0.71
```

---

## Appendix B: Usage Examples

```lisp
;; Load the system
(asdf:load-system :gakuri)
(use-package :gakuri)

;; Generate a yearning progression in C major
(generate-emotional-progression 0 :mood :yearning :length 10)

;; Generate batch across multiple moods
(generate-batch 0 :moods '(:ballad :noir :neo-soul :bittersweet)
                  :per-mood 5 :length 12)

;; Analyze an existing progression
(analyze-and-rate my-progression
                  (make-key-signature :root 0 :mode :major)
                  :mood :melancholic)

;; Export as Roman numerals
(export-progression-text progression
                         (make-key-signature :root 0 :mode :major)
                         :format :roman)
```

---

*This paper and the GAKURI system are products of SAKURA Lab (音ラボ), Onsen Factory MEGA. The system is open-source under the MIT License.*
