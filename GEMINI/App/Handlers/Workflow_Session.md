# Shutter::App::Handlers::Workflow_Session

## Purpose
This module is responsible for managing the session-related UI components, primarily the main notebook and the "Session" (index) tab.

## Usage
Called during application initialization to set up the main interface and whenever a new tab needs to be created for a screenshot.

## Dependencies
*   `Moo`
*   `Gtk3`
*   `Glib`
*   `Gtk3::ImageView` (optional/dynamic)
*   `Shutter::App::Handlers::Events_Tray`
*   `Shutter::App::Handlers::Screenshot_UI`

## Key Functions/Methods
*   **`fct_create_session_notebook`**: 
    *   Configures the main `Gtk3::Notebook`.
    *   Sets up Drag-and-Drop (DnD) support for files.
    *   Creates the first "Session" tab which shows an overview of all captures.
*   **`fct_create_tab`**: 
    *   Creates a new tab page (either for a specific image or the session overview).
    *   For images: Sets up a `Gtk3::ImageView` within a scrolled window and adds event handlers for zooming and context menus.
    *   For the session overview: Sets up a `Gtk3::IconView` with a `Gtk3::ListStore` model and enables DnD source capabilities.
