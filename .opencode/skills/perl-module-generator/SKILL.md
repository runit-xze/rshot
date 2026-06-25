---
name: perl-module-generator
description: Scaffold new Shutter Moo-based Perl modules following project conventions (v5.40, Moo, try/catch, signatures, Log::Any)
license: GPL-3.0-or-later
compatibility: opencode
metadata:
  audience: developers
  workflow: scaffolding
---

## What I do

Scaffold new Perl modules in the Shutter project under `share/shutter/resources/modules/Shutter/`, following established conventions.

## When to use me

Use this skill when creating a new Perl module. I will generate the file with the correct license header, `use v5.40`, `Moo` setup, subroutine signatures, and proper namespace.

## Conventions I enforce

- License header: GPLv3+ block
- `use v5.40;` with `use feature 'try';` / `no warnings 'experimental::try';`
- `use Moo;` for object orientation
- `has` for attributes with `is => 'ro'` and `required => 1` where appropriate
- Subroutine signatures: `sub method_name ($self, @params) { ... }`
- `snake_case` for methods and variables
- `Log::Any` for logging: `use Log::Any;` and `my $log = Log::Any->get_logger;`
- End with `1;`
- Return `TRUE`/`FALSE` from Glib when dealing with GTK callbacks
- Run `make tidy` after creation

## Namespace conventions

| Purpose | Namespace |
|---------|-----------|
| Core managers | `Shutter::App::Core::*` |
| UI components | `Shutter::App::UI::*` |
| Screenshot logic | `Shutter::Screenshot::*` |
| Drawing tools | `Shutter::Draw::*` |
| Upload plugins | `Shutter::Upload::*` |
| Geometry | `Shutter::Geometry::*` |
| Pixbuf operations | `Shutter::Pixbuf::*` |

## Dependencies

Add new CPAN dependencies to `cpanfile` at the project root. For system dependencies, update `Dockerfile` and `org.shutter_project.Shutter.json` (Flatpak).

## Testing

Create a corresponding test file in `t/` using `Test::More`. Run `make test` to verify.

## Module template

```perl
package Shutter::App::Namespace::ModuleName;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Log::Any;

my $log = Log::Any->get_logger;

has '_common' => (is => 'ro', required => 1);

sub method_name ($self, $param1, $param2) {
    $log->debug("method_name called with $param1");
    # implementation
    return 1;
}

1;
```
