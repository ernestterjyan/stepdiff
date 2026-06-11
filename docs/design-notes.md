# Design Notes

`stepdiff` is currently a visual diffing tool, not a mathematics engine. The package compares consecutive derivation lines and highlights the tokens that changed. This keeps the implementation small, predictable, and useful for authors who already know what derivation they want to write.

## Why Token-Level Diffing

Mathematical notation in LaTeX is rich, flexible, and often author-specific. A full parser would have to understand macros, local notation, implicit multiplication, spacing commands, and many equivalent ways of writing the same expression. For a first MVP, token-level diffing gives immediate value without pretending to solve mathematical equivalence.

The goal is visual clarity: help readers see what changed from one line to the next.

## Why Not Semantic Mathematics Yet

Semantic mathematics is a much harder problem. Detecting whether a line is a valid expansion, simplification, factorization, derivative, or algebraic transformation would require a mathematical parser and likely a computer algebra system. That would add complexity, dependencies, and failure modes that do not belong in the minimal package yet.

For now, `stepdiff` assumes the author is responsible for correctness.

## Manual Controls Are Necessary

Automatic visual diffing will never be perfect. Sometimes a token-level algorithm highlights too much, too little, or the wrong local chunk. This is why per-step controls exist:

- `diff=auto` for the default automatic behavior.
- `diff=false` or `diff=none` when highlighting is noisy.
- `diff=all` when the author wants to emphasize a whole line.

These controls keep the package useful in real lecture notes, where presentation quality matters more than algorithmic purity.

## Visual Diffing vs. Mathematical Verification

Visual diffing answers the question: "What text changed on the page?"

Mathematical verification answers the question: "Is this transformation correct?"

`stepdiff` only answers the first question. It does not check equations, prove equality, call a CAS, or infer the mathematical meaning of a step.

## Future Ideas

- A better math atom tokenizer for scripts, fractions, roots, delimiters, and common operator forms.
- Optional semantic mode for users who want deeper checking or CAS integration.
- Better color themes for print, dark-on-light lecture notes, and projector slides.
- Beamer support, including overlays for revealing derivation steps.
- More robust test documents that cover common LaTeX math constructs.
