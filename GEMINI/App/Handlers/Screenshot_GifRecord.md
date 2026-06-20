# Shutter::App::Handlers::Screenshot_GifRecord

**File Path:** `share/shutter/resources/modules/Shutter/App/Handlers/Screenshot_GifRecord.pm`

## Description

Handler for the GIF recording capture mode. Manages the full lifecycle: region
selection (via `SelectorAdvanced` or `Window`), Cairo countdown overlay, recorder
start/stop, floating stop button, and after-capture pipeline integration.

## Key Methods

- `evt_gif_record($widget, $data, $folder, $extra)` — Entry point wired from menu/toolbar.
- `_start_capture_flow($data, $folder, $extra)` — Dispatches to region or window selection.
- `_show_countdown($region, $on_done)` — Renders a Cairo 3-2-1 countdown overlay.
- `_begin_recording($data, $region, $folder)` — Instantiates `GifRecorder` and starts capture.
- `_show_stop_ui()` — Displays a floating "Stop Recording" button.
- `_on_recording_done($gif_path)` — Integrates the GIF into the session and runs the pipeline.

## Supported Data Tokens

| Token | Description |
|-------|-------------|
| `gif_select` / `tray_gif_select` | Region-based GIF recording |
| `gif_window` / `tray_gif_window` | Window-based GIF recording |
