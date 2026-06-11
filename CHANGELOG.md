# Changelog

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
