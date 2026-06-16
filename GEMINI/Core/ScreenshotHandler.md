# Shutter::App::Core::ScreenshotHandler

## Purpose
Orchestrates screenshot capture workflow including delays, notifications, and error handling.

## Location
`share/shutter/resources/modules/Shutter/App/Core/ScreenshotHandler.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `take_screenshot($widget, $data, $folder_from_config, $extra)`
Main entry point for screenshot capture.
- Handles window hide/show logic
- Manages capture delays
- Dispatches to specific capture type

### `fct_take_screenshot($widget, $data, $folder_from_config, $extra)`
Performs actual screenshot capture.
- Delegates to `Shutter::Screenshot::*` modules
- Handles clipboard import
- Integrates result into session

## Capture Types
- `full` - Full screen
- `window` - Window selection
- `select` - Area selection
- `menu` - Menu capture
- `tooltip` - Tooltip capture
- `web` - Website capture
- `redoshot` - Repeat last capture

## Event Flow
1. User triggers capture (menu, toolbar, keybinding)
2. `evt_take_screenshot()` called
3. Window hidden if configured
4. Delay timer started if configured
5. `fct_take_screenshot()` captures image
6. Result integrated into session notebook
7. Notification shown
8. Window restored if configured

## Dependencies
- `Shutter::Screenshot::Main` - Core capture logic
- `Shutter::App::SimpleDialogs` - Error dialogs
- `Shutter::App::Notification` - User notifications
- `Gtk3::Clipboard` - Paste from clipboard

## Related
- See `Shutter::Screenshot::Main` for capture implementation
- See `Shutter::App::AfterCapturePipeline` for post-processing