# Shutter::App::Init

## Purpose
Core modular initialization that creates and connects all application managers and components.

## Location
`share/shutter/resources/modules/Shutter/App/Init.pm`

## Key Methods

### `initialize($cli)`
Creates and initializes all core application objects:
- SessionManager for tab/session state
- SettingsManager for settings persistence
- ScreenshotHandler for capture orchestration
- UploadManager for upload functionality
- AfterCapturePipeline for post-capture workflow
- Pixbuf loaders and savers
- Stores backward-compatible references on CLI object

## Returned State
```perl
$cli->{session_manager} = Shutter::App::Core::SessionManager instance
$cli->{settings_manager} = Shutter::App::Core::SettingsManager instance
$cli->{screenshot_handler} = Shutter::App::Core::ScreenshotHandler instance
$cli->{upload_manager} = Shutter::App::Core::UploadManager instance
$cli->{session_screens} = {}  # Session hash for tab management
$cli->{session_start_screen} = { first_page => {} }  # First tab data
```

## Dependencies
- `Shutter::App::Constants`
- `Shutter::App::Core::*` managers
- `Shutter::App::AfterCapturePipeline`
- `Shutter::App::PinToScreen`
- `Shutter::Pixbuf::*`

## Related
- See `Shutter::App::CLI` as entry point
- See `Shutter::App::UI::Windows` for window creation