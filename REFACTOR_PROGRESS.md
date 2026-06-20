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

- [x] Extract `DrawingTool::Pen`
- [x] Extract `DrawingTool::Ellipse`
- [x] Extract `DrawingTool::Rectangle`
- [x] Extract `DrawingTool::Blur`
- [x] Extract `DrawingTool::Censor`
- [x] Extract `DrawingTool::Highlighter`
- [x] Extract `DrawingTool::Arrow`
- [x] Extract `DrawingTool::Text`
- [x] Implement `DrawingTool::CanvasManager` (Moo)
- [x] Implement `DrawingTool::ToolbarManager` (Moo)
