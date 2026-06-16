# Shutter::App::Session

## Purpose
Manages the session notebook where screenshots are displayed as tabs.

## Location
`share/shutter/resources/modules/Shutter/App/Session.pm`

## Key Methods

### `new(cli => $cli)`
Constructor. Creates SessionManager and notebook widget.

### `create_notebook()`
Returns the Gtk3::Notebook widget for session display.

### `add_tab($content, $label)`
Adds a new tab to the notebook with content and label.

## Attributes
- `cli` - Reference to CLI object
- `manager` - Shutter::App::Core::SessionManager instance
- `notebook` - Gtk3::Notebook widget

## Dependencies
- `Shutter::App::Core::SessionManager` - Session state management
- `Gtk3` - UI components

## Related
- See `Shutter::App::Core::SessionManager` for tab key management
- See `Shutter::App::CLI` for parent object