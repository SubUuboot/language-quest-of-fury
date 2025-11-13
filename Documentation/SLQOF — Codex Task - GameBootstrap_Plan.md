
# Request for Codex

Please read this document and design a unified startup sequence for Super Language Quest Of Fury, including scene order, signal management, and input synchronization. Focus on creating a GameBootstrap scene as described.

# Game Bootstrap & Initialization Refactor Plan

## 🎯 Objective
Establish a clean and reliable startup sequence for **Super Language Quest Of Fury**, ensuring that all autoloaded systems (InputBootstrap, DevTools, MotherAI, StageManager, etc.) are fully initialized before gameplay begins.

The main scene should **only start once all systems are ready**, preventing timing-related bugs such as missing input bindings or incomplete signal connections.

## 🧩 Current Symptoms

1. **InputBootstrap initialization race condition**
   - The autoload `InputBootstrap` sometimes initializes *after* `MainScene` and `TankController2D`.
   - As a result, the first frame of gameplay starts without working clutch/gear controls.
   - This is visible because the `gear_up`, `gear_down`, and `clutch` inputs are not yet registered.

2. **DevTools timing mismatch**
   - The F1 toggle and `devtools_toggled` signal work correctly now, but only after the scene has been running for a few frames.
   - The scene currently contains only `LogConsole` and `MetricsOverlay` visible by default; the `DebugMenu` panel remains hidden.

3. **Duplicate initialization**
   - `MotherAI` and `StageManager` sometimes register the same scene multiple times (`Scene registered: Hangar` appears twice in logs).

4. **TankController2D input desync**
   - The tank starts “alive” but partially unresponsive.
   - The engine (spacebar → RPM) works, but clutch and gear changes do not.
   - When DevTools opens, inputs lock/unlock correctly — so the signal logic is fine, but the timing is not.


## ⚙️ Root Cause Hypothesis

- The game loads directly into `MainScene.tscn`, which includes all systems at once (HUDLayer, DevTools, Tank, Commander, etc.).
- The autoloads (`InputBootstrap`, `StageManager`, `MotherAI`) initialize asynchronously during this process.
- The tank and DevTools rely on InputMap actions and signals that may not yet exist.
- Therefore, the first few frames run in an inconsistent state.


## 🧠 Proposed Solution

Introduce a **Game Bootstrap Scene** (`MainMenu.tscn` or `GameBootstrap.tscn`) that:
1. Loads **before** `MainScene`.
2. Waits for all autoloads and managers to finish initialization.
3. Optionally shows a **main menu or splash screen** with “Press any key” or a simple loading animation.
4. Once everything is ready, it **transitions to `MainScene`** using `get_tree().change_scene_to_file()`.


## 🧩 Required Changes

### 1. New Scene: `Scenes/GameBootstrap.tscn`

**Node structure proposal:**

GameBootstrap (Control)
├── Logo (TextureRect)
├── LoadingLabel (Label)
├── ProgressBar (ProgressBar)
└── Timer (Timer)


**Script: `GameBootstrap.gd`**
```gdscript
extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var loading_label: Label = $LoadingLabel

var systems_ready := false

func _ready() -> void:
	print("🚀 [Bootstrap] Initializing game systems...")
	set_process(true)
	loading_label.text = "Initializing systems..."
	progress_bar.value = 0

func _process(delta: float) -> void:
	if _check_systems_ready():
		progress_bar.value = 100
		loading_label.text = "All systems ready!"
		print("✅ [Bootstrap] Launching MainScene...")
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

func _check_systems_ready() -> bool:
	# Wait for InputBootstrap, StageManager, MotherAI, etc.
	var all_ready := true

	if not Engine.has_singleton("InputBootstrap"):
		all_ready = false
	if not has_node("/root/MotherAI"):
		all_ready = false
	if not has_node("/root/StageManager"):
		all_ready = false

	return all_ready

2. Autoload Adjustments

Ensure that the following autoloads are declared in project.godot and initialized before gameplay:

    InputBootstrap.gd

    StageManager.gd

    MotherAI.gd

3. DevTools Integration

    Confirm that DevTools.tscn is not visible by default.

    On F1, ensure it’s toggled by its own _unhandled_input() logic (already functional).

    Add a hook in GameBootstrap or MainScene to preload DevTools if not already present.

4. TankController2D Safety Guard

Inside TankController2D._ready(), add:

await get_tree().process_frame  # Wait one frame for InputBootstrap to finish
if not InputMap.has_action("gear_up"):
	print("⚠️ [Tank] InputBootstrap not ready — waiting...")
	await get_tree().create_timer(0.5).timeout

This ensures that input bindings exist even on slow initializations.
✅ Deliverables for Codex

    Validate the feasibility of the GameBootstrap scene and its placement before MainScene.

    Suggest any necessary diffs to:

        TankController2D.gd

        InputBootstrap.gd

        DevTools.gd

    Verify that autoload dependencies are respected and signal connections remain stable.

    Propose a transition flow (fade-in/out or “Press any key to start” option) for polish.

📦 Expected Result

    The game boots into a loading or menu scene (no Tank yet).

    All autoloads are confirmed ready (no missing InputMap entries).

    On continue, MainScene loads cleanly.

    F1 toggle and tank input work immediately, without any race condition.
