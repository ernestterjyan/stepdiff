# Changelog

## 0.5.0 - Unreleased

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
