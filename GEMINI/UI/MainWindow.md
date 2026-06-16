# Shutter::App::UI::MainWindow

## Purpose
Creates and manages the main application window including layout, menus, and toolbars.

## Location
`share/shutter/resources/modules/Shutter/App/UI/MainWindow.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `create_main_window($app)`
Creates the main GTK ApplicationWindow.
- Sets default size (500px height)
- Configures window properties
- Returns window object

### `create_menu()`
Builds the main menu bar.
- Delegates to `Shutter::App::Menu`

### `create_toolbar()`
Creates the main toolbar.
- Delegates to `Shutter::App::Toolbar`

### `create_session_notebook()`
Creates the tabbed interface for screenshots.
- Session view (icon view)
- Individual screenshot tabs

## Window Structure

```
MainWindow (Gtk3::ApplicationWindow)
├── MenuBar (from Menu.pm)
├── Toolbar (from Toolbar.pm)
├── Notebook (session tabs)
│   ├── Session Tab (icon view)
│   └── Screenshot Tabs (image views)
└── StatusBar (status messages)
```

## Dependencies
- `Shutter::App::Menu` - Menu creation
- `Shutter::App::Toolbar` - Toolbar creation
- `Shutter::App::Common` - Application state

## Related
- See `Shutter::App::Menu` for menu structure
- See `Shutter::App::Toolbar` for toolbar buttons
- See `Shutter::App::UI::SettingsDialog` for preferences