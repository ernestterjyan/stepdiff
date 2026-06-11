# stepdiff

`stepdiff` is a small LuaLaTeX package for writing step-by-step mathematical
derivations. It compares each line with the previous line and highlights the
tokens that changed.

This first MVP is intentionally simple: it performs token-level visual diffing
only. It does not try to understand, verify, or classify the mathematics.

## What it does

- Typesets derivations as aligned display math.
- Compares consecutive `\step{...}` lines.
- Ignores whitespace while comparing.
- Highlights tokens in the current line that are not part of a longest common
  subsequence with the previous line.
- Supports an optional right-side annotation with `reason={...}`.
- Lets users redefine `\SDchanged{...}` and `\SDreason{...}`.

## What it does not do

- It does not prove equality.
- It does not use a computer algebra system.
- It does not detect whether a step is expansion, factorization,
  differentiation, cancellation, or simplification.
- It does not display deleted tokens from the previous line.

## Usage

```latex
\documentclass{article}
\usepackage{xcolor}
\usepackage{stepdiff}

\begin{document}

\[
\begin{stepdiff}
\step{a(x+b)}
\step[reason={distribute a}]{ax + ab}
\end{stepdiff}
\]

\end{document}
```

Customize highlighting by redefining the user hooks:

```latex
\renewcommand{\SDchanged}[1]{\color{red}{#1}}
\renewcommand{\SDreason}[1]{\quad\text{\scriptsize #1}}
```

## Building the demo

Compile from the repository root with LuaLaTeX:

```bash
lualatex examples/demo.tex
```

or use the Makefile:

```bash
make demo
```

Clean generated demo files with:

```bash
make clean
```

## Current limitations

- Diffing is purely textual and token-based.
- Removed tokens are not shown because only the current line is rendered.
- LaTeX tokenization is deliberately basic and may be coarse around complex
  macros.
- Commands with braced arguments, such as `\frac{...}{...}`, are usually kept
  as one token to avoid invalid highlighted output.
- Alignment is simple: the full expression is placed in one math column and the
  reason is placed in a second column.

## Planned next features

- Better token grouping for common math constructs such as powers,
  subscripts, fractions, roots, and paired delimiters.
- Optional styles for insertions, replacements, and unchanged context.
- More alignment modes, including alignment around relation symbols such as
  `=`, `\le`, and `\approx`.
