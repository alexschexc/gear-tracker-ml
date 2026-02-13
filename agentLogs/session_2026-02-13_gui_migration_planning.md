# Session Log: GUI Migration Planning

**Date:** February 13, 2026  
**Project:** GearTracker-ML OCaml Port  
**Session Type:** Planning - GUI Migration Strategy  
**Status:** Complete - Ready for Implementation

---

## Summary

This session focused on planning the migration of the GearTracker-ML GUI from **GTK3 (lablgtk3)** to **Dear ImGui** using the `imguiml` OCaml bindings. This is a critical step before implementing the Beta features, as it will enable true cross-platform single-binary distribution.

## Key Decisions Made

### 1. Backend Selection Strategy
- **Compile-time option**, not runtime
- Two dune profiles: `release` (ImGui) and `gtk3` (legacy GTK)
- Direct replacement approach (not a separate branch)

### 2. GUI Library Choice
- **Selected:** Dear ImGui (`imguiml` bindings)
- **Reason:** Better cross-platform support, static linking, smaller binaries
- **Alternative considered:** Keeping GTK3 (rejected due to macOS/Windows issues)

### 3. File Browser
- **Decision:** ImGui-based (not native OS dialogs)
- **Implementation:** Custom file browser widget
- **Benefit:** Consistent UI across all platforms

### 4. Priority
- GUI migration happens **before** Beta features
- Rationale: Beta features should be built on the new foundation

## Migration Plan Overview

### 8 Implementation Phases:
1. **Infrastructure** (3-4 days) - Dependencies, backend module
2. **Widget Library** (4-5 days) - Reusable ImGui components
3. **Theme System** (2-3 days) - Dark theme matching Python version
4. **Tab Conversion** (10-12 days) - Convert all 10 tabs
5. **Dialog Conversion** (5-6 days) - All modal dialogs
6. **Integration** (4-5 days) - State management, main loop
7. **Cross-Platform Builds** (3-4 days) - CI/CD updates
8. **Testing & Polish** (3-4 days) - QA, documentation

**Total Estimated Duration:** 6-7 weeks

## Technical Architecture

### New Dependencies
- `imguiml` - Dear ImGui bindings
- `conf-glfw3` - Window management
- `conf-glew` - OpenGL extensions
- `ctypes` + `ctypes-foreign` - FFI

### Removed Dependencies
- `lablgtk3` - GTK3 bindings

### File Structure Changes
```
bin/
  gui_gtk3.ml       (renamed from current gui.ml)
  gui_imgui.ml      (NEW)
  gui.ml            (NEW - backend selector)
lib/
  imgui_backend.ml  (NEW)
  ui_widgets.ml     (NEW)
  ui_theme.ml       (NEW)
vendor/
  imgui-filebrowser/ (NEW)
```

## Code Pattern Changes

### GTK3 (Retained Mode)
```ocaml
let btn = GButton.button ~label:"Click" () in
btn#connect#clicked ~callback:(fun () -> ...);
vbox#pack btn#coerce;
```

### Dear ImGui (Immediate Mode)
```ocaml
(* In render loop, every frame *)
if ImGui.button "Click" then (
  (* Handle click immediately *)
);
```

## Success Criteria

1. ✅ Feature parity with GTK3 version
2. ✅ Single binary distribution (no deps)
3. ✅ 60fps UI performance
4. ✅ Builds on Linux, macOS, Windows
5. ✅ Compile-time backend selection
6. ✅ All tests passing
7. ✅ Documentation updated

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| imguiml build issues | Medium | Docker builds, contribute upstream |
| Software rendering perf | Low | Optimize draw calls, caching |
| macOS notarization | Medium | Document manual install |
| File browser UX | Low | Extensive testing, iterate |

## Next Steps

1. ✅ **This Session:** Planning complete
2. **Next Session:** Begin Phase 1 (Infrastructure)
   - Update dune-project
   - Install imguiml
   - Create imgui_backend.ml
   - Setup build profiles
3. **Future Sessions:** Phases 2-8

## References

- **Full Plan Document:** `agentLogs/GUI_MIGRATION_PLAN_2026-02-13.md`
- **Current Codebase:** GTK3 GUI in `bin/gui.ml`
- **Target Library:** [imguiml](https://opam.ocaml.org/packages/imguiml/)
- **Backend:** GLFW3 + OpenGL3

## Notes

- Software rendering via Mesa llvmpipe for headless/VM environments
- Theme will match Python GearTracker PyQt6 dark theme
- Will preserve GTK3 backend via `--profile gtk3` for compatibility
- All 10 tabs need conversion: Firearms, Gear, Consumables, Reloading, Loadouts, Checkouts, Borrowers, NFA Items, Transfers, Import/Export

---

**Session Complete:** Plan documented and ready for implementation approval.

**Prepared by:** Claude Code (via opencode)  
**Review Status:** Pending User Approval
