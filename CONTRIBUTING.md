# Contributing

Thanks for helping improve `stepdiff`. This project is currently a small LuaLaTeX MVP, so contributions should keep the package simple and predictable.

## Compile Examples

From the repository root, run:

```bash
make clean
make examples
```

`make examples` compiles every `.tex` file in `examples/` with LuaLaTeX.

## Coding Style

- Keep the LaTeX interface small and documented.
- Keep Lua code readable and avoid clever parsing tricks unless they are clearly tested.
- Prefer token-level visual behavior unless a feature is explicitly marked as semantic.
- Do not add a CAS dependency without discussion.
- Add or update examples when changing visible behavior.

## Reporting Bugs

When reporting a bug, include:

- A minimal LaTeX example.
- The LuaLaTeX version if relevant.
- The expected output.
- The actual output or compilation error.
- Whether the issue is about rendering, highlighting, alignment, or documentation.

## Welcome Contributions

Good first contributions include:

- Better examples.
- Documentation improvements.
- Safer tokenization for common LaTeX math constructs.
- More robust Makefile targets.
- Small visual styling improvements that preserve user customization hooks.
