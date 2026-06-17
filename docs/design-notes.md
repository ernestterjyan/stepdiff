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

The v1.1 visual layer is TeX-side presentation. It does not change the diffing model or add semantic reasoning.

Display modes set high-level rhythm:

- `display=notes` for balanced lecture-note output.
- `display=slide` for larger, more spacious projected output.
- `display=focus` for stronger changed-term and final-step emphasis.

Themes set coordinated colors and default highlight/reason treatments:

- `theme=soft` for polished notes.
- `theme=minimal` for print-friendly documents.
- `theme=focus` for tutorials and slides.

Highlight modes, reason styles, framed blocks, and final-step emphasis are intentionally small hooks around the existing rendered tokens. `\SDchanged{...}` controls changed math chunks, `\SDreason{...}` controls reason text, `\SDfinalmath{...}` and `\SDfinalreason{...}` control final-step presentation, and `frame=true` wraps the aligned block in a lightweight box.

## Global Setup

`\stepdiffsetup{...}` stores a default key list for document-level visual defaults. Each environment applies package defaults, then global setup, then local environment options. Supported visual defaults include `display`, `theme`, `layout`, `highlight`, `reason-style`, `frame`, and `show-reasons`.

## Beamer Overlays

Overlay support is row-level. The formula cells and reason annotation for a step are wrapped with Beamer overlay commands so they appear together. In non-Beamer documents, overlay syntax is accepted and rendered without overlay behavior.

The visual system is designed to compile in Beamer without additional packages. Framed blocks use standard LaTeX color boxes rather than `tcolorbox`.

## Testing Direction

The repository uses both compile tests and Lua-side tests.

Compile tests protect the LaTeX API, Beamer usage, visual style options, relation-aware alignment, global setup, frame rendering, final tags, and overlay syntax. Lua tests protect tokenizer behavior, diff rendering, relation detection, and overlay row rendering.

These tests are about visual and structural reliability. They do not check mathematical correctness.

## Future Ideas

- Continue improving the math atom tokenizer for scripts, fractions, roots, delimiters, relation tokens, and common operator forms.
- Add more polished examples from lecture notes and slide decks.
- Prepare CTAN-style packaging metadata.
- Consider optional integrations only if they can remain clearly separate from the visual diffing core.
