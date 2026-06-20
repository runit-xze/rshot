# Project Conventions: Shutter

## Knowledge Base
The central knowledge base for this project is located at [docs/README.md](../docs/README.md). Always refer to the links and documents mentioned there to understand the system architecture and current refactoring state.

## Core Directives
1. **Perl Version**: We use Perl v5.40. Use modern signatures (`sub method ($self, $param1) { ... }`) and `try { ... } catch ($e) { ... }`. Do not use legacy prototype signatures.
2. **OOP System**: We use `Moo` for object orientation. Avoid manual `bless`. Prefer composition over inheritance.
3. **Architecture**: Business logic goes in `Shutter::App::Core::*` or similar `Shutter::App::*` namespaces, not in UI components.
4. **Tooling**: Ensure code changes are formatted according to `.perltidyrc` and pass `.perlcriticrc` checks.
5. **Testing**: Add tests in the `t/` directory using `Test::More` for any new modules.

Refer to [CONTRIBUTING.md](../CONTRIBUTING.md) for more details.
