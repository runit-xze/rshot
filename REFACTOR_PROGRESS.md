# Refactor Progress Dashboard: Phase 4

This document tracks the second wave of modularization, focusing on decomposing large subsystem modules and modernizing legacy components.

## Subsystem Refactoring Summary

| Module | Purpose | Current LOC | Refactor Status | Target |
|--------|---------|-------------|-----------------|--------|
| `Shutter::Draw::DrawingTool` | Drawing Editor | 499 | 🟢 Completed | Break into Tool/UI classes |
| `Shutter::Screenshot::SelectorAdvanced` | Advanced Region Selection | 626 | 🟡 Initial Assessment | Port to Cairo overlays |
| `Shutter::Screenshot::Main` | Main Capture Logic | 495 | 🟡 In Progress | Modernize via `ScreenshotHandler` |

## Completed Items (FTP removed - deprecated)

## Active Task: Drawing Tool Decomposition
*Goal: Reduce DrawingTool.pm to <500 lines of UI glue code.*

### Extracted Modules (ready for integration)
- [x] `Shutter::Draw::UndoManager` - Stack management and UI updates
- [x] `Shutter::Draw::CanvasOverlays` - Resize handles and embedded items

### Tool Structure (ready for implementation)
- [x] `Shutter::Draw::Tool::Registry` - Moo registry for tool lookup
- [x] `Shutter::Draw::Tool::Base` - Moo role defining tool interface
- [x] `Shutter::Draw::Tool::Pen` (calls `Shutter::Draw::Polyline->setup`)
- [x] `Shutter::Draw::Tool::Ellipse` (calls `Shutter::Draw::Ellipse->setup`)
- [x] `Shutter::Draw::Tool::Rectangle` (calls `Shutter::Draw::Rectangle->setup`)
- [x] `Shutter::Draw::Tool::Blur` (calls `Shutter::Draw::Blur->setup`)
- [x] `Shutter::Draw::Tool::Censor` (calls `Shutter::Draw::Censor->setup`)
- [x] `Shutter::Draw::Tool::Highlighter` (calls `Shutter::Draw::Polyline->setup`)
- [x] `Shutter::Draw::Tool::Arrow` (calls `Shutter::Draw::Arrow->setup`)
- [x] `Shutter::Draw::Tool::Text` (calls `Shutter::Draw::Text->setup`)

### Manager Classes
- [x] `Shutter::Draw::CanvasManager` - Delegates to active tool
- [x] `Shutter::Draw::ToolbarManager` - UI widget setup and tool switching

### Next Steps
- [x] Integrate `UndoManager` into DrawingTool (delegates stack management/UI updates)
- [x] Integrate `CanvasOverlays` into DrawingTool (replace handle_* methods)
- [ ] Implement SelectorAdvanced zoom window with direct Cairo drawing (remove GooCanvas2 dependency)
