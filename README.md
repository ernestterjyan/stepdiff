# stepdiff

`stepdiff` is a LuaLaTeX package for step-by-step mathematical derivations with automatic visual diffing between consecutive lines. It is meant for lecture notes, worked examples, and Beamer slides where readers should quickly see what changed from one displayed step to the next.

LuaLaTeX is required. `stepdiff` uses Lua for visual tokenization and diff rendering, so it does not work with pdfLaTeX.

`stepdiff` performs visual token-level diffing. It does not verify mathematical correctness, does not use a CAS, and does not understand transformations semantically.

## Status

Current target: `v1.1.0`.

![stepdiff demo](docs/assets/demo-preview.png)

Generated PDFs are ignored by Git. Rebuild them locally with the Makefile. Rendered screenshots and release-note images can live under `docs/assets/`.

## Quick start

Copy these files into your project or somewhere TeX can find them:

```text
stepdiff.sty
stepdiff.lua
```

Compile documents with LuaLaTeX:

```bash
lualatex your-file.tex
```

From this repository:

```bash
make clean
make examples
make test
make lua-test
```

## Minimal example

```latex
\documentclass{article}
\usepackage{xcolor}
\usepackage{stepdiff}

\begin{document}

\[
\begin{stepdiff}
\step{a(x+b)}
\step[reason={distribute}]{ax+ab}
\step[reason={commute terms}]{ab+ax}
\end{stepdiff}
\]

\end{document}
```

## Visual presentation

Visual options are set globally with `\stepdiffsetup{...}` or locally on a `stepdiff` environment. Local environment options override global defaults.

```latex
\stepdiffsetup{
  display=notes,
  theme=soft,
  layout=lecture,
  highlight=background,
  reason-style=muted
}

\[
\begin{stepdiff}[frame=true]
\step{S_n = 1 + 2 + \cdots + n}
\step[reason={pair terms}]{2S_n = n(n+1)}
\step[reason={final formula}, diff=all, tag=final]{S_n = \frac{n(n+1)}{2}}
\end{stepdiff}
\]
```

```latex
\[
\begin{stepdiff}[display=focus, theme=focus, reason-style=badge]
\step{f(x)=x^2+2x}
\step[reason={differentiate}]{f'(x)=2x+2}
\step[reason={evaluate}, tag=final]{f'(3)=8}
\end{stepdiff}
\]
```

Display modes:

- `display=notes`: balanced lecture-note spacing, subtle highlights, and muted reasons.
- `display=slide`: more generous spacing and larger reason annotations for projected material.
- `display=focus`: stronger changed-term emphasis and final-step weight for tutorials.

Themes:

- `theme=soft`: elegant note style with soft background highlights and muted reasons.
- `theme=minimal`: print-friendly styling with less color.
- `theme=focus`: higher contrast styling for tutorials and slides.

Highlight modes:

- `highlight=background`: changed chunks receive a soft background tint.
- `highlight=underline`: changed chunks are underlined without a box.
- `highlight=color`: changed chunks are colored directly.
- `highlight=none`: no visible highlighting; layout and reasons still render.

Reason styles:

- `reason-style=plain`: small, simple annotations close to the original style.
- `reason-style=muted`: subtle gray note styling for lecture notes.
- `reason-style=badge`: compact label styling for stronger visual separation.

Framed derivation blocks use `frame=true`:

```latex
\[
\begin{stepdiff}[display=notes, frame=true]
\step{x^2-1=(x-1)(x+1)}
\step[reason={expand}]{x^2-1=x^2-1}
\step[reason={result}, tag=final]{x^2-1=(x-1)(x+1)}
\end{stepdiff}
\]
```

Final-step emphasis uses `tag=final` on a step. It adds a little spacing before the line and applies subtle final-line styling. It also works with manual emphasis:

```latex
\step[reason={final formula}, diff=all, tag=final]{S_n = \frac{n(n+1)}{2}}
```

Global setup supports `display`, `theme`, `layout`, `highlight`, `reason-style`, `frame`, and `show-reasons`.

## Manual control

Automatic token-level diffing is approximate, so each step can choose a diff mode:

```latex
\step[reason={default}, diff=auto]{x^2+2x+1}
\step[reason={hide diff}, diff=false]{x^2+2x+1}
\step[reason={also hide diff}, diff=none]{x^2+2x+1}
\step[reason={emphasize line}, diff=all]{x^2+2x+1}
```

`diff=auto` is the default. Use `diff=false` or `diff=none` when highlighting is noisy. Use `diff=all` when the whole line should be emphasized.

## Relation-aware alignment

Lines containing a recognized relation are aligned at the first recognized relation token. Supported relation targets include:

```latex
= \le \ge < > \approx \sim \equiv \Rightarrow \Longrightarrow
```

Example:

```latex
\begin{stepdiff}[display=notes, theme=soft]
\step{a_n \le b_n}
\step[reason={take limits}]{\lim a_n \le \lim b_n}
\step[reason={conclude}, tag=final]{L \le M}
\end{stepdiff}
```

Relation detection is conservative and token-based. It avoids splitting inside common braced constructs such as fractions when those constructs are tokenized as a single visual atom.

## Beamer overlays

In Beamer documents, `\step` accepts overlay specifications:

```latex
\begin{stepdiff}[display=slide, theme=focus, reason-style=badge]
\step<1->{f(x)=x^2}
\step<2->[reason={differentiate}]{f'(x)=2x}
\step<3->[reason={evaluate at x=3}, tag=final]{f'(3)=6}
\end{stepdiff}
```

The formula, reason annotation, and highlighting for a step appear together on the requested overlays. In non-Beamer documents, overlay syntax is accepted and rendered without overlay behavior.

## Customization

The main customization hooks are:

```latex
\renewcommand{\SDchanged}[1]{\color{red}{#1}}
\renewcommand{\SDreason}[1]{\normalfont\scriptsize\itshape #1}
```

`\SDchanged{...}` receives changed math content and should remain safe in math mode. `\SDreason{...}` styles reason text inside the annotation column. `\SDfinalmath{...}` and `\SDfinalreason{...}` can be redefined for custom final-step presentation.

Reasons can also be hidden and shown with:

```latex
\SDhidereasons
\SDshowreasons
```

For new documents, prefer `\stepdiffsetup{show-reasons=false}` when hiding reasons globally.

## Examples

The repository includes:

- `examples/demo.tex`: polished main v1.1 demo.
- `examples/visual-styles.tex`: display modes, themes, highlights, reason styles, frames, and final tags.
- `examples/polished-notes.tex`: realistic lecture-note style derivation.
- `examples/relations.tex`: relation-aware alignment examples.
- `examples/algebra.tex`: expansion and factorization examples.
- `examples/calculus.tex`: derivative and logarithmic differentiation examples.
- `examples/manual-control.tex`: diff modes and customization examples.
- `examples/beamer-demo.tex`: minimal Beamer frame using `stepdiff`.
- `examples/beamer-overlays.tex`: Beamer overlay reveals with visual styles.

Compile all examples with:

```bash
make examples
```

## What stepdiff does not do

- It does not check whether mathematics is correct.
- It does not prove equality or implication.
- It does not use a CAS.
- It does not classify a step as expansion, factorization, differentiation, simplification, or any other transformation.
- It does not perform semantic math parsing.

## Current limitations

- Diffing is visual and token-level.
- Removed tokens are not shown because only the current line is rendered.
- Complex macros may not always diff perfectly.
- Highlighting can be approximate for dense or macro-heavy notation.
- Relation alignment uses the first recognized relation token.
- Beamer overlay support is intentionally basic and applies to whole step rows.

## Roadmap after v1.1

- Improve tokenizer coverage for more common LaTeX math macros.
- Add more examples from lecture-note workflows.
- Prepare CTAN-style packaging metadata.
- Consider optional integrations only if they remain clearly separate from the visual diffing core.

## License

MIT License. See `LICENSE`.
