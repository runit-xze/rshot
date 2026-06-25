---
name: flatpak-builder
description: Build and test the Shutter Flatpak package from the org.shutter_project.Shutter.json manifest
license: GPL-3.0-or-later
compatibility: opencode
metadata:
  audience: maintainers
  workflow: packaging
---

## What I do

Build and test the Shutter Flatpak using the manifest at `org.shutter_project.Shutter.json`. I handle the full build pipeline: resolving dependencies from `generated-sources.json`, building Perl 5.40, installing CPAN dependencies, and packaging the application.

## When to use me

Use this skill when packaging a release, testing Flatpak builds, or updating Flatpak dependencies (e.g., after adding new CPAN modules or system libraries).

## Manifest structure

The Flatpak manifest at `org.shutter_project.Shutter.json` has three modules:

1. **perl** — Builds Perl 5.40 from source (`perl-5.40.0.tar.gz`)
2. **perl-libs** — Installs CPAN dependencies from `generated-sources.json` via `perl-libs/install.sh`
3. **shutter** — Copies the application files into the Flatpak

## Commands

### Build locally
```bash
flatpak-builder --force-clean build-dir org.shutter_project.Shutter.json
```

### Build and install for testing
```bash
flatpak-builder --force-clean --install --user build-dir org.shutter_project.Shutter.json
```

### Run the built Flatpak
```bash
flatpak run org.shutter_project.Shutter
```

### Update generated sources for new CPAN deps
When you add a CPAN dependency, regenerate `generated-sources.json`:
```bash
flatpak-builder --force-clean --state-dir=flatpak-state build-dir org.shutter_project.Shutter.json 2>&1 | tee build.log
```

### Update the runtime version
The manifest uses `org.gnome.Platform` runtime version `45`. To bump: edit the `runtime-version` field in `org.shutter_project.Shutter.json`.

## Notes

- Requires `flatpak` and `flatpak-builder` to be installed
- The GNOME runtime and SDK must be available: `flatpak install org.gnome.Platform//45 org.gnome.Sdk//45`
- `generated-sources.json` is checked into the repo and must be regenerated when CPAN dependencies change
- The finish args grant network, X11/Wayland, DRI, home filesystem access, and DBus portals
