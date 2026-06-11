# stepdiff

`stepdiff` is a small LuaLaTeX package for writing step-by-step mathematical
derivations. It compares each line with the previous line and highlights the
tokens that changed.

This first MVP is intentionally simple: it performs token-level visual diffing
only. It does not try to understand, verify, or classify the mathematics.

## What it does

- Typesets derivations as aligned display math.
- Aligns each step at the first `=` when one is present.
- Compares consecutive `\step{...}` lines.
- Ignores whitespace while comparing.
- Groups nearby changed tokens and highlights the changed chunks in the current
  line.
- Places optional `reason={...}` annotations in a separate right-hand annotation
  column.
- Lets users redefine `\SDchanged{...}` and `\SDreason{...}`.
- Supports per-step manual controls with `diff=auto`, `diff=false`, `diff=none`, and `diff=all`.

## What it does not do

- It does not prove equality.
- It does not use a computer algebra system.
- It does not detect whether a step is expansion, factorization,
  differentiation, cancellation, or simplification.
- It does not display deleted tokens from the previous line.

## Design philosophy

`stepdiff` helps authors make derivations visually clear, but it does not check
the mathematics. The highlighting is token-based and approximate: it is meant to
show where the written expression changed, not why the change is valid.

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

Lines containing `=` are aligned at the first equals sign. Reasons are placed in
a separate annotation column, visually similar to:

```latex
\begin{aligned}
left & = right && \text{reason}
\end{aligned}
```

Customize highlighting and reason styling by redefining the user hooks:

```latex
\renewcommand{\SDchanged}[1]{\color{red}{#1}}
\renewcommand{\SDreason}[1]{\normalfont\scriptsize\itshape #1}
```


## Manual control

Automatic token-level diffing is approximate, so each step can choose a diff
mode:

```latex
\step[reason={expand}, diff=auto]{x^2 + 2x + 1}
\step[reason={too noisy}, diff=false]{x^2 + 2x + 1}
\step[reason={important final formula}, diff=all]{x^2 + 2x + 1}
```

- `diff=auto` is the default. It compares the current step to the previous step
  using token-level diffing.
- `diff=false` disables automatic highlighting for that line. `diff=none` is an
  equivalent spelling.
- `diff=all` highlights the whole mathematical line while keeping the reason
  annotation in place.

Reasons can be hidden or shown globally after loading the package:

```latex
\SDhidereasons
\SDshowreasons
```

The styling hooks remain ordinary user-level macros:

```latex
\renewcommand{\SDchanged}[1]{\color{red}{#1}}
\renewcommand{\SDreason}[1]{\normalfont\scriptsize\itshape #1}
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
- Highlighting is approximate and may still choose unintuitive chunks.
- Removed tokens are not shown because only the current line is rendered.
- LaTeX tokenization is deliberately basic and may be coarse around complex
  macros.
- Commands with braced arguments, such as `\frac{...}{...}`, are usually kept
  as one token to avoid invalid highlighted output.
- Alignment currently uses only the first literal `=` in each step.

## Planned next features

- Better token grouping for common math constructs such as powers,
  subscripts, fractions, roots, and paired delimiters.
- Optional styles for insertions, replacements, and unchanged context.
- More relation-aware alignment, including `\le`, `\approx`, and similar
  relation symbols.
