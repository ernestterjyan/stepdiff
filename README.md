# stepdiff

`stepdiff` is a LuaLaTeX package for step-by-step mathematical derivations with visual token-level diffing between consecutive steps. It helps teachers, lecturers, and authors write clean derivations where changed parts stand out without turning the package into a computer algebra system.

LuaLaTeX is required. `stepdiff` uses Lua for tokenization and diff rendering, so it does not work with pdfLaTeX.

## Status

Current target: `v1.0.0-rc1` release candidate.

`stepdiff` is intended to be stable enough for lecture notes, worked examples, Beamer slides, and experimentation. The release candidate is not the final `v1.0.0` tag.

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

The stable public API includes:

```latex
\begin{stepdiff}[theme=soft, layout=lecture, highlight=background]
...
\end{stepdiff}

\step{...}
\step[reason={...}]{...}
\step[reason={...}, diff=false]{...}
\step[reason={...}, diff=none]{...}
\step[reason={...}, diff=all]{...}
\step<2->{...}
\step<2->[reason={...}]{...}

\stepdiffsetup{theme=minimal, highlight=underline}

\SDchanged{...}
\SDreason{...}
```

## Manual control

Automatic token-level diffing is approximate, so each step can choose a diff mode:

```latex
\step[reason={default}, diff=auto]{x^2+2x+1}
\step[reason={hide diff}, diff=false]{x^2+2x+1}
\step[reason={also hide diff}, diff=none]{x^2+2x+1}
\step[reason={emphasize line}, diff=all]{x^2+2x+1}
```

`diff=auto` is the default. Use `diff=false` or `diff=none` when highlighting is noisy. Use `diff=all` when the whole line should be emphasized.

## Visual styles

Visual options are set on the `stepdiff` environment. Environment options override global setup defaults.

```latex
\begin{stepdiff}[theme=soft, layout=lecture, highlight=background]
\step{S_n = 1 + 2 + \cdots + n}
\step[reason={pair terms}]{2S_n = n(n+1)}
\step[reason={final formula}, diff=all]{S_n = \frac{n(n+1)}{2}}
\end{stepdiff}
```

```latex
\begin{stepdiff}[theme=minimal, highlight=underline]
\step{x^2 - 1 = (x-1)(x+1)}
\step[reason={expand}, diff=false]{x^2 - 1 = x^2 - 1}
\end{stepdiff}
```

Supported options:

- `theme=soft`
- `theme=minimal`
- `highlight=background`
- `highlight=underline`
- `highlight=color`
- `highlight=none`
- `layout=compact`
- `layout=lecture`
- `layout=wide`

Legacy aliases `style=highlight` and `style=underline` remain available.

## Global setup

Use `\stepdiffsetup{...}` to set document-level defaults:

```latex
\stepdiffsetup{
  theme=soft,
  layout=lecture,
  highlight=background
}
```

Supported global keys are `theme`, `layout`, `highlight`, and `show-reasons`:

```latex
\stepdiffsetup{theme=minimal, highlight=underline}

\begin{stepdiff}
\step{x^2-1=(x-1)(x+1)}
\step[reason={expand}]{x^2-1=x^2-1}
\end{stepdiff}
```

```latex
\stepdiffsetup{show-reasons=false}
```

A local environment option can re-enable reasons with `show-reasons=true`.

## Relation-aware alignment

Lines containing a recognized relation are aligned at the first top-level relation token. Supported relation targets include:

```latex
= \le \ge < > \approx \sim \equiv \Rightarrow \Longrightarrow
```

Example:

```latex
\begin{stepdiff}
\step{a_n \le b_n}
\step[reason={take limits}]{\lim a_n \le \lim b_n}
\step[reason={conclude}]{L \le M}
\end{stepdiff}
```

Relation detection is conservative and token-based. It avoids splitting inside common braced constructs such as fractions when those constructs are tokenized as a single visual atom.

## Beamer overlays

In Beamer documents, `\step` accepts overlay specifications:

```latex
\begin{stepdiff}
\step<1->{f(x)=x^2}
\step<2->[reason={differentiate}]{f'(x)=2x}
\step<3->[reason={evaluate at x=3}, diff=all]{f'(3)=6}
\end{stepdiff}
```

The formula, reason annotation, and highlighting for a step appear together on the requested overlays. Visual options and global setup still apply.

Overlay syntax is intended for Beamer. In non-Beamer documents, `stepdiff` accepts the syntax and renders the steps normally without overlay behavior.

## Customization

The main customization hooks are:

```latex
\renewcommand{\SDchanged}[1]{\color{red}{#1}}
\renewcommand{\SDreason}[1]{\normalfont\scriptsize\itshape #1}
```

`\SDchanged{...}` receives changed math content and should remain safe in math mode. `\SDreason{...}` styles reason text inside the annotation column.

Reasons can also be hidden and shown with:

```latex
\SDhidereasons
\SDshowreasons
```

For new documents, prefer `\stepdiffsetup{show-reasons=false}` when hiding reasons globally.

## Examples

The repository includes:

- `examples/demo.tex`: polished main release-candidate demo.
- `examples/algebra.tex`: expansion and factorization examples.
- `examples/calculus.tex`: derivative and logarithmic differentiation examples.
- `examples/relations.tex`: relation-aware alignment examples.
- `examples/visual-styles.tex`: themes, highlight modes, and layout examples.
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
- Complex LaTeX macros may not always diff perfectly.
- Highlighting can be approximate for dense or macro-heavy notation.
- Relation alignment uses the first recognized top-level relation token.
- Beamer overlay support is intentionally basic and applies to whole step rows.

## Roadmap after v1.0

- Improve tokenizer coverage for more common LaTeX math macros.
- Add more examples from lecture-note workflows.
- Consider additional visual presets for print and presentation use.
- Explore final-step emphasis controls beyond `diff=all`.
- Prepare CTAN-style packaging metadata.

## License

MIT License. See `LICENSE`.
