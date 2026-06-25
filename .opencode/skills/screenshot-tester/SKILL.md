---
name: screenshot-tester
description: Test the Shutter capture pipeline using --mock-capture mode without needing X11/Wayland
license: GPL-3.0-or-later
compatibility: opencode
metadata:
  audience: developers
  workflow: testing
---

## What I do

Guide you through testing Shutter's capture pipeline using `--mock-capture` mode, which uses a static test image instead of actual screen capture. This lets you test the entire after-capture pipeline (naming, resizing, uploading, saving) without a display server.

## When to use me

Use this skill when you need to test changes to the capture pipeline, upload workflow, file saving, or any post-capture processing without taking real screenshots.

## Commands

### Basic mock capture (full screen simulation)
```bash
carton exec bin/rshot --mock-capture --full
```

### Mock capture with custom output
```bash
carton exec bin/rshot --mock-capture --full --output=/tmp/test.png
```

### Mock capture with region simulation
```bash
carton exec bin/rshot --mock-capture --select=10,10,100,100
```

### Debug mode (verbose logging)
```bash
carton exec bin/rshot --mock-capture --full --debug
```

### Mock capture with upload test
```bash
carton exec bin/rshot --mock-capture --select=10,10,100,100 --debug
```

### Log to file
```bash
carton exec bin/rshot --mock-capture --full --log-file=/tmp/rshot.log --log-level=debug
```

## Quick smoke test

To quickly verify after changes:
```bash
carton exec bin/rshot --mock-capture --full --output=/tmp/smoke_test.png
```

If this exits without errors and produces `/tmp/smoke_test.png`, the basic pipeline is intact.

## Notes

- You don't need X11, Wayland, or a display server for `--mock-capture`
- Mock capture uses a built-in static test image
- Combine with `--debug` or `--log-level=debug` for detailed pipeline tracing
- The flag is defined in `Shutter::App::Options.pm` and handled in `Shutter::App::CLI.pm`
