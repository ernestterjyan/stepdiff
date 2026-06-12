# Release Checklist

Use this checklist for a clean public release.

- Update version in `stepdiff.sty`.
- Update version in `stepdiff.lua`.
- Update `CHANGELOG.md`.
- Run `make clean`.
- Run `make examples`.
- Run `make test`.
- Visually inspect `examples/demo.pdf`.
- Commit changes.
- Tag release.
- Push tag.
- Create GitHub release.
