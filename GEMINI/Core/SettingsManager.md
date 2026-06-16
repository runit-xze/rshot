# Shutter::App::Core::SettingsManager

## Purpose
Handles application settings persistence, profile management, and account storage.

## Location
`share/shutter/resources/modules/Shutter/App/Core/SettingsManager.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `save_settings($profilename)`
Saves current settings to XML file.
- Writes to `~/.shutter/settings.xml` or profile-specific file
- Handles atomic write via temp file

### `load_settings($data, $profilename)`
Loads settings from XML file.
- Supports profile-specific settings
- Handles migration detection

### `load_accounts($profilename)`
Loads upload account credentials from XML.
- Validates plugin paths exist
- Handles profile-specific accounts

### `get_profiles()`
Returns list of available profiles from `~/.shutter/profiles/`.

## File Locations

| File | Purpose |
|------|---------|
| `~/.shutter/settings.xml` | Main settings |
| `~/.shutter/profiles/*.xml` | Profile-specific settings |
| `~/.shutter/accounts.xml` | Upload account credentials |
| `~/.shutter/session.xml` | Open session state |

## Settings Structure
```perl
%settings = (
    'general' => {
        'filetype' => 0,
        'quality' => 90,
        'folder' => '/path/to/screenshots',
        'filename' => '$name_%NNN',
        'cursor' => 0,
        'delay' => 0,
        # ... many more
    },
    'gui' => {
        'btoolbar_active' => 1,
    },
    'recent' => {
        'ruu_tab' => 0,
        'ruu_hosting' => 0,
    }
)
```

## Related
- See `Shutter::App::GlobalSettings` for runtime settings
- See `Shutter::App::Directories` for path resolution