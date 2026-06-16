# Shutter::App::Handlers::Workflow_Post

## Purpose
This module manages post-action workflows, such as finalizing settings changes and updating the application state after user interactions in dialogs.

## Usage
Typically called after the user closes the settings dialog or performs an action that requires a state update across the application.

## Dependencies
*   `Moo`
*   `Gtk3`
*   `Glib`
*   `Shutter::App::Directories`

## Key Functions/Methods
*   **`fct_post_settings`**: 
    *   Finalizes settings after the settings dialog is closed.
    *   Ensures the profile combobox matches the active profile.
    *   Hides the settings dialog.
    *   Triggers saving of settings to disk.
    *   Updates the autostart configuration based on current settings.
    *   Triggers updates for the tray icon and general application information.
