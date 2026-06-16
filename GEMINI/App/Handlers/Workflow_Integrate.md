# Shutter::App::Handlers::Workflow_Integrate

## Purpose
This module handles the integration of new screenshots into the Shutter application's main user interface, specifically within the notebook component (the tabs at the bottom).

## Usage
It is called after a screenshot has been successfully captured and saved, or when a file is opened, to create the necessary UI elements to display the image.

## Dependencies
*   `Moo`
*   `Gtk3`
*   `Glib`
*   `URI::Escape`
*   `Shutter::App::Handlers::Menu_Ret_Get`
*   `Shutter::App::Handlers::Workflow_Session`
*   `Shutter::App::Handlers::UI_Status`
*   `Shutter::App::Handlers::Events_Init`

## Key Functions/Methods
*   **`fct_integrate_screenshot_in_notebook`**: 
    *   Takes a `GFile` object and an optional pixbuf/history.
    *   Validates the file exists and is a supported image type.
    *   Adds the file to the system's `RecentManager`.
    *   Calculates the appropriate tab index and label.
    *   Creates a new tab in the notebook using `Shutter::App::Handlers::Workflow_Session`.
    *   Sets up the tab label with a close button.
    *   Initiates file monitoring for the new image.
    *   Returns the unique key (label) for the new tab.
