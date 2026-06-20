# Drawing Tool Refactoring Progress

This document tracks the decomposition of `Shutter::Draw::DrawingTool.pm`.

## 🛠 Status
- [x] Base Class (`Shutter::Draw::Tool::Base`)
- [x] Tool Registry
- [x] Canvas Manager
- [x] Pen Tool (Stub & Delegate)
- [x] Ellipse Tool (Stub & Delegate)
- [x] Rectangle Tool (Stub & Delegate)
- [x] Toolbar Manager Extraction
- [x] Logic Extraction (Iterative migration from `DrawingTool.pm` to Tool Classes)

## 📋 Pending Tasks
1.  **Refactor `DrawingTool.pm`** to expose internal state (canvas, item storage) to the new tool classes.
2.  **Iteratively Migrate** drawing logic from `DrawingTool.pm` into tool-specific classes (`Pen`, `Ellipse`, `Rectangle`).
3.  **Implement `ToolbarManager`** to centralize UI creation and event wiring.
4.  **Verification & Cleanup:** Once logic is fully extracted, remove the delegated methods from `DrawingTool.pm`.
