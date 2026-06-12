# Contributing

Thanks for helping improve `stepdiff`. The project is moving toward a stable LuaLaTeX package, so contributions should keep the package simple, predictable, and honest about what it does.

## Build and Test

From the repository root, run:

```bash
make clean
make examples
make test
make lua-test
```

`make examples` compiles every `.tex` file in `examples/` with LuaLaTeX. `make test` compiles regression documents in `tests/` and runs Lua-side unit tests.

## Coding Style

- Keep the LaTeX interface small and documented.
- Preserve the stable public API unless a change is explicitly planned.
- Keep Lua code readable and avoid clever parsing tricks unless they are clearly tested.
- Prefer token-level visual behavior unless a feature is explicitly marked as semantic.
- Do not add CAS, proof-checking, or mathematical verification behavior without a major design discussion.
- Add or update examples and tests when changing visible behavior.

## Public API Expectations

The stable API includes the `stepdiff` environment, `\step`, `\stepdiffsetup`, diff modes, visual options, Beamer overlay syntax, and the customization hooks `\SDchanged` and `\SDreason`.

Changes should preserve ordinary article usage and Beamer usage unless the changelog calls out a breaking change.

## Reporting Bugs

When reporting a bug, include:

- A minimal LuaLaTeX example.
- The LuaLaTeX version if relevant.
- The expected output.
- The actual output or compilation error.
- Whether the issue is about rendering, highlighting, alignment, Beamer overlays, global setup, or documentation.

## Good Contributions

Good contributions include:

- Better examples.
- Documentation improvements.
- Safer tokenization for common LaTeX math constructs.
- More robust compile or Lua tests.
- Small visual styling improvements that preserve user customization hooks.
