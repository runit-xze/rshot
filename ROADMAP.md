# Shutter Modernization Roadmap

**Target:** Perl v5.40 — using modern signatures, `try`/`catch`, Moo OOP, `Future`-based async, and zero `perlcritic --brutal` violations.

---

## Completed Milestones

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

### Drawing Tool Refactoring
- [x] **Tool Roles Extracted:** `Movable`, `Resizable`, `Selectable` roles from `Tool::Base`.
- [x] **Legacy Inlining:** Arrow, Blur, Censor, Ellipse, Rectangle, Text delegators inlined into `Tool::*` classes.
- [x] **UndoManager/CanvasOverlays:** Extracted from `DrawingTool.pm`.

### Screenshot Engine Modernization
- [x] **Moo for all Screenshot::* modules:** Error, History, Web, Window, WindowName, WindowXid, Workspace converted.
- [x] **Async Capture Pipeline:** `Main.pm`, `Workspace.pm`, `Window.pm` converted to `Future`-based async.
- [x] **SelectorAdvanced:** Ported to Cairo overlays with `InputManager` and `SelectionModel`.
- [x] **Window::Highlighter:** Extracted selection overlay role.
- [x] **Window::Geometry & Selector:** Extracted from Window.pm.

---

## Phase 1: Quality Gate (Current)

Establish a provable quality baseline and prevent regression during active refactoring.

- [x] **Install perlcritic:** `Perl::Critic` + `Test::Perl::Critic::Progressive` available in CI.
- [x] **Progressive Baseline:** `t/critic.t` now tracks violation counts per-policy and total — new violations cause test failure.
- [x] **Makefile:** `make lint` and `make test` work without `carton`.
- [x] **Fix syntax.t:** Restored `all_perl_files` using `Perl::Critic::Utils`.

**Baseline stats (perlcritic --brutal, all modules):**
- Total violations: 1,429 (progressive baseline)
- Top issues: `ProhibitInterpolationOfLiterals` (1,475), `ProhibitMagicNumbers` (551), `RequirePodSections` (539), `ProhibitTrailingWhitespace` (338), `RequireFinalReturn` (415)
- Severity-5 ("bugs"): 0 — all `ProhibitExplicitReturnUndef` eliminated

---

## Phase 2: Window.pm Decomposition (In Progress)

The roadmap's top structural priority — break up the largest remaining Shutter capture monolith.

**Progress:**
- 645 → **229 lines** (64% reduction — under the 300-line target 🎉)
- `window_async` method: ~397 → **66 lines** (6x reduction)
- `redo_capture_async` → extracted to `Window::CaptureManager` role
- `_capture_interactive` → extracted to `Window::Interaction` role (173 lines)
- `_capture_noninteractive` → moved to `Window::CaptureManager` role
- Bugfix: capture chain now always resolves future (shape loop no-match path hung)

- [x] Extract `redo_capture_async` → `Window::CaptureManager` role
- [x] Extract `_capture_interactive` → `Window::Interaction` role (new)
- [x] Extract `_capture_noninteractive` → `Window::CaptureManager`
- [x] Target: `Window.pm` under 300 lines ✔️
- [ ] Extract grab/setup preamble from `window_async`
- [ ] Extract `quit` / `quit_eventh_only` → `Window::Lifecycle` role or move to `Main.pm`
- [ ] Each extracted role written clean (zero new --brutal violations)

---

## Phase 3: Large Module Decomposition

Tackle remaining monoliths in the Draw subsystem.

| Module | Lines | Strategy |
|--------|-------|----------|
| `Draw::ToolbarManager` | 919 | Split tool registration from UI widget setup |
| `Draw::IOManager` | 906 | Decompose read/write/file-format handling |
| `Draw::PropertyManager` | 775 | Extract property UI from config management |
| `Draw::Tool::Base` | 754 | Already partially refactored; review remaining surface |
| `App::Menu` | 693 | Review if further splitting is warranted |

Each extraction writes clean Moo-based code with full signatures, `try`/`catch`, and Log::Any — zero new perlcritic violations, reducing the progressive baseline naturally.

---

## Phase 4: perlcritic --brutal Compliance

Rachet down the violation count module-by-module until `--brutal` passes clean.

**Mechanics:**
- As each module is touched for refactoring, clean up ALL its violations
- The progressive baseline drops automatically after each passing test run
- Periodically add per-policy step sizes to force targeted cleanup

| Priority | Policy | Count | Effort | Status |
|----------|--------|-------|--------|--------|
| P0 | `ProhibitExplicitReturnUndef` (sev 5) | 7 | Trivial — mechanical fix | ✅ Done |
| P1 | `ProhibitNoWarnings` (sev 4) | 109 | Tighten `no warnings` scopes | |
| P1 | `RequireFinalReturn` (sev 4) | 321 | Mechanical — add `return` | |
| P1 | `RequireArgUnpacking` (sev 4) | 71 | Already fixed in modern code | |
| P2 | `ProhibitExcessComplexity` (sev 3) | 47 | Fixed by decomposition | |
| P2 | `ProhibitDeepNests` (sev 3) | 43 | Fixed by decomposition | |
| P3 | `ProhibitInterpolationOfLiterals` (sev 3) | 1,475 | Cosmetic — string quoting | |
| P3 | `ProhibitMagicNumbers` (sev 3) | 551 | Named constants | |
| P3 | `RequirePodSections` (sev 3) | 539 | Documentation |

**Target:** Zero violations under `--brutal` across `bin/`, `share/shutter/resources/modules/`, and `t/`.

---

## Phase 5: GTK3 & HiDPI Polish

- [ ] **HiDPI Fixes:** Resolve menu capture and multi-monitor scaling issues.
- [ ] **Widget Modernization:** Replace deprecated `HBox/VBox` with `Gtk3::Box`.
- [ ] **SSH/X Forwarding:** Debug and fix issues with remote X sessions.
- [ ] **UI Refinement:** Improve "stickiness" of the selection cursor to region edges.

---

## Phase 6: Wayland Parity

- [ ] **Portal-based Capture:** Improve Wayland support via XDG Desktop Portals.
- [ ] **Native Backend:** Investigate native implementations for GNOME/KDE/Sway without XWayland.

---

## Phase 7: Upload System

- [ ] **Uploader Standardization:** Ensure all legacy uploaders (FTP, etc.) are converted to the new `UploadManager` pattern.
- [ ] **Post-Upload Actions:** Finalize "Copy URL" and "Generate QR Code" workflows.

---

## Phase 8: Quality & Documentation

- [ ] **Unit Testing:** Build a comprehensive test suite for `SessionManager` and `SettingsManager` using `Test2::V0`.
- [ ] **CI Integration:** Automate test runs via GitHub Actions.
- [ ] **Custom Policies:** Write project-specific perlcritic policies (e.g., "all Moo classes must end with `1;`").

---

## Phase 9: Future Vision (Backlog)

- [ ] **OCR Integration:** Tesseract-based text extraction from screenshots.
- [ ] **Plugin API:** Stable API for 3rd party "After Capture" and "Uploader" plugins.
