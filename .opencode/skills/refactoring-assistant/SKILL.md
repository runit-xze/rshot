---
name: refactoring-assistant
description: Apply mechanical code transformations for the Shutter refactoring effort — method extraction, monolith decomposition, signature migration
license: GPL-3.0-or-later
compatibility: opencode
metadata:
  audience: developers
  workflow: refactoring
---

## What I do

Assist with the ongoing Shutter refactoring by applying mechanical transformations: extracting methods from legacy monoliths, migrating to Moo attributes, adding subroutine signatures, splitting modules, and modernizing Perl code.

## When to use me

Use this skill when working on refactoring tasks described in `REFACTOR_PROGRESS.md`, `DRAW_TOOL_REFACTOR.md`, or `ARCHITECTURE.md`.

## Patterns I apply

### 1. Legacy to modern signature migration

Replace:
```perl
sub legacy_method {
    my ($self, $arg1, $arg2) = @_;
    ...
}
```
With:
```perl
sub legacy_method ($self, $arg1, $arg2) {
    ...
}
```

### 2. Hash-based object to Moo migration

Replace `bless` and hash access with Moo `has` declarations and method calls.

### 3. Module extraction

Extract a group of related methods from a large file (like `Common.pm`) into a new Moo-based module under an appropriate `Shutter::App::*` namespace. Update all callers.

### 4. Try/catch modernization

Replace `eval { ... }; if ($@) { ... }` with:
```perl
try {
    ...
} catch ($e) {
    $log->error("caught error: $e");
}
```

### 5. Refactoring scripts

The project has several `.pl` scripts in the root for refactoring:
- `refactor.pl` — DrawingTool/CanvasOverlays extraction
- `replace_methods.pl` — Method replacement
- `fix_*.pl` — Various fix scripts
- `extract_new.pl` / `mass_extraction.pl` — Module extraction

Refer to these for prior patterns before starting new refactoring.

## Verification

After any refactoring:
1. Run `make tidy` for formatting
2. Run `make lint` for style checks
3. Run `make test` to verify nothing is broken
4. Run `carton exec bin/rshot --mock-capture --full` for a smoke test
