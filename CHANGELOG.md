# Changelog

## 1.1.1 - 2026-09-25

### Fixed
- Highlight changes to the first aligned relation, such as `\le` becoming `\ge`.
- Compare the two sides of aligned relations independently, so matching tokens cannot cross the relation.
- Prefer the earliest common tokens when an expression contains repeated atoms.
- Emphasize the surviving expression when a step only removes tokens, so the change is not invisible.
- Report the LuaLaTeX engine requirement explicitly.

### Added
- Regression tests for relation changes, removed relations, deletion-only changes, and repeated atoms.
- A standalone illustrated PDF manual and a reproducible CTAN archive target.

### Notes
Removed tokens are still not printed; a deletion-only step highlights what remains. The package performs visual diffing and does not verify mathematics.

## 1.1.0 - 2026-06-17

### Added
- Higher-level display modes: `notes`, `slide`, and `focus`.
- Improved visual theme system, including `theme=focus`.
- Reason annotation styles: `plain`, `muted`, and `badge`.
- Optional framed derivation blocks with `frame=true`.
- Final-step emphasis with `tag=final`.
- Typed visual diffing with `color-mode=single`, `color-mode=typed`, and `color-mode=teaching`.
- Public visual macros: `\SDadded`, `\SDmodified`, `\SDoperation`, `\SDmoved`, and `\SDfinal`.
- Conservative operation detection for examples such as `\lim` applied to both sides of a relation.
- Optional visual legend support with `legend=true`, rendered from styled typed-category sample words.
- New typed-color examples and tests.

### Improved
- Highlight appearance.
- Vertical spacing and visual rhythm.
- Visual examples and documentation.
- Beamer overlay visuals.
- Showcase examples for notes, visual styles, and Beamer slides.
- Final-step emphasis and conclusion-line consistency.
- Teaching-oriented visual hierarchy.
- Reason badge styling in teaching mode, coordinated with the operation color.
- Demo and polished-note examples.

### Notes
`stepdiff` remains a visual token-level diffing package. Typed visual categories are syntactic and pedagogical; they do not verify mathematical correctness, do not use a CAS, and do not understand transformations semantically.

## 1.0.0-rc1 - Unreleased

### Added
- Basic Beamer overlay support for `\step<...>{...}`.
- Global setup command `\stepdiffsetup{...}`.
- Additional examples for Beamer overlays and global configuration.
- Expanded compilation tests.
- Expanded documentation for the stable public API.

### Improved
- Documentation structure for first stable release.
- Test coverage for examples and package options.
- Release checklist for v1.0.

### Notes
`stepdiff` remains a visual token-level diffing package. It does not check mathematical correctness, does not use a CAS, and does not understand transformations semantically.

## 0.5.0 - Visual styles

- Added visual themes.
- Added highlight modes.
- Added layout modes.
- Improved reason annotation styling.
- Added visual style examples and tests.

## 0.4.0 - Relation-aware alignment

- Added relation-aware alignment.
- Added support for aligning at common relation symbols such as `=`, `\le`, `\ge`, `\approx`, `\equiv`, and `\Rightarrow`.
- Added relation-alignment examples and tests.

## 0.3.0 - Lua-side tests

- Added Lua-side tests for tokenizer behavior.
- Added Lua-side tests for diff rendering.
- Improved internal testability of `stepdiff.lua`.

## 0.2.0 - Improved visual diffing

- Improved math atom tokenization.
- Improved changed-chunk grouping.
- Added Beamer example.
- Added compilation-based regression tests.
- Added environment styles: `style=highlight` and `style=underline`.
- Improved documentation for customization.

## 0.1.0 - MVP

Initial public MVP of `stepdiff`.

- Added `stepdiff` environment for aligned step-by-step derivations.
- Added `\step` command with optional key-value arguments.
- Added token-level automatic visual diffing between consecutive steps.
- Added first-`=` alignment for derivation lines.
- Added reason annotations in a separate right-hand column.
- Added manual controls: `diff=auto`, `diff=false`, `diff=none`, `diff=all`.
- Added customization macros: `\SDchanged{...}` and `\SDreason{...}`.
- Added global reason visibility controls: `\SDhidereasons` and `\SDshowreasons`.
- Added example documents for algebra, calculus, and manual controls.
- Added MIT license, README, design notes, and contribution guide.
