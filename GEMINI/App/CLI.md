# Shutter::App::CLI

## Purpose
New modular application entry point that orchestrates the initialization of all application components.

## Location
`share/shutter/resources/modules/Shutter/App/CLI.pm`

## Key Methods

### `new(shutter_root => $path)`
Constructor. Requires the root directory path.

### `run()`
Main entry point. Initializes app, creates objects, and runs the Gtk3 main loop.

### `_setup_app()`
Creates the Gtk3::Application and connects activation signals.

### `_create_core_objects()`
Creates the Common, HelperFunctions, and Options objects.

### `_initialize_modules()`
Instantiates all modular components:
- `Shutter::App::UI::Windows` for window creation
- `Shutter::App::UI::Menus` for menu/toolbar wiring
- `Shutter::App::Events::*` for event handlers
- `Shutter::App::Workflow` for post-capture workflow

## Attributes
- `shutter_root` - Application root directory
- `sc` - Shutter::App::Common instance (state container)
- `shf` - Shutter::App::HelperFunctions instance
- `so` - Shutter::App::Options instance
- `app` - Gtk3::Application instance
- `window` - Main application window

## Dependencies
- `Shutter::App::Constants` - Version/constants
- `Shutter::App::Common` - State container
- `Shutter::App::HelperFunctions` - Utilities
- `Shutter::App::Options` - CLI parsing
- `Shutter::App::Init` - Modular initialization
- `Shutter::App::UI::*` - UI modules
- `Shutter::App::Events::*` - Event handlers
- `Shutter::App::Workflow` - Workflow setup

## Related
- See `Shutter::App::Init` for object creation
- See `Shutter::App::Common` for shared state