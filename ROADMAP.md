# Shutter Modernization Roadmap 2.0

This document outlines the strategic path for Shutter as it transitions from a legacy Perl/GTK2 application to a modern, modular, and high-performance screenshot suite.

## 🏆 Completed Milestones

### Core Architecture
- [x] **Monolith Elimination:** `bin/shutter` reduced from 11,500+ LOC to <100 LOC.
- [x] **Moo Migration:** Core logic moved to `Shutter::App::*` using modern Moo OOP.
- [x] **Handler Registry:** Centralized event handling via `Shutter::App::Handlers::Registry`.
- [x] **Modern Perl:** Adopted Perl v5.40 standards (signatures, try/catch, utf8).
- [x] **Logging:** Standardized on `Log::Any` across the entire codebase.

### New Features (ShareX-inspired)
- [x] **After Capture Pipeline:** Configurable sequence of post-capture tasks.
- [x] **Pin to Screen:** Floating screenshot overlays for quick reference.
- [x] **SXCU Support:** Compatibility with ShareX custom uploader configurations.
- [x] **Modern Naming:** Extensive file-naming macro support (`%y`, `%wt`, etc.).
- [x] **GIF Recording:** Animated GIF capture mode with region/window selection, countdown overlay, and configurable FPS/duration.

---

## 🏗️ Phase 4: Subsystem Modularization (Active)

The primary goal is to break down the remaining large modules that still carry legacy patterns.

### 4.1 Drawing Tool Refactoring
- [ ] **Break up `DrawingTool.pm` (7,300 LOC):** Extract UI management, tool logic (Ellipse, Rectangle, etc.), and state into separate Moo classes.
- [ ] **Modernize Rendering:** Ensure drawing tools are fully compatible with Cairo and GTK3 drawing signals.

### 4.2 Screenshot Engines
- [ ] **Advanced Selector:** Modernize `SelectorAdvanced.pm` to use Cairo-based overlays instead of legacy X11 primitives.
- [ ] **Wayland Parity:** Improve Wayland support via XDG Desktop Portals for improved security and compatibility.

### 4.3 Upload System
- [ ] **Uploader Standardization:** Ensure all legacy uploaders (FTP, etc.) are converted to the new `UploadManager` pattern.
- [ ] **Post-Upload Actions:** Finalize "Copy URL" and "Generate QR Code" workflows.

---

## 🎨 Phase 5: GTK3 & HiDPI Polish

- [ ] **HiDPI Fixes:** Resolve menu capture and multi-monitor scaling issues.
- [ ] **Widget Modernization:** Replace deprecated `HBox/VBox` with `Gtk3::Box`.
- [ ] **SSH/X Forwarding:** Debug and fix issues with remote X sessions.
- [ ] **UI Refinement:** Improve "stickiness" of the selection cursor to region edges.

---

## 🧪 Phase 6: Quality & Documentation

- [ ] **Unit Testing:** Build a comprehensive test suite for `SessionManager` and `SettingsManager` using `Test2::V0`.
- [ ] **GEMINI Documentation:** Achieve 100% coverage for all modules in the `GEMINI/` directory.
- [ ] **CI Integration:** Automate AppImage builds and test runs via GitHub Actions.

---

## 🚀 Future Vision (Backlog)

- [ ] **OCR Integration:** OCR support using Tesseract for instant text extraction.
- [ ] **Plugin API:** Stable API for 3rd party "After Capture" and "Uploader" plugins.
- [ ] **Native Wayland Capture:** Native implementation for GNOME/KDE/Sway environments without XWayland.
