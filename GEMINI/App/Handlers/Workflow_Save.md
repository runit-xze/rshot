# Shutter::App::Handlers::Workflow_Save

## Purpose
This module provides handlers for loading and saving application settings, session data, and account information.

## Usage
Used throughout the application whenever state needs to be persisted to or restored from disk (typically in XML format).

## Dependencies
*   `Moo`
*   `XML::Simple`
*   `IO::File`
*   `File::Temp`
*   `File::Copy`

## Key Functions/Methods
*   **`fct_load_settings`**: 
    *   Loads settings from `~/.shutter/settings.xml` or a specific profile XML file.
    *   Uses `XML::Simple` to parse the file.
    *   Handles errors gracefully, showing a message to the user if settings cannot be restored.
*   **`fct_save_settings`**: 
    *   Saves the current application state to `~/.shutter/settings.xml` or a profile-specific file.
    *   Employs a safe-write pattern using a temporary file and `File::Copy::move`.
    *   Also handles saving session and account data.
