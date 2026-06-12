# Design Notes

`stepdiff` is a visual diffing tool, not a mathematics engine. The package compares consecutive derivation lines and highlights tokens that changed. This keeps the implementation small, predictable, and useful for authors who already know the derivation they want to write.

## Core Identity

`stepdiff` is a LuaLaTeX package for visual token-level diffing between consecutive mathematical derivation steps. It helps teachers, lecturers, and authors write clean derivations with highlighted changes.

The package deliberately does not verify mathematics, prove transformations, or call a computer algebra system.

## Why Token-Level Diffing

Mathematical notation in LaTeX is rich, flexible, and often author-specific. A full parser would have to understand macros, local notation, implicit multiplication, spacing commands, and many equivalent ways of writing the same expression.

Token-level diffing gives useful visual feedback without pretending to solve mathematical equivalence. The goal is visual clarity: help readers see what changed from one line to the next.

## Manual Controls Are Necessary

Automatic visual diffing will never be perfect. Sometimes a token-level algorithm highlights too much, too little, or the wrong local chunk. This is why per-step controls exist:

- `diff=auto` for default automatic behavior.
- `diff=false` or `diff=none` when highlighting is noisy.
- `diff=all` when the author wants to emphasize a whole line.

These controls keep the package useful in real lecture notes, where presentation quality matters more than algorithmic purity.

## Relation-Aware Alignment

Relation-aware alignment scans the tokenized top-level expression for the first recognized relation token, such as `=`, `\le`, `\ge`, `\approx`, `\equiv`, or `\Rightarrow`, and uses that token as the alignment point.

This deliberately depends on tokenizer boundaries. Braced groups, fractions, roots, and parenthesized atoms are normally kept as single tokens, so relation-like text inside those atoms is not treated as an alignment target. That keeps the detector conservative and avoids splitting inside common LaTeX constructs.

## Visual Presentation Controls

Themes, highlight modes, and layout modes are TeX-side presentation controls. They change how existing visual diffs are displayed while leaving tokenization and relation-aware alignment conceptually unchanged.

The styling layer remains deliberately small: `\SDchanged{...}` controls changed math chunks, `\SDreason{...}` controls reason text, and layout options adjust row spacing and the reason-column separation. These hooks stay customizable so authors can adapt the package to lecture notes, print handouts, or house styles.

## v1.0.0-rc1 Direction

The release-candidate milestone stabilizes the public API rather than changing the diffing model. It adds two author-facing conveniences:

- Beamer overlay syntax for `\step<...>{...}`.
- `\stepdiffsetup{...}` for document-level visual defaults.

Overlay support is row-level. The formula cells and reason annotation for a step are wrapped with Beamer overlay commands so they appear together. In non-Beamer documents, overlay syntax is accepted and rendered without overlay behavior.

Global setup remains simple: it stores a default key list for `theme`, `layout`, `highlight`, and reason visibility. Each `stepdiff` environment applies compact defaults, then global setup, then local environment options.

## Testing Direction

The repository uses both compile tests and Lua-side tests.

Compile tests protect the LaTeX API, Beamer usage, visual style options, relation-aware alignment, global setup, and overlay syntax. Lua tests protect tokenizer behavior, diff rendering, relation detection, and overlay row rendering.

These tests are about visual and structural reliability. They do not check mathematical correctness.

## Future Ideas

- Continue improving the math atom tokenizer for scripts, fractions, roots, delimiters, relation tokens, and common operator forms.
- Add more polished final-step emphasis controls beyond `diff=all`.
- Add more robust examples from lecture notes and slide decks.
- Prepare CTAN-style packaging metadata.
- Consider optional semantic integrations only if they can remain clearly separate from the visual diffing core.
