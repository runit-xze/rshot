# Shutter::App::UI::SettingsDialog

## Purpose
Manages the preferences/settings dialog window.

## Location
`share/shutter/resources/modules/Shutter/App/UI/SettingsDialog.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `create_settings_dialog($window)`
Creates the settings dialog.
- Modal dialog with notebook tabs
- Tabs: Main, Advanced, Actions, Image View, Behavior, Upload, Plugins

### `show()`
Displays the dialog and runs modal loop.

### `hide()`
Hides the dialog.

## Dialog Structure

The settings dialog contains multiple tabs:

| Tab | Purpose |
|-----|---------|
| Main | File format, save behavior, filename |
| Advanced | Capture settings, delays, borders |
| Actions | Post-capture actions (open with, copy) |
| Image View | Transparency, thumbnail settings |
| Behavior | Autostart, hide behavior, notifications |
| Upload | FTP credentials, account management |
| Plugins | Effect plugins configuration |
| Workflow | After-capture pipeline (ShareX) |

## Profile Management
- Profile selection combobox
- Save/Delete profile buttons
- Apply profile functionality

## Dependencies
- `Shutter::App::SimpleDialogs` - Dialog helpers
- `Shutter::App::HelperFunctions` - Utility functions
- `Gtk3` - UI components

## Related
- See `Shutter::App::Core::SettingsManager` for persistence
- See `Shutter::App::GlobalSettings` for runtime settings