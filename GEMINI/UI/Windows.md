# Shutter::App::UI::Windows

## Purpose
Creates and configures the main application window with all UI components.

## Location
`share/shutter/resources/modules/Shutter/App/UI/Windows.pm`

## Key Methods

### `new(cli => $cli)`
Constructor. Creates window, vbox container, and connects menu/toolbar.

### `get_window()`
Returns the Gtk3::ApplicationWindow instance.

### `get_vbox()`
Returns the main Gtk3::VBox container.

## UI Structure
```
window (Gtk3::ApplicationWindow)
└── vbox (Gtk3::VBox)
    ├── menu (from Shutter::App::Menu)
    ├── toolbar (from Shutter::App::Toolbar)
    └── statusbar (Gtk3::Statusbar)
```

## Dependencies
- `Gtk3` - UI components
- `Shutter::App::Menu` - Menu creation
- `Shutter::App::Toolbar` - Toolbar creation

## Related
- See `Shutter::App::UI::Menus` for signal wiring
- See `Shutter::App::CLI` as entry point