# Shutter::App::Options

## Purpose
This module handles command-line argument parsing for Shutter.

## Usage
Called at application startup to process flags like `--full`, `--select`, `--debug`, and to identify any image files passed as arguments to be opened.

## Dependencies
*   `Getopt::Long`
*   `Pod::Usage`
*   `Encode`
*   `Log::Any`

## Key Functions/Methods
*   **`get_options`**: 
    *   Uses `Getopt::Long` to parse standard and project-specific CLI options.
    *   Maps options to state changes in the `Common` state object (`sc`).
    *   Handles `--help` and `--version` by printing and exiting.
    *   Collects any remaining arguments (potential filenames) and returns them as an array reference.
