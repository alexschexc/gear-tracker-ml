# GearTracker-ML GUI Migration Plan
## GTK3 (lablgtk3) → Dear ImGui (imguiml)

**Date:** February 13, 2026  
**Status:** Planning Phase  
**Priority:** High - Before Beta Features  
**Approach:** Direct replacement with compile-time backend selection

---

## Executive Summary

This document outlines the comprehensive migration of the GearTracker-ML GUI from GTK3 (lablgtk3) to Dear ImGui using the `imguiml` OCaml bindings. This migration is critical for achieving true cross-platform single-binary distribution, particularly for macOS and Windows where GTK3 dependencies are problematic.

### Key Benefits

| Aspect | Current (GTK3) | Target (Dear ImGui) |
|--------|---------------|---------------------|
| **macOS Support** | Requires Homebrew, X11 issues | Native OpenGL, no deps |
| **Windows Support** | Complex DLL management | Static linkable |
| **Binary Size** | ~9.5MB + external deps | Smaller, self-contained |
| **Distribution** | Folder with libs | Single executable |
| **Cross-compile** | Difficult | Straightforward |
| **Look & Feel** | Native desktop | Modern tool aesthetic |

---

## Architecture Overview

### Compile-Time Backend Selection

The application will support both backends via dune profiles:

```bash
# GTK3 backend (legacy)
dune build --profile gtk3

# Dear ImGui backend (default)
dune build --profile release

# Static Dear ImGui
dune build --profile static
```

### Directory Structure

```
gearTracker-ml/
├── bin/
│   ├── main.ml              # CLI entry (unchanged)
│   ├── cli.ml               # CLI interface (unchanged)
│   ├── gui_gtk3.ml          # GTK3 GUI (current gui.ml)
│   ├── gui_imgui.ml         # NEW: Dear ImGui GUI
│   └── gui.ml               # NEW: Backend selector
├── lib/
│   ├── imgui_backend.ml     # NEW: OpenGL/Glfw initialization
│   ├── ui_widgets.ml        # NEW: High-level ImGui widgets
│   ├── ui_theme.ml          # NEW: Dark theme configuration
│   └── ...                  # (existing modules unchanged)
├── vendor/
│   └── imgui-filebrowser/   # NEW: ImGui-based file browser
└── dune-workspace           # MODIFIED: Multi-context profiles
```

---

## Technical Specifications

### Dependencies

**Remove:**
- `lablgtk3` (GTK3 OCaml bindings)

**Add:**
- `imguiml` (Dear ImGui OCaml bindings) - v1.90.6+
- `conf-glfw3` (Window management)
- `conf-glew` (OpenGL Extension Wrangler)
- `ctypes` + `ctypes-foreign` (C FFI)
- `nfd` or custom file browser (file dialogs)

**Optional:**
- `implot` (plotting library for charts)

### Software Rendering Configuration

For headless/VM environments:

```bash
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
export LIBGL_ALWAYS_SOFTWARE=1  # Force Mesa llvmpipe
```

---

## Implementation Phases

### Phase 1: Infrastructure (Foundation)

**Duration:** 3-4 days  
**Goal:** Setup Dear ImGui backend and build system

#### Tasks:

1. **Update `dune-project`**
   - Remove `lablgtk3` from dependencies
   - Add `imguiml`, `conf-glfw3`, `conf-glew`, `ctypes`

2. **Create `lib/imgui_backend.ml`**
   ```ocaml
   module type BACKEND = sig
     val init : width:int -> height:int -> title:string -> unit
     val shutdown : unit -> unit
     val new_frame : unit -> unit
     val render : unit -> unit
     val should_close : unit -> bool
     val poll_events : unit -> unit
     val get_framebuffer_size : unit -> int * int
   end
   
   module Glfw_backend : BACKEND = struct
     (* GLFW + OpenGL3 implementation *)
   end
   ```

3. **Update `dune-workspace`**
   ```ocaml
   (context default)  ; Default context uses ImGui
   
   (context
    (default
     (name gtk3)
     (profile gtk3)
     (toolchain default)
     (env
      (HAVE_GTK3 true))))
   ```

4. **Create `lib/ui_theme.ml`**
   - Dark theme matching Python GearTracker
   - Colors: WindowBg #353535, Text #FFFFFF, etc.
   - Font configuration

5. **Test infrastructure**
   - Verify `dune build --profile release` works
   - Verify `dune build --profile gtk3` still works

**Deliverables:**
- [ ] Build system supports both backends
- [ ] `imgui_backend.ml` compiles
- [ ] Theme system in place

---

### Phase 2: Widget Library (Reusable Components)

**Duration:** 4-5 days  
**Goal:** Create ImGui equivalents of GTK3 widgets

#### Tasks:

1. **Create `lib/ui_widgets.ml`**

   **Data Display:**
   ```ocaml
   val table_header : string list -> unit
   val table_row : string list -> unit
   val selectable_row : string list -> bool -> bool
   ```

   **Form Inputs:**
   ```ocaml
   val input_text : label:string -> value:string ref -> max_length:int -> unit
   val input_int : label:string -> value:int ref -> unit
   val input_float : label:string -> value:float ref -> format:string -> unit
   val combo : label:string -> items:string list -> selected_idx:int ref -> unit
   val checkbox : label:string -> checked:bool ref -> unit
   val date_picker : label:string -> timestamp:Timestamp.t ref -> unit
   ```

   **Layout:**
   ```ocaml
   val begin_window : title:string -> unit
   val end_window : unit -> unit
   val begin_child : id:string -> size:(float * float) -> unit
   val end_child : unit -> unit
   val separator : unit -> unit
   val spacing : unit -> unit
   ```

   **Dialogs:**
   ```ocaml
   val begin_modal : title:string -> unit
   val end_modal : unit -> unit
   val open_modal : title:string -> unit
   ```

2. **Create `vendor/imgui-filebrowser/`**
   - ImGui-based file browser (no native dialogs)
   - Support for:
     - Directory navigation
     - File filtering (*.csv, *.db)
     - New folder creation
     - File preview

3. **Test widgets**
   - Create `test/test_widgets.ml`
   - Visual test of all widgets

**Deliverables:**
- [ ] All GTK3 widgets have ImGui equivalents
- [ ] File browser working
- [ ] Widget test suite passing

---

### Phase 3: Theme System & Styling

**Duration:** 2-3 days  
**Goal:** Match Python GearTracker dark theme

#### Tasks:

1. **Create `lib/ui_theme.ml`**
   ```ocaml
   let setup_dark_theme () =
     let style = ImGui.get_style () in
     (* Colors matching Python PyQt6 theme *)
     (* WindowBg: 53, 53, 53 *)
     (* ChildBg: 35, 35, 35 *)
     (* Text: 255, 255, 255 *)
     (* Button: 53, 53, 53 *)
     (* ButtonHovered: 70, 70, 70 *)
     (* ButtonActive: 90, 90, 90 *)
     (* FrameBg: 35, 35, 35 *)
     (* Highlight: 42, 130, 218 *)
   ```

2. **Font configuration**
   - Load system fonts or bundle Roboto
   - Configure sizes for headers/body/text

3. **Style consistency**
   - Rounding on buttons/inputs
   - Padding and spacing
   - Scrollbar styling

**Deliverables:**
- [ ] Dark theme matches Python version
- [ ] All UI elements styled consistently
- [ ] Font rendering crisp

---

### Phase 4: Tab Conversion (10 Tabs)

**Duration:** 10-12 days  
**Goal:** Convert all 10 tabs to ImGui

#### Conversion Pattern:

**GTK3 Pattern:**
```ocaml
let create_firearms_tab () =
  let vbox = GPack.vbox () in
  let btn = GButton.button ~label:"Add" () in
  btn#connect#clicked ~callback:(fun () -> ...);
  vbox#pack btn#coerce;
  (* ... widgets ... *)
  (vbox, btn, refresh)
```

**ImGui Pattern:**
```ocaml
let render_firearms_tab ~state () =
  Ui_widgets.begin_child "FirearmsList" ~size:(-1.0, -50.0);
  render_table state;
  Ui_widgets.end_child ();
  
  ImGui.separator ();
  if ImGui.button "Add Firearm" then (
    state.show_add_dialog <- true
  );
  ImGui.same_line ();
  if ImGui.button "Edit" then (
    (* handle edit *)
  );
  
  (* Dialogs *)
  if state.show_add_dialog then (
    render_add_dialog state
  )
```

#### Tab Migration Order:

1. **Firearms Tab** (Day 1-2)
   - Table with columns: Name, Caliber, Serial, Status, Rounds
   - Action buttons: Add, Edit, Delete, Log Maintenance, Transfer
   - Search/filter box

2. **Gear Tab** (Day 2-3)
   - Similar to Firearms
   - Category filtering

3. **Consumables Tab** (Day 3-4)
   - Quantity display with color coding
   - Stock add/use buttons
   - Transaction history

4. **Reloading Tab** (Day 4-5)
   - Batch details table
   - Status indicators (WORKUP/READY/DEPLETED)

5. **Loadouts Tab** (Day 5-6)
   - Loadout list
   - Item management
   - Checkout/return workflow

6. **Checkouts Tab** (Day 6-7)
   - Active checkouts
   - Return functionality
   - History view

7. **Borrowers Tab** (Day 7-8)
   - Borrower list
   - Active checkouts per borrower

8. **NFA Items Tab** (Day 8-9)
   - Similar to Firearms
   - NFA-specific fields

9. **Transfers Tab** (Day 9-10)
   - Transfer records
   - Buyer information

10. **Import/Export Tab** (Day 10-12)
    - Checkboxes for entity selection
    - File browser dialog
    - Progress indicators
    - Results display

**Deliverables:**
- [ ] All 10 tabs converted
- [ ] Feature parity with GTK3 version
- [ ] Keyboard navigation working

---

### Phase 5: Dialog Conversion

**Duration:** 5-6 days  
**Goal:** Convert all modal dialogs

#### Dialogs to Convert:

**CRUD Dialogs:**
1. Add Firearm
2. Edit Firearm
3. Add Gear
4. Add Consumable
5. Add Reload Batch
6. Add Loadout
7. Add Borrower
8. Add NFA Item
9. Record Transfer
10. Log Maintenance (all types)

**Confirmation Dialogs:**
11. Delete confirmations
12. Overwrite confirmations (import)

**Special Dialogs:**
13. File browser (import/export)
14. Progress dialogs (long operations)
15. Error message dialogs

**ImGui Pattern:**
```ocaml
let render_add_firearm_dialog ~state () =
  if state.show_add_dialog then (
    ImGui.open_popup "Add Firearm";
    state.show_add_dialog <- false
  );
  
  if ImGui.begin_popup_modal "Add Firearm" ~flags:0 () then (
    Ui_widgets.input_text ~label:"Name" ~value:state.name ~max_length:255;
    Ui_widgets.input_text ~label:"Caliber" ~value:state.caliber ~max_length:50;
    (* ... more fields ... *)
    
    ImGui.separator ();
    if ImGui.button "Save" then (
      (* validate and save *)
      ImGui.close_current_popup ()
    );
    ImGui.same_line ();
    if ImGui.button "Cancel" then (
      ImGui.close_current_popup ()
    );
    
    ImGui.end_popup ()
  )
```

**Deliverables:**
- [ ] All dialogs converted
- [ ] Form validation working
- [ ] Keyboard shortcuts (Tab, Enter, Escape)

---

### Phase 6: Integration & State Management

**Duration:** 4-5 days  
**Goal:** Connect all pieces, manage application state

#### Tasks:

1. **Create `bin/gui_imgui.ml`**
   - Main window setup
   - Menu bar (File, View, Help)
   - Tab bar
   - Render loop

2. **State management**
   ```ocaml
   type app_state = {
     (* Current tab *)
     mutable current_tab : tab;
     
     (* Firearms tab state *)
     mutable firearms_list : Firearm.t list;
     mutable selected_firearm : Firearm.t option;
     mutable search_filter : string;
     mutable show_add_firearm : bool;
     
     (* ... similar for other tabs ... *)
     
     (* Global *)
     mutable show_about : bool;
     mutable show_settings : bool;
   }
   ```

3. **Event loop**
   ```ocaml
   let run () =
     Imgui_backend.Glfw_backend.init ~width:1280 ~height:720 ~title:"GearTracker";
     Ui_theme.setup_dark_theme ();
     
     let state = init_state () in
     
     while not (Imgui_backend.Glfw_backend.should_close ()) do
       Imgui_backend.Glfw_backend.poll_events ();
       Imgui_backend.Glfw_backend.new_frame ();
       
       render_menu_bar state;
       render_tab_bar state;
       render_current_tab state;
       render_modals state;
       
       Imgui_backend.Glfw_backend.render ()
     done;
     
     Imgui_backend.Glfw_backend.shutdown ()
   ```

4. **Backend selection**
   ```ocaml
   (* bin/gui.ml *)
   #ifdef HAVE_GTK3
     include Gui_gtk3
   #else
     include Gui_imgui
   #endif
   ```

**Deliverables:**
- [ ] Full application runs with ImGui
- [ ] All tabs accessible
- [ ] State persists correctly
- [ ] No memory leaks

---

### Phase 7: Cross-Platform Build System

**Duration:** 3-4 days  
**Goal:** Update CI/CD for ImGui builds

#### Tasks:

1. **Update Linux workflow**
   ```yaml
   # Remove: libgtk-3-dev
   # Add: libglfw3-dev, libglew-dev
   # Build: dune build --profile release
   # Output: gearTracker-ml-gui (static binary)
   ```

2. **Update macOS workflow**
   ```yaml
   # Remove: brew install gtk+3
   # Add: brew install glfw glew
   # Build: dune build --profile release
   # Create: GearTracker.app bundle with embedded libs
   ```

3. **Update Windows workflow**
   ```yaml
   # Remove: mingw GTK dependencies
   # Add: mingw GLFW/GLEW
   # Build: dune build --profile release (cross-compile)
   # Output: Single .exe with static linking
   ```

4. **Static linking configuration**
   - Musl libc for Linux
   - Static OpenGL (Mesa)
   - Bundle fonts

5. **Test builds**
   - Linux x86_64 AppImage
   - macOS .app + DMG
   - Windows .exe + installer

**Deliverables:**
- [ ] All three platforms building
- [ ] Single-binary distribution
- [ ] No external dependencies

---

### Phase 8: Testing & Polish

**Duration:** 3-4 days  
**Goal:** Ensure quality and parity

#### Tasks:

1. **Functional testing**
   - All CRUD operations
   - Import/export roundtrip
   - All maintenance log types
   - Checkout/return workflow

2. **UI/UX testing**
   - Responsive layout at different sizes
   - Keyboard navigation
   - Tab order
   - Font scaling

3. **Performance testing**
   - Large dataset handling (1000+ firearms)
   - Memory usage
   - Frame rate (should be 60fps)

4. **Cross-platform testing**
   - Linux (primary dev)
   - macOS (VM or CI)
   - Windows (VM or CI)

5. **Documentation**
   - Update README with new build instructions
   - Update examples
   - API docs (odoc)

**Deliverables:**
- [ ] All tests passing
- [ ] Performance acceptable
- [ ] Documentation updated

---

## Timeline Summary

| Phase | Duration | Cumulative |
|-------|----------|------------|
| 1. Infrastructure | 3-4 days | Day 4 |
| 2. Widget Library | 4-5 days | Day 9 |
| 3. Theme System | 2-3 days | Day 12 |
| 4. Tab Conversion | 10-12 days | Day 24 |
| 5. Dialog Conversion | 5-6 days | Day 30 |
| 6. Integration | 4-5 days | Day 35 |
| 7. Cross-Platform | 3-4 days | Day 39 |
| 8. Testing | 3-4 days | Day 43 |

**Total Estimated Duration:** 6-7 weeks

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| imguiml build issues | Medium | High | Use Docker for builds; contribute fixes upstream |
| Software rendering performance | Low | Medium | Optimize draw calls; cache where possible |
| macOS notarization | Medium | Medium | Document manual override; consider unsigned for now |
| File browser UX | Low | Medium | Extensive testing; iterate on design |
| Font rendering issues | Low | Medium | Bundle tested fonts; fallback to system fonts |

---

## Success Criteria

1. ✅ **Feature Parity:** All GTK3 features work in ImGui version
2. ✅ **Single Binary:** No external dependencies on any platform
3. ✅ **Performance:** 60fps UI, <100MB RAM for large datasets
4. ✅ **Cross-Platform:** Builds and runs on Linux, macOS, Windows
5. ✅ **Compile-Time Selection:** Both backends available via build flags
6. ✅ **Tests Pass:** All existing tests pass; new widget tests added
7. ✅ **Documentation:** README, examples, and API docs updated

---

## Next Steps

1. Review and approve this plan
2. Create feature branch `feature/imgui-migration`
3. Begin Phase 1: Infrastructure
4. Weekly progress reviews

---

## Appendix: Code Examples

### Example: Backend Selection in Dune

```ocaml
(* bin/dune *)
(executable
 (public_name gearTracker-ml-gui)
 (name gui)
 (libraries 
  (select gui_backend from
   (imguiml -> gui_imgui.ml)
   (lablgtk3 -> gui_gtk3.ml))
  gearTracker_ml))
```

### Example: Conditional Compilation

```ocaml
(* bin/gui.ml *)
module Backend = struct
  #ifdef IMGUI_BACKEND
    include Gui_imgui
  #else
    include Gui_gtk3
  #endif
end

let main = Backend.run
```

### Example: File Browser Usage

```ocaml
(* In import/export tab *)
if ImGui.button "Export to CSV..." then (
  Filebrowser.open_dialog 
    ~title:"Export Data"
    ~filters:["CSV files", "*.csv"]
    ~on_select:(fun path ->
      (* perform export *)
    )
)
```

---

**Document Version:** 1.0  
**Last Updated:** February 13, 2026  
**Author:** Claude Code (via opencode)  
**Review Status:** Pending
