# Shutter::App::Handlers::Workflow_Init

## Purpose
This module provides handlers for various initialization tasks during the Shutter application's startup workflow. These tasks include setting up debug output, checking for external dependencies, and cleaning up temporary unsaved files.

## Usage
The functions within this module are typically called during the application's initial setup phase to ensure the environment is correctly configured and necessary dependencies are available. It relies on the `cli` object for state management.

## Dependencies
*   `Moo`
*   `Gtk3`
*   `Glib`
*   `File::Glob`
*   `IPC::Cmd`
*   `Log::Any`
*   `Shutter::App::Directories`
*   `Shutter::App::Constants`

## Key Functions/Methods
*   **`fct_init_debug_output`**: Gathers system information (kernel, OS, Glib/Gtk3 versions) and logs it for debugging purposes.
*   **`fct_init_depend`**: Checks for the presence of external tools and libraries (e.g., ImageMagick, gnome-web-photo, GooCanvas2, Image::ExifTool, AppIndicator) and updates the application's `cli` object with their availability status.
*   **`fct_init_unsaved_files`**: Scans the cache directory and deletes any unsaved temporary files that are not associated with the current Shutter session.
