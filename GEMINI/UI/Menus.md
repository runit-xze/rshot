# Shutter::App::UI::Menus

## Purpose
Connects menu items and toolbar buttons to their respective event handlers.

## Location
`share/shutter/resources/modules/Shutter/App/UI/Menus.pm`

## Key Methods

### `new(cli => $cli)`
Constructor. Creates menu/toolbar and connects all signals.

### `_connect_menu_items()`
Connects menu item activate signals to handlers.

### `_connect_toolbar_items()`
Connects toolbar button click signals to handlers.

## Signal Connections

| Widget | Signal | Handler |
|--------|--------|---------|
| `_menuitem_open` | activate | `fct_open_files` |
| `_menuitem_quit` | activate | `evt_delete_window` |
| `_redoshot` | clicked | `evt_take_screenshot('redoshot')` |
| `_select` | clicked | `evt_take_screenshot('select')` |
| `_full` | clicked | `evt_take_screenshot('full')` |
| `_window` | clicked | `evt_take_screenshot('window')` |
| `_menu` | clicked | `evt_take_screenshot('menu')` |
| `_tooltip` | clicked | `evt_take_screenshot('tooltip')` |

## Dependencies
- `Gtk3` - UI components
- `Shutter::App::Menu` - Menu object
- `Shutter::App::Toolbar` - Toolbar object

## Related
- See `Shutter::App::Events::*` for handler implementations
- See `Shutter::App::CLI` as entry point