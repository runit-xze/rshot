# Shutter::Screenshot::GifRecorder

**File Path:** `share/shutter/resources/modules/Shutter/Screenshot/GifRecorder.pm`

## Description

Animated GIF recording engine for Shutter. This Moo class captures screen frames
at a configurable FPS using `Gtk3::Gdk::pixbuf_get_from_window`, saves them as
temporary PNGs, and assembles the final GIF via ImageMagick `convert`.

## Key Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `_common` | Object | (required) | Shared application context |
| `region` | HashRef | (required) | `{ x, y, w, h }` capture region |
| `fps` | Int | 10 | Frames per second |
| `duration` | Int | 0 | Max recording seconds (0 = manual stop) |
| `output` | Str | (required) | Output `.gif` file path |
| `on_done` | CodeRef | (required) | Callback invoked with output path on completion |

## Key Methods

- `start()` — Begins the `Glib::Timeout` frame capture loop.
- `stop()` — Cancels the timer and triggers `_assemble()`.
- `_grab_frame()` — Captures a pixbuf from the root window for the defined region.
- `_save_frame($pbuf, $n)` — Saves a numbered PNG frame to the temp directory.
- `_assemble()` — Invokes `convert -delay <delay> -loop 0 frame_*.png output.gif`.
- `get_mode()` — Returns `'gif_select'`.

## Related Modules

- `Shutter::App::Handlers::Screenshot_GifRecord` — UI handler that drives this engine.
- `Shutter::App::GlobalSettings` — Stores GIF settings (fps, duration, countdown).
- `Shutter::App::AfterCapturePipeline` — Post-capture pipeline (receives the finished GIF).
