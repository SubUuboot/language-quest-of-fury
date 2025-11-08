extends Control

const GAME_SCENE: PackedScene = preload("res://game.tscn")
const DEVTOOLS_SCENE: PackedScene = preload("res://Scenes/DevTools.tscn")
const TANK_CONTROLLER_SCRIPT: Script = preload("res://Scripts/TankController2D.gd")

var _status_label: Label
var _progress_bar: ProgressBar
var _start_timer: Timer

func _ready() -> void:
	print("🧠 GameBootstrap _ready() called — scheduling deferred init…")
	_status_label = get_node("Overlay/VBox/StatusLabel")
	_progress_bar = get_node("Overlay/VBox/ProgressBar")
	_start_timer = get_node("StartTimer")
	call_deferred("_deferred_ready")

func _deferred_ready() -> void:
	print("🚀 GameBootstrap _deferred_ready() started")
	print("  ⏱️ Nodes:", _status_label, _progress_bar, _start_timer)
	
	if _status_label == null:
		push_error("❌ StatusLabel introuvable — vérifie le nom exact dans la scène GameBootstrap.tscn")
		return
	if _progress_bar == null:
		push_error("❌ ProgressBar introuvable — vérifie le nom exact dans la scène GameBootstrap.tscn")
		return
	if _start_timer == null:
		push_error("❌ StartTimer introuvable — vérifie le nom exact dans la scène GameBootstrap.tscn")
		return

	_status_label.text = "Preparing systems..."
	_progress_bar.value = 0.1
	print("🧩 Boot overlay visible → timer started")
	_start_timer.start()
	await _start_timer.timeout
	await _run_bootstrap()

func _run_bootstrap() -> void:
	print("⚙️ Running bootstrap sequence…")
	await _ensure_input_bootstrap()
	await _prewarm_devtools()
	await _prewarm_stage_manager()
	await _prewarm_tank_controller()
	_update_status("Launching mission...", 1.0)
	await get_tree().process_frame
	print("✅ Switching to GAME_SCENE =", GAME_SCENE)
	get_tree().change_scene_to_packed(GAME_SCENE)

func _ensure_input_bootstrap() -> void:
	_update_status("Waiting for input bindings...", 0.25)
	var bootstrap: Node = null
	while bootstrap == null:
		bootstrap = get_tree().root.get_node_or_null("InputBootstrap")
		if bootstrap == null:
			await get_tree().process_frame
	if bootstrap.has_method("await_ready"):
		await bootstrap.await_ready()
	_update_status("Input system ready.", 0.35)

func _prewarm_devtools() -> void:
	_update_status("Priming DevTools...", 0.5)
	var devtools_stub: Node = DEVTOOLS_SCENE.instantiate()
	devtools_stub.free()
	await get_tree().process_frame

func _prewarm_stage_manager() -> void:
	_update_status("Priming StageManager...", 0.65)
	var stage_manager_script: Script = ResourceLoader.load("res://Scripts/systems/StageManager.gd") as Script
	if stage_manager_script:
		var stage_manager_stub: Node = stage_manager_script.new()
		stage_manager_stub.free()
	await get_tree().process_frame

func _prewarm_tank_controller() -> void:
	_update_status("Priming Tank systems...", 0.8)
	var tank_stub: Node = TANK_CONTROLLER_SCRIPT.new()
	tank_stub.free()
	await get_tree().process_frame

func _update_status(message: String, progress: float) -> void:
	print("📶", message)
	if _status_label:
		_status_label.text = message
	if _progress_bar:
		_progress_bar.value = clamp(progress, 0.0, 1.0)
