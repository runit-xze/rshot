# Shutter Modular Refactoring Roadmap

This document outlines the ongoing work to transition Shutter from a monolithic `bin/shutter` architecture to a modern, modular Moo-based design.

## Current Status

### Completed (Committed)
- `Shutter::App::UI` module created for UI orchestration
- ShareX `.sxcu` uploader support implemented with URL shortening via TinyURL
- QR code display via `qrencode` integrated
- AfterCapturePipeline module for configurable task workflows
- PinToScreen module for floating screenshot overlay
- File naming macros implementation (`%y`, `%mo`, `%d`, `%h`, `%mi`, `%s`, `%pn`, `%wt`, `%ww`, `%wh`)
- Modernized codebase to Perl v5.40 (header pragmas, try/catch, subroutine signatures)
- Dropped 5 external dependencies, replaced with core Perl implementations
- Removed gnome-web-photo and Image::Magick/Proc::Simple requirements

### In Progress (Untracked Files)
- `Shutter::App::CLI` - New application entry point
- `Shutter::App::Constants` - Project-wide constants
- `Shutter::App::Init` - Core object initialization
- `Shutter::App::Session` - Session tab management
- `Shutter::App::Workflow` - After-capture pipeline setup
- Core modules in `Shutter::App::Core/`:
  - `SessionManager` - Session state and tab management
  - `SettingsManager` - Settings persistence and profiles
  - `ScreenshotHandler` - Screenshot capture orchestration
  - `UploadManager` - File upload functionality
- UI modules in `Shutter::App::UI/`:
  - `Windows` - Main window creation and layout
  - `Menus` - Menu and toolbar signal wiring
- Event modules in `Shutter::App::Events/`:
  - `File` - File operation handlers
  - `Screenshot` - Screenshot-related events
  - `Edit` - Edit action handlers
- Handler modules in `Shutter::App::Handlers/` - Extracted ~1500+ lines of subroutines

## Architecture Vision

```
Shutter::App::CLI (entry point)
├── Shutter::App::UI::Windows (main window)
├── Shutter::App::UI::Menus (menu/toolbar wiring)
├── Shutter::App::Core::SessionManager (tab/session state)
├── Shutter::App::Core::SettingsManager (settings/profiles)
├── Shutter::App::Core::ScreenshotHandler (capture logic)
├── Shutter::App::Core::UploadManager (upload logic)
├── Shutter::App::AfterCapturePipeline (post-capture workflow)
├── Shutter::App::PinToScreen (floating overlay)
└── Shutter::App::Event::* (event handlers)
```

## Phase 1: Module Integration (In Progress)

- [ ] Wire `Shutter::App::CLI` as primary entry point (replace bin/shutter bottom section)
- [ ] Complete `Shutter::App::Init::initialize` to create all core objects
- [ ] Integrate `Shutter::App::UI::Windows` for window creation
- [ ] Integrate `Shutter::App::UI::Menus` for menu/toolbar signals
- [ ] Connect `Shutter::App::Session` to notebook widget
- [ ] Ensure `AfterCapturePipeline` is initialized and connected to settings

## Phase 2: Handler Migration

- [ ] Migrate screenshot action handlers from `bin/shutter` to `Shutter::App::Handlers::Screenshot_Actions`
- [ ] Migrate edit handlers to `Shutter::App::Handlers::Edit_*` modules
- [ ] Migrate dialog handlers to `Shutter::App::Handlers::Dialogs_*` modules
- [ ] Migrate upload handlers to `Shutter::App::Handlers::Upload_*` modules
- [ ] Migrate menu handlers to `Shutter::App::Handlers::Menu_*` modules

## Phase 3: API Modernization

- [ ] Replace package-global variables with object attributes
- [ ] Replace direct subroutine calls with handler registry pattern (`Shutter::App::Handlers`)
- [ ] Ensure all modules use Moo with proper dependency injection
- [ ] Add proper error handling with try/catch throughout

## Phase 4: Testing & Integration

- [ ] Test application startup with new modular architecture
- [ ] Verify screenshot capture and save functionality
- [ ] Verify upload pipeline execution
- [ ] Verify workflow configuration in Preferences
- [ ] Verify Pin to Screen feature

## Phase 5: Cleanup

- [ ] Remove redundant code from `bin/shutter`
- [ ] Remove deprecated global variable usage
- [ ] Update documentation (GEMINI.md files)
- [ ] Ensure backward compatibility with plugins

## Known Issues

- Handler modules still reference globals like `$sc`, `$d`, `$session_screens`
- Some event modules call subroutines that haven't been migrated yet
- Settings dialog integration needs completion

## Dependencies

The modular architecture requires these modules to be loaded in order:
1. `Shutter::App::Constants` - First, for version/app constants
2. `Shutter::App::Common` - Core state container
3. `Shutter::App::HelperFunctions` - Utility functions
4. `Shutter::App::Options` - CLI argument parsing
5. `Shutter::App::Init` - Object initialization
6. `Shutter::App::UI::*` - UI components
7. `Shutter::App::Events::*` - Event handlers
8. `Shutter::App::Workflow` - Workflow setup