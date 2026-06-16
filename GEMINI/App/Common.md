# Shutter::App::Common

## Purpose
Central application state container using Moo roles.

## Location
`share/shutter/resources/modules/Shutter/App/Common.pm`

## Attributes

### Required
- `shutter_root` - Installation path
- `main_window` - Main GTK window
- `appname`, `version`, `rev`, `pid` - Application metadata

### Configuration
- `debug` - Enable debug output
- `clear_cache` - Clear caches on startup
- `min` - Start minimized
- `disable_systray` - Disable system tray
- `exit_after_capture` - Exit after capture

### State
- `gettext_object` - Translation handler
- `icontheme` - Icon theme
- `notification` - Notification handler
- `global_settings` - Global settings object

### Recently Used
- `ruu_tab`, `ruu_hosting`, `ruu_places` - Recent upload locations
- `rusf`, `ruof` - Recent save/open folders

## Methods

### Getters
- `get_root()`, `get_appname()`, `get_version()`, `get_rev()`
- `get_gettext()`, `get_theme()`, `get_notification_object()`
- `get_mainwindow()`, `get_debug()`, `get_min()`
- `get_start_with()`, `get_profile_to_start_with()`

### Setters
- `set_mainwindow()`, `set_notification_object()`
- `set_debug()`, `set_clear_cache()`, `set_min()`
- `set_start_with()`, `set_export_filename()`
- `set_delay()`, `set_include_cursor()`, `set_remove_cursor()`

## Usage
```perl
my $common = Shutter::App::Common->new(
    shutter_root => $shutter_root,
    main_window => $window,
    appname => SHUTTER_NAME,
    version => SHUTTER_VERSION,
    rev => SHUTTER_REV,
    pid => $PID,
);
```

## Dependencies
- `Moo` - Object system
- `Gtk3` - GUI toolkit
- `Locale::gettext` - Internationalization
- `POSIX` - Locale handling