# Release Checklist

Use this checklist for a clean public release or release candidate.

## Versioning

- Update version in `stepdiff.sty`.
- Update version in `stepdiff.lua`.
- Update `CHANGELOG.md`.
- Confirm whether this is a release candidate or final release.
- Do not tag `v1.1.0` until the final release is intended.

## Validation

- Run `make clean`.
- Run `make examples`.
- Run `make test`.
- Run `make lua-test`.
- Visually inspect `examples/demo.pdf`.
- Visually inspect `examples/visual-styles.pdf`.
- Visually inspect `examples/polished-notes.pdf`.
- Visually inspect `examples/beamer-overlays.pdf` for overlay behavior.
- Spot-check `frame=true` and `tag=final` output in notes and Beamer contexts.

## Documentation

- Check `README.md` status and API examples.
- Check `docs/design-notes.md` for accurate non-goals.
- Confirm visual presentation options are documented: display, theme, highlight, reason style, frame, final tag, and global setup.
- Confirm screenshot links under `docs/assets/` are stable.
- Confirm generated PDFs are not committed.

## Publish

- Commit changes.
- Tag release or release candidate only when intended.
- Push branch.
- Push tag when releasing.
- Create GitHub release.
- Include notes that `stepdiff` performs visual token-level diffing and does not verify mathematics.
