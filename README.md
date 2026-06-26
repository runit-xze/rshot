# RShot (formerly Shutter)

Donate:
XMR: 842xeJ73G1f8Wu1r9VmBDKgSXrkSTkd71CTLx3vxvxjac6Ho5E3RPvAdUPFrVnqp8kbAGZXL4oVVkLyEbotbTkZRHNcmLFM
BTC: TBA

## Q: How do I install this?
## A: For now, point your agent at it and ask it to do so. Flatpak and appimage will be coming soon-ish.

## Q: What works?
## A: This changes depending on the state of the repo, but as of time of writing screenshots + gif recording + video recording with sound all work.

RShot is a modern, feature-rich screenshot program for Linux-based operating systems. It is a heavily refactored and modernized fork of the original Shutter project.

## 🛠️ Work Done Since Original Fork
Since forking from the original Shutter project, RShot has undergone massive improvements:
* **Complete Architectural Overhaul**: Migrated from a legacy monolith to a clean, modular `Moo`-based object-oriented design.
* **Modernized Codebase**: Upgraded strictly to Perl v5.40, fully utilizing modern language features like subroutine signatures and native `try/catch`.
* **Dependency Diet**: Eliminated numerous obsolete external dependencies, replacing them with core Perl implementations for better security and stability.
* **Modern Uploaders**: Dropped legacy upload plugins (like FTP and Imgur) in favor of standard ShareX configurations (`.sxcu`), supporting modern hosts like Catbox, ImgBB, and Litterbox out-of-the-box.
* **Logging Integration**: Standardized the entire application's logging infrastructure using `Log::Any`.
* **Cruft Removal**: Removed outdated legacy Perl image manipulation plugins (e.g., Polaroid, Sepia) to streamline the core experience.

## 🚀 Development Quick Start

Get up and running in less than 2 minutes.

### 1. Environment Setup
*   **VS Code (Recommended):** Open this folder and click **"Reopen in Container"**. All dependencies, Perl v5.40, and tools are pre-configured.
*   **Manual (Linux):** Ensure you have Perl installed, then run:
    ```bash
    ./bin/setup
    ```

### 2. Run RShot
```bash
carton exec bin/rshot
```

### 3. Mock Capture (For Rapid Testing)
Test the entire pipeline without taking real screenshots:
```bash
carton exec bin/rshot --mock-capture --full
```

---

## 📖 Documentation
*   [**Contributing Guide**](CONTRIBUTING.md) - How to set up, test, and submit PRs.
*   [**Architecture Overview**](ARCHITECTURE.md) - Understanding the Moo-based modular design.
*   [**Life of a Screenshot**](docs/LIFE_OF_A_SCREENSHOT.md) - A temporal trace of the capture workflow.
*   [**Refactor Progress**](REFACTOR_PROGRESS.md) - Track the migration from the legacy monolith.

---

## Legacy Information
RShot is a fork of Shutter.
Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
---------------------

Shutter Licence
------------
Licence: GPL 3 or (at your option) any later version.

RShot (and Shutter) is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public Licence as published
by the Free Software Foundation; either version 3 of the Licence,
or (at your option) any later version.
