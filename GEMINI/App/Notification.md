# Shutter::App::Notification

## Purpose
This module provides a wrapper for system-level desktop notifications using DBus (`org.freedesktop.Notifications`).

## Usage
Used to show informational messages to the user that persist outside the main application window.

## Dependencies
*   `Net::DBus`
*   `Log::Any`
*   `Glib`

## Key Functions/Methods
*   **`show`**: 
    *   Sends a notification to the desktop environment.
    *   Takes a summary and body text.
    *   Returns a notification ID (`nid`) which can be used to close or update the notification.
*   **`close`**: 
    *   Closes an active notification by its ID.
