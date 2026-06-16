# Shutter::App::Menu

## Purpose
This module is responsible for creating and managing the main application menu bar and its submenus (File, Edit, View, Screenshot, Go, Help).

## Usage
Initialized during the application's UI setup phase. It constructs the GTK3 menu hierarchy and associates keyboard accelerators.

## Dependencies
*   `Gtk3`
*   `Glib`
*   `Shutter::App::HelperFunctions`

## Key Functions/Methods
*   **`create_menu`**: The main entry point to construct the entire menubar.
*   **`fct_ret_file_menu`**: Constructs the File menu (New, Open, Save As, Export, Print, Quit).
*   **`fct_ret_edit_edit`**: Constructs the Edit menu (Undo, Redo, Copy, Settings).
*   **`fct_ret_view_menu`**: Constructs the View menu (Toolbar visibility, Zoom controls, Fullscreen).
*   **`fct_ret_actions_menu`**: Constructs the Screenshot/Actions menu (Open with, Rename, Send To, Export, Edit).
*   **`fct_ret_session_menu`**: Constructs the Session/Go menu (Back, Forward, First, Last).
*   **`fct_ret_help_menu`**: Constructs the Help menu (Online Help, Translate, Report Problem, About).
*   **`fct_ret_new_menu`**: Constructs the New capture submenu (Selection, Desktop, Window, etc.).
