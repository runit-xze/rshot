# Shutter::App::Core::SessionManager

## Purpose
Manages session state including open screenshots, tab management, and session persistence.

## Location
`share/shutter/resources/modules/Shutter/App/Core/SessionManager.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `integrate_screenshot($giofile, $pixbuf, $history, $count)`
Integrates a captured screenshot into the session notebook.
- Creates tab with thumbnail/view
- Handles undo/redo history
- Manages tab indexing

### `fct_get_latest_tab_key()`
Returns the highest tab index number for generating new keys.

### `get_session_screens()`
Returns the hash of all open screenshots in session.

### `get_session_start_screen()`
Returns the first page session data for the session view.

## Dependencies
- `Shutter::App::Common` - Application state
- `Shutter::App::SimpleDialogs` - Error dialogs
- `Gtk3` - GUI components
- `File::Copy` - File operations

## Data Structures
```perl
%session_screens = (
    $key => {
        'giofile' => Glib::IO::File,
        'long' => $filepath,
        'image' => Gtk3::ImageView,
        'tab_child' => Gtk3::Widget,
        'undo' => [ @files ],
        'redo' => [ @files ],
        'history' => DateTime::Format::ISO8601 object,
    }
)
```

## Related
- See `Shutter::App::Common` for shared state
- See `Shutter::Screenshot::*` for capture modules