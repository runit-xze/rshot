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
| `ShareX.pm` | ShareX (`.sxcu`) upload | [View](GEMINI/Upload/ShareX.md) |
| `Catbox.pm` | Catbox.moe upload | [View](GEMINI/Upload/Catbox.md) |

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
## Additional Modules

### . Modules (`share/shutter/resources/modules/Shutter/./`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `App.pm` | TODO | [View](GEMINI/App.md) |

### App Modules (`share/shutter/resources/modules/Shutter/App/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `AboutDialog.pm` | TODO | [View](GEMINI/App/AboutDialog.md) |
| `AfterCapturePipeline.pm` | TODO | [View](GEMINI/App/AfterCapturePipeline.md) |
| `Autostart.pm` | TODO | [View](GEMINI/App/Autostart.md) |
| `CLI.pm` | TODO | [View](GEMINI/App/CLI.md) |
| `Common.pm` | TODO | [View](GEMINI/App/Common.md) |
| `Constants.pm` | TODO | [View](GEMINI/App/Constants.md) |
| `Directories.pm` | TODO | [View](GEMINI/App/Directories.md) |
| `GlobalSettings.pm` | TODO | [View](GEMINI/App/GlobalSettings.md) |
| `Handlers.pm` | TODO | [View](GEMINI/App/Handlers.md) |
| `HelperFunctions.pm` | TODO | [View](GEMINI/App/HelperFunctions.md) |
| `Init.pm` | TODO | [View](GEMINI/App/Init.md) |
| `Menu.pm` | TODO | [View](GEMINI/App/Menu.md) |
| `Notification.pm` | TODO | [View](GEMINI/App/Notification.md) |
| `Options.pm` | TODO | [View](GEMINI/App/Options.md) |
| `PinToScreen.pm` | TODO | [View](GEMINI/App/PinToScreen.md) |
| `Session.pm` | TODO | [View](GEMINI/App/Session.md) |
| `ShutterNotification.pm` | TODO | [View](GEMINI/App/ShutterNotification.md) |
| `SimpleDialogs.pm` | TODO | [View](GEMINI/App/SimpleDialogs.md) |
| `Toolbar.pm` | TODO | [View](GEMINI/App/Toolbar.md) |
| `UI.pm` | TODO | [View](GEMINI/App/UI.md) |
| `Workflow.pm` | TODO | [View](GEMINI/App/Workflow.md) |

### App/Core Modules (`share/shutter/resources/modules/Shutter/App/Core/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `ScreenshotHandler.pm` | TODO | [View](GEMINI/App/Core/ScreenshotHandler.md) |
| `SessionManager.pm` | TODO | [View](GEMINI/App/Core/SessionManager.md) |
| `SettingsManager.pm` | TODO | [View](GEMINI/App/Core/SettingsManager.md) |
| `UploadManager.pm` | TODO | [View](GEMINI/App/Core/UploadManager.md) |

### App/Events Modules (`share/shutter/resources/modules/Shutter/App/Events/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Edit.pm` | TODO | [View](GEMINI/App/Events/Edit.md) |
| `File.pm` | TODO | [View](GEMINI/App/Events/File.md) |
| `Screenshot.pm` | TODO | [View](GEMINI/App/Events/Screenshot.md) |

### App/Handlers Modules (`share/shutter/resources/modules/Shutter/App/Handlers/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Core.pm` | TODO | [View](GEMINI/App/Handlers/Core.md) |
| `Dialogs_Open.pm` | TODO | [View](GEMINI/App/Handlers/Dialogs_Open.md) |
| `Dialogs_Plugin.pm` | TODO | [View](GEMINI/App/Handlers/Dialogs_Plugin.md) |
| `Dialogs_Rename.pm` | TODO | [View](GEMINI/App/Handlers/Dialogs_Rename.md) |
| `Dialogs_Settings.pm` | TODO | [View](GEMINI/App/Handlers/Dialogs_Settings.md) |
| `Dialogs_Upload.pm` | TODO | [View](GEMINI/App/Handlers/Dialogs_Upload.md) |
| `Edit_Delete.pm` | TODO | [View](GEMINI/App/Handlers/Edit_Delete.md) |
| `Edit_Draw.pm` | TODO | [View](GEMINI/App/Handlers/Edit_Draw.md) |
| `Edit_Nav.pm` | TODO | [View](GEMINI/App/Handlers/Edit_Nav.md) |
| `Events_Control.pm` | TODO | [View](GEMINI/App/Handlers/Events_Control.md) |
| `Events_Init.pm` | TODO | [View](GEMINI/App/Handlers/Events_Init.md) |
| `Events_Tray.pm` | TODO | [View](GEMINI/App/Handlers/Events_Tray.md) |
| `Init_Accounts.pm` | TODO | [View](GEMINI/App/Handlers/Init_Accounts.md) |
| `Init_Handlers.pm` | TODO | [View](GEMINI/App/Handlers/Init_Handlers.md) |
| `Init_Model.pm` | TODO | [View](GEMINI/App/Handlers/Init_Model.md) |
| `Menu.pm` | TODO | [View](GEMINI/App/Handlers/Menu.md) |
| `Menu_Ret_Get.pm` | TODO | [View](GEMINI/App/Handlers/Menu_Ret_Get.md) |
| `Menu_Ret_Tray.pm` | TODO | [View](GEMINI/App/Handlers/Menu_Ret_Tray.md) |
| `Menu_Ret_Upload.pm` | TODO | [View](GEMINI/App/Handlers/Menu_Ret_Upload.md) |
| `Menu_Ret_UploadLinks.pm` | TODO | [View](GEMINI/App/Handlers/Menu_Ret_UploadLinks.md) |
| `Menu_Ret_Workspace.pm` | TODO | [View](GEMINI/App/Handlers/Menu_Ret_Workspace.md) |
| `Registry.pm` | TODO | [View](GEMINI/App/Handlers/Registry.md) |
| `Screenshot_Actions.pm` | TODO | [View](GEMINI/App/Handlers/Screenshot_Actions.md) |
| `Screenshot_InitTray.pm` | TODO | [View](GEMINI/App/Handlers/Screenshot_InitTray.md) |
| `Screenshot_Take.pm` | TODO | [View](GEMINI/App/Handlers/Screenshot_Take.md) |
| `Screenshot_GifRecord.pm` | GIF recording handler — countdown, region capture loop, stop UI | [View](GEMINI/App/Handlers/Screenshot_GifRecord.md) |
| `Screenshot_UI.pm` | TODO | [View](GEMINI/App/Handlers/Screenshot_UI.md) |
| `UI_Status.pm` | TODO | [View](GEMINI/App/Handlers/UI_Status.md) |
| `UI_Tabs.pm` | TODO | [View](GEMINI/App/Handlers/UI_Tabs.md) |
| `Upload_Execute.pm` | TODO | [View](GEMINI/App/Handlers/Upload_Execute.md) |
| `Upload_Main.pm` | TODO | [View](GEMINI/App/Handlers/Upload_Main.md) |
| `Util_File.pm` | TODO | [View](GEMINI/App/Handlers/Util_File.md) |
| `Util_Get.pm` | TODO | [View](GEMINI/App/Handlers/Util_Get.md) |
| `Workflow_Control.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Control.md) |
| `Workflow_Init.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Init.md) |
| `Workflow_Integrate.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Integrate.md) |
| `Workflow_Post.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Post.md) |
| `Workflow_Save.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Save.md) |
| `Workflow_Session.pm` | TODO | [View](GEMINI/App/Handlers/Workflow_Session.md) |

### App/Optional Modules (`share/shutter/resources/modules/Shutter/App/Optional/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Exif.pm` | TODO | [View](GEMINI/App/Optional/Exif.md) |

### App/UI Modules (`share/shutter/resources/modules/Shutter/App/UI/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `MainWindow.pm` | TODO | [View](GEMINI/App/UI/MainWindow.md) |
| `Menus.pm` | TODO | [View](GEMINI/App/UI/Menus.md) |
| `SettingsDialog.pm` | TODO | [View](GEMINI/App/UI/SettingsDialog.md) |
| `Windows.pm` | TODO | [View](GEMINI/App/UI/Windows.md) |

### App/UI/Settings Modules (`share/shutter/resources/modules/Shutter/App/UI/Settings/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Main.pm` | TODO | [View](GEMINI/App/UI/Settings/Main.md) |

### Draw Modules (`share/shutter/resources/modules/Shutter/Draw/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `CanvasManager.pm` | TODO | [View](GEMINI/Draw/CanvasManager.md) |
| `DrawingTool.pm` | TODO | [View](GEMINI/Draw/DrawingTool.md) |
| `Ellipse.pm` | TODO | [View](GEMINI/Draw/Ellipse.md) |
| `UIManager.pm` | TODO | [View](GEMINI/Draw/UIManager.md) |
| `Utils.pm` | TODO | [View](GEMINI/Draw/Utils.md) |

### Draw/Tool Modules (`share/shutter/resources/modules/Shutter/Draw/Tool/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Base.pm` | TODO | [View](GEMINI/Draw/Tool/Base.md) |
| `Ellipse.pm` | TODO | [View](GEMINI/Draw/Tool/Ellipse.md) |
| `Pen.pm` | TODO | [View](GEMINI/Draw/Tool/Pen.md) |
| `Registry.pm` | TODO | [View](GEMINI/Draw/Tool/Registry.md) |

### Geometry Modules (`share/shutter/resources/modules/Shutter/Geometry/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Region.pm` | TODO | [View](GEMINI/Geometry/Region.md) |

### Pixbuf Modules (`share/shutter/resources/modules/Shutter/Pixbuf/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Border.pm` | TODO | [View](GEMINI/Pixbuf/Border.md) |
| `Load.pm` | TODO | [View](GEMINI/Pixbuf/Load.md) |
| `Save.pm` | TODO | [View](GEMINI/Pixbuf/Save.md) |

### Screenshot Modules (`share/shutter/resources/modules/Shutter/Screenshot/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Error.pm` | TODO | [View](GEMINI/Screenshot/Error.md) |
| `History.pm` | TODO | [View](GEMINI/Screenshot/History.md) |
| `Main.pm` | TODO | [View](GEMINI/Screenshot/Main.md) |
| `SelectorAdvanced.pm` | TODO | [View](GEMINI/Screenshot/SelectorAdvanced.md) |
| `SelectorAuto.pm` | TODO | [View](GEMINI/Screenshot/SelectorAuto.md) |
| `Wayland.pm` | TODO | [View](GEMINI/Screenshot/Wayland.md) |
| `Web.pm` | TODO | [View](GEMINI/Screenshot/Web.md) |
| `Window.pm` | TODO | [View](GEMINI/Screenshot/Window.md) |
| `WindowName.pm` | TODO | [View](GEMINI/Screenshot/WindowName.md) |
| `WindowXid.pm` | TODO | [View](GEMINI/Screenshot/WindowXid.md) |
| `Workspace.pm` | TODO | [View](GEMINI/Screenshot/Workspace.md) |
| `GifRecorder.pm` | Animated GIF recording engine — frame grab, temp storage, ImageMagick assembly | [View](GEMINI/Screenshot/GifRecorder.md) |

### Upload Modules (`share/shutter/resources/modules/Shutter/Upload/`)

| Module | Purpose | GEMINI.md |
|--------|---------|-----------|
| `Catbox.pm` | TODO | [View](GEMINI/Upload/Catbox.md) |
| `ShareX.pm` | TODO | [View](GEMINI/Upload/ShareX.md) |
| `Role/Uploader.pm` | TODO | [View](GEMINI/Upload/Role/Uploader.md) |

