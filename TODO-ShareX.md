# ShareX Modernization TODOs

This document tracks upcoming features to bring ShareX-like capabilities to Shutter.

## 1. The "After Capture" Task Pipeline
**Priority:** High | **Effort:** Medium | **Impact:** Massive
- [ ] Build a configurable queue of actions that execute sequentially after a screenshot is taken.
- [ ] Transition `CustomUploader.pm` from a singular "Upload" action to a step within a plugin-based task manager.
- [ ] Support workflows like: `[Save to disk] -> [Open in Editor] -> [Upload to Catbox] -> [Copy Link to Clipboard]`.
- [ ] Design choice needed: Keep UI in the Preferences dialog or add a dedicated "Workflow" configuration tab.

## 2. "Pin to Screen"
**Priority:** Medium | **Effort:** Low | **Impact:** High
- [ ] Create a simple overlay window that renders the image buffer, allowing a captured region to float on top of all other windows.
- [ ] Add a quick toggle or keyboard shortcut to activate "Pin to Screen" for the most recent capture.

## 3. File Naming Templates
**Priority:** Medium | **Effort:** Low | **Impact:** High
- [ ] Implement string formatter macros for file naming (e.g., `%y-%mo-%d_%h-%mi-%s` for date/time or `%pn` for project name).
- [ ] Apply formatting before saving the file to `~/Pictures/Shutter`.
- [ ] Note: Shutter currently supports `%Y-%m-%d` via `strftime`. Evaluate extending this to full macro templates.

## 4. Direct Clipboard/OCR Workflow
**Priority:** Low | **Effort:** High | **Impact:** Medium
- [ ] Integrate a lightweight OCR step that runs before or during the upload.
- [ ] Use a system-level tool like `tesseract` to extract recognized text from a region.
- [ ] Add option to copy recognized text directly to clipboard.

## 5. "After Upload" Actions
**Priority:** Medium | **Effort:** Medium | **Impact:** Medium
- [ ] Build a system for actions following a successful `.sxcu` upload.
- [ ] Implement URL shortener integration (e.g., TinyURL or Bitly).
- [ ] Implement QR Code generation for the returned link to display on screen.
