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


## v0.2.0 Tokenizer Direction

Version 0.2.0 improves the tokenizer without changing the core philosophy. Common visual atoms such as `x^2`, `a_{n+1}`, `\frac{a}{b}`, `\sqrt[n]{x}`, `\sin x`, `\log x`, `\cdots`, and parenthesized expressions are kept together more often. This generally produces cleaner highlighting because the diff algorithm compares larger visual units instead of individual punctuation tokens.

This is still not semantic parsing. The tokenizer does not know that two expressions are equivalent; it only tries to preserve common LaTeX math atoms so visual changes are easier to read.

## v0.3.0 Internal Testing Direction

Version 0.3.0 starts adding Lua-side unit tests for the tokenizer and visual diff renderer. The internal test hooks expose tokenizer output, LCS matching, and step rendering through `stepdiff._test` so these behaviors can be checked without compiling a full LaTeX document for every case.

These tests are still about visual reliability, not mathematical meaning. They check that common LaTeX math atoms stay coherent and that changed chunks render as valid LaTeX-like output with `\SDchanged{...}` where expected.

## v0.4.0 Relation Alignment Direction

Version 0.4.0 adds relation-aware alignment while keeping the implementation token-based. After tokenization, `stepdiff` scans the top-level token list for the first recognized relation token, such as `=`, `\le`, `\ge`, `\approx`, `\equiv`, or `\Rightarrow`, and uses that token as the alignment point.

This deliberately depends on tokenizer boundaries. Braced groups, fractions, roots, and parenthesized atoms are normally kept as single tokens, so relation-like text inside those atoms is not treated as an alignment target. That keeps the detector conservative and avoids splitting inside common LaTeX constructs.

## v0.5.0 Visual Presentation Direction

Version 0.5.0 focuses on TeX-side presentation controls rather than new math behavior. Themes, highlight modes, and layout modes change how existing visual diffs are displayed while leaving tokenization and relation-aware alignment conceptually unchanged.

The styling layer remains deliberately small: `\SDchanged{...}` controls changed math chunks, `\SDreason{...}` controls reason text, and layout options adjust row spacing and the reason-column separation. These hooks stay customizable so authors can adapt the package to lecture notes, print handouts, or house styles.

Final-step emphasis is still handled through existing diff controls, especially `diff=all`. A dedicated `tag=final` option may be added later if it can be done without complicating row rendering.

## Styles and Presentations

The package includes style controls such as `theme=soft`, `theme=minimal`, `highlight=background`, `highlight=underline`, `highlight=color`, `highlight=none`, and layout modes for compact, lecture, and wide spacing. The older `style=highlight` and `style=underline` aliases remain available for compatibility.

Beamer support is still basic: `stepdiff` can be used inside a frame, but overlay-aware step reveals are a future goal.

## Future Ideas

- Continue improving the math atom tokenizer for scripts, fractions, roots, delimiters, relation tokens, and common operator forms.
- Optional semantic mode for users who want deeper checking or CAS integration.
- More refined theme presets for print, dark-on-light lecture notes, and projector slides.
- Beamer support, including overlays for revealing derivation steps.
- More robust test documents that cover common LaTeX math constructs.
