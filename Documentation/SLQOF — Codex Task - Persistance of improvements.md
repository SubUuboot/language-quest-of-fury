---
# 🧭 Super Language Quest of Fury  
## DevTools v2.2.2 — Input & Persistence Improvements  
**Branch:** `refacto-codex-devtools-task`  
**Base:** `refacto` (after Godot 4.5 `raise()` compatibility fix)



### 🎯 Summary
The current DevTools system (v2.2.1) works correctly after UI and cursor fixes, but three UX improvements are required to make the Input and Mechanics sections more complete:

1. Add a **checkbox to invert steering direction** (Q ↔ D swap).  
2. Add a **Save Settings** button to persist current parameters.  
3. Fix the **focus handling** when using the *Listen* button for input rebinding.

All modifications must remain compatible with the sandbox and existing InputBootstrap logic.


## 1️⃣ Invert Steering Direction Option

### 🔧 Objective
Allow toggling the tank’s steering direction to accommodate player preference (mechanically both directions make sense).

### 🧱 UI
- Add a `CheckButton` labeled **“Invert Steering Direction”** in the *Input* tab of DevTools, near the *Listen / Clear / Reset* buttons.

### 🧩 Logic
- Add a property to DevTools:
  ```gdscript
  var invert_steering: bool = false
  ```
- When toggled, update the tank or input system:
  ```gdscript
  if _tank:
      _tank.invert_steering = invert_steering
  ```
- If `TankController2D` doesn’t support inversion, Codex should handle it internally by flipping the mapping for `turn_left` / `turn_right`.

### 💾 Persistence
- Save and load `invert_steering` via the same config system as bindings or through a new `DevTools.save_settings()`.



## 2️⃣ Save Settings Button

### 🔧 Objective
Enable the user to persist mechanics and input modifications between sessions.

### 🧱 UI
- Add a new button labeled **“Save Settings”** next to the existing **“Reset Mechanics”** button.

### 🧩 Logic
- Implement `_on_save_settings_pressed()`:
  ```gdscript
  func _on_save_settings_pressed() -> void:
      var data := {
          "tank": _capture_tank_defaults(),
          "invert_steering": invert_steering
      }
      var file := FileAccess.open("user://devtools_settings.json", FileAccess.WRITE)
      if file:
          file.store_var(data)
          file.close()
          _mechanics_status.text = "Settings saved."
  ```
- At `_ready()`, if the file exists, read it back and reapply:
  ```gdscript
  if FileAccess.file_exists("user://devtools_settings.json"):
      var file := FileAccess.open("user://devtools_settings.json", FileAccess.READ)
      var data: Dictionary = file.get_var()
      file.close()
      # Apply saved parameters
  ```



## 3️⃣ Input Remapper Focus Fix

### ⚠️ Problem
When *Listen* is active and the user presses arrow keys, the UI navigation reacts instead of binding the key.

### ✅ Expected Behavior
When *Listen* is enabled, DevTools should temporarily **capture full keyboard focus** and ignore UI navigation until the binding is done or canceled.

### 🧩 Implementation
Update `_on_listen_button_pressed()`:
```gdscript
func _on_listen_button_pressed() -> void:
    if not _sandbox_enabled:
        _binding_status.text = "Sandbox disabled — cannot listen."
        return
    var action_name: String = _get_selected_action()
    if action_name == "":
        return
    _listening_action = action_name
    _binding_status.text = "Listening for new input..."
    get_viewport().gui_release_focus()
    grab_focus()
```

Then, at the end of `_unhandled_input(event)`:
```gdscript
release_focus()
get_viewport().gui_release_focus()
```

Optionally, disable `_tabs_container` and `_input_action_selector` while listening to avoid accidental menu navigation.


## ✅ Deliverables for Codex
- [ ] Add **Invert Steering Direction** checkbox linked to tank control inversion.  
- [ ] Add **Save Settings** button to persist sliders and remaps.  
- [ ] Fix *Listen* focus capture so it properly owns keyboard input until completion.  
- [ ] Maintain sandbox safety and production disable compatibility.



### 📁 File destination
`/Documentation/DevTools_Task_v2.2.2_Input_Persistence.md`
---
