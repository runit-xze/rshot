---
name: lint-test-runner
description: Run perlcritic linting and prove-based test suite for the Shutter project
license: GPL-3.0-or-later
compatibility: opencode
metadata:
  audience: developers
  workflow: validation
---

## What I do

Run linting (`perlcritic`) and tests (`prove`) on the Shutter codebase after changes are made. I know the correct commands and configuration files to use.

## When to use me

Use this skill after making changes to any Perl file in `bin/`, `share/shutter/resources/modules/`, or `t/`. I will run the linter to catch style issues and the test suite to verify correctness.

## Commands I run

### Lint (perlcritic)

```bash
make lint
```

Equivalent to:
```bash
carton exec perlcritic bin/ share/shutter/resources/modules/ t/
```

Config: `.perlcriticrc` (severity 3, verbosity 8, with these policies disabled):
- `BuiltinFunctions::ProhibitStringyEval`
- `ControlStructures::ProhibitPostfixControls`
- `Subroutines::ProhibitSubroutinePrototypes`
- `Variables::ProhibitPunctuationVariables`

### Test (prove)

```bash
make test
```

Equivalent to:
```bash
carton exec prove -Ishare/shutter/resources/modules -It/lib -r t/
```

### Code formatting (perltidy)

```bash
make tidy
```

Format config: `.perltidyrc` (indentation=2, continuation=4, --ce, --sot, --sct, line length=200)

### Full validation pipeline

```bash
make tidy && make lint && make test
```

## Notes

- If `carton` is not available or dependencies are missing, run `carton install` first
- For CI-like runs (no X11), use headless mode or set `DISPLAY=` appropriately
