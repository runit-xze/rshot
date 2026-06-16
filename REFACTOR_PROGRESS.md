# Refactor Progress Dashboard: Phase 4

This document tracks the second wave of modularization, focusing on decomposing large subsystem modules and modernizing legacy components.

## Subsystem Refactoring Summary

| Module | Purpose | Current LOC | Refactor Status | Target |
|--------|---------|-------------|-----------------|--------|
| `Shutter::Draw::DrawingTool` | Drawing Editor | 7,305 | 🔴 Planning | Break into Tool/UI classes |
| `Shutter::Screenshot::SelectorAdvanced` | Advanced Region Selection | 2,150 | 🟡 Initial Assessment | Port to Cairo overlays |
| `Shutter::Screenshot::Main` | Main Capture Logic | 1,200 | 🟡 In Progress | Modernize via `ScreenshotHandler` |
| `Shutter::Upload::FTP` | Legacy Uploader | 450 | ⚪ Pending | Standardize on `UploadManager` |

## Recent Progress

### ✅ Completed: Monolith Elimination (Phase 1-3)
- **Source:** `bin/shutter.monolith`
- **Total Subs:** 165
- **Migrated:** 165
- **Status:** **COMPLETE**. Monolith file removed.

## Active Task: Drawing Tool Decomposition
*Goal: Reduce DrawingTool.pm to <500 lines of UI glue code.*

- [ ] Extract `DrawingTool::Pen`
- [ ] Extract `DrawingTool::Ellipse`
- [ ] Extract `DrawingTool::Rectangle`
- [ ] Extract `DrawingTool::Blur`
- [ ] Extract `DrawingTool::Censor`
- [ ] Extract `DrawingTool::Highlighter`
- [ ] Extract `DrawingTool::Arrow`
- [ ] Extract `DrawingTool::Text`
- [ ] Implement `DrawingTool::CanvasManager` (Moo)
- [ ] Implement `DrawingTool::ToolbarManager` (Moo)
