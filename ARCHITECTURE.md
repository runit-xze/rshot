# Shutter Architecture & Component Map

This document serves as an index for the Shutter codebase documentation.

## Architecture Overview

Shutter is a GTK-based screenshot application written in Perl. The codebase follows a modular architecture separating concerns into distinct components.

### Entry Point
- `bin/shutter` - Main application entry point (88 LOC)
- `Shutter::App::CLI` - Main application controller (277 LOC)

### Core Architecture

```
bin/shutter (entry point)
├── UI Layer - Main window, menus, dialogs
├── Core Layer - Session, Settings, Screenshot, Upload managers
├── Existing Modules - Reusable components
└── Event Handlers - User interaction callbacks
```

## Components

### Core Modules (`share/shutter/resources/modules/Shutter/App/Core/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `SessionManager.pm` | Session state and tab management | [View](GEMINI/Core/SessionManager.md) |
| `SettingsManager.pm` | Settings persistence and profiles | [View](GEMINI/Core/SettingsManager.md) |
| `ScreenshotHandler.pm` | Screenshot capture orchestration | [View](GEMINI/Core/ScreenshotHandler.md) |
| `UploadManager.pm` | File upload functionality | [View](GEMINI/Core/UploadManager.md) |

### UI Modules (`share/shutter/resources/modules/Shutter/App/UI/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `MainWindow.pm` | Main window creation and layout | [View](GEMINI/UI/MainWindow.md) |
| `SettingsDialog.pm` | Settings dialog management | [View](GEMINI/UI/SettingsDialog.md) |

### Existing Application Modules (`share/shutter/resources/modules/Shutter/App/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Common.pm` | Application state container | [View](GEMINI/App/Common.md) |
| `HelperFunctions.pm` | Utility functions | [View](GEMINI/App/HelperFunctions.md) |
| `Options.pm` | Command-line argument parsing | [View](GEMINI/App/Options.md) |
| `Menu.pm` | Menu system | [View](GEMINI/App/Menu.md) |
| `Toolbar.pm` | Toolbar UI | [View](GEMINI/App/Toolbar.md) |
| `SimpleDialogs.pm` | Dialog helpers | [View](GEMINI/App/SimpleDialogs.md) |
| `Directories.pm` | Path management | [View](GEMINI/App/Directories.md) |
| `Autostart.pm` | Autostart file management | [View](GEMINI/App/Autostart.md) |
| `Notification.pm` | System notifications | [View](GEMINI/App/Notification.md) |
| `ShutterNotification.pm` | Built-in notifications | [View](GEMINI/App/ShutterNotification.md) |
| `GlobalSettings.pm` | Global configuration | [View](GEMINI/App/GlobalSettings.md) |
| `AboutDialog.pm` | About dialog | [View](GEMINI/App/AboutDialog.md) |
| `AfterCapturePipeline.pm` | Post-capture workflow | [View](GEMINI/App/AfterCapturePipeline.md) |
| `PinToScreen.pm` | Window pinning | [View](GEMINI/App/PinToScreen.md) |

### Pixbuf Modules (`share/shutter/resources/modules/Shutter/Pixbuf/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Save.pm` | Image saving | [View](GEMINI/Pixbuf/Save.md) |
| `Load.pm` | Image loading | [View](GEMINI/Pixbuf/Load.md) |
| `Border.pm` | Image borders | [View](GEMINI/Pixbuf/Border.md) |

### Screenshot Modules (`share/shutter/resources/modules/Shutter/Screenshot/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Main.pm` | Main screenshot logic | [View](GEMINI/Screenshot/Main.md) |
| `SelectorAdvanced.pm` | Advanced selection tool | [View](GEMINI/Screenshot/SelectorAdvanced.md) |
| `SelectorAuto.pm` | Auto selection | [View](GEMINI/Screenshot/SelectorAuto.md) |
| `Workspace.pm` | Full workspace capture | [View](GEMINI/Screenshot/Workspace.md) |
| `Window.pm` | Window capture | [View](GEMINI/Screenshot/Window.md) |
| `Web.pm` | Website capture | [View](GEMINI/Screenshot/Web.md) |
| `Error.pm` | Error handling | [View](GEMINI/Screenshot/Error.md) |
| `Wayland.pm` | Wayland support | [View](GEMINI/Screenshot/Wayland.md) |

### Upload Modules (`share/shutter/resources/modules/Shutter/Upload/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `FTP.pm` | FTP upload | [View](GEMINI/Upload/FTP.md) |
| `ShareX.pm` | ShareX upload | [View](GEMINI/Upload/ShareX.md) |
| `Shared.pm` | Shared upload logic | [View](GEMINI/Upload/Shared.md) |

### Draw Modules (`share/shutter/resources/modules/Shutter/Draw/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `DrawingTool.pm` | Drawing tool UI | [View](GEMINI/Draw/DrawingTool.md) |
| `UIManager.pm` | Drawing UI management | [View](GEMINI/Draw/UIManager.md) |
| `Utils.pm` | Drawing utilities | [View](GEMINI/Draw/Utils.md) |
| `Ellipse.pm` | Ellipse shapes | [View](GEMINI/Draw/Ellipse.md) |

### Geometry Module (`share/shutter/resources/modules/Shutter/Geometry/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Region.pm` | Region calculations | [View](GEMINI/Geometry/Region.md) |

## Development Guidelines

1. **Module Structure**: Each module should follow the Moo object system
2. **Dependencies**: Check existing modules before adding new ones
3. **Naming**: Use `Shutter::App::*` for application modules
4. **Documentation**: Keep GEMINI.md files updated when modifying code