# Contributing to RShot

Welcome! We're glad you're interested in contributing to Shutter. This guide will help you get started with the project's new modern architecture.

## Getting Started

### 1. Development Environment
We use **Carton** to manage dependencies and **Docker/Dev Containers** to ensure a consistent environment.

*   **Option A (VS Code):** Open the project and select "Reopen in Container".
*   **Option B (Local):** Run `./bin/setup` to install system dependencies, Perl modules, and git hooks.
*   **IDE Support:** See [**Editor Setup**](docs/EDITOR_SETUP.md) for VS Code, Vim, Emacs, and Neovim tips.

### 2. Workflow
1.  Fork the repository and create a feature branch.
2.  Run `make tidy` to format your code.
3.  Run `make lint` and `make test` to ensure everything is correct.
4.  Submit a Pull Request with a clear description of your changes.

---

## Modern Perl Bridge (v5.40+)

If you're coming from Python, Go, or Ruby, modern Shutter code will feel familiar. We use **Moo** for object orientation and **v5.40** features to eliminate legacy Perl "noise."

*   **Subroutine Signatures:** No more `my ($self, $args) = @_;`. Use `sub method ($self, $param1, $param2) { ... }`.
*   **Moo Objects:** Attributes are defined with `has attr => (is => 'ro');`.
*   **Try/Catch:** We use the native `try { ... } catch ($e) { ... }` syntax.

Example of a modern Shutter module:
```perl
package Shutter::App::Example;
use v5.40;
use Moo;

has name => (is => 'ro', required => 1);

sub greet ($self) {
    say "Hello, " . $self->name;
}
```

---

## 🏗️ Architecture

Detailed technical documentation can be found in the [**ARCHITECTURE.md**](ARCHITECTURE.md) file and the `GEMINI/` directory:

### Core Philosophy
*   **Decoupling**: Business logic is separated from UI logic.
*   **Composition**: We prefer Moo Roles and composition over complex inheritance.
*   **Consistency**: Every new module should follow the patterns established in `Shutter::App::CLI`.

---

---

## 🎯 Good First Issues

Looking for a place to start? 
*   **Refactoring:** Check [**REFACTOR_PROGRESS.md**](REFACTOR_PROGRESS.md) for remaining subroutines in `Common.pm` that need to be moved to Moo attributes.
*   **Tests:** Add unit tests for any module in `share/shutter/perl/Shutter/App/` that lacks a corresponding file in `t/`.

---

## 🛠️ Coding Standards

*   **Strict & Warnings**: Always use `use strict;` and `use warnings;` (or let Moo/v5.40 handle it).
*   **Naming**: Use `snake_case` for methods and variables.
*   **Formatting**: We use `perltidy`. Run `make tidy` before committing.
*   **Static Analysis**: We use `perlcritic`. Run `make lint` to check for common issues.

## 🛠️ Testing & Debugging

New features should always include tests in the `t/` directory. Use `Test::More` and `Test::MockModule` where appropriate.

```bash
# Run all tests
make test
```

### Development Mode (Mock Capture)

Testing screenshot logic manually can be tedious. Shutter includes a **Mock Capture Mode** that allows you to test the entire after-capture pipeline (naming, resizing, uploading, etc.) without actually taking a screenshot of your desktop.

To use it, pass the `--mock-capture` flag:

```bash
# Take a mock "full screen" capture and save to /tmp
perl -Ishare/shutter/perl bin/shutter --mock-capture --full --output=/tmp/test.png

# Test the upload pipeline with a mock image
perl -Ishare/shutter/perl bin/shutter --mock-capture --select=10,10,100,100 --debug
```

This mode uses a static test image and bypasses X11/Wayland capture requirements, making it ideal for CI environments or quick pipeline testing.

### Visualizing Architecture
To see how modules interact and identify where legacy patterns might be leaking into modern ones:
```bash
make map
```
This generates a `DEPENDENCIES.md` file with a Mermaid diagram. Modern Moo modules are highlighted in pink with a thick border.

Thank you for helping make Shutter better!
