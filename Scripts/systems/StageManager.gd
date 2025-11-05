extends Node

## ────────────────────────────────
## CONFIGURATION
## ────────────────────────────────

@export var stages_path := "res://Scenes/Stages/"

const STAGE_FILES := {
	"Stage0": "Stage0_Hangar.tscn",
	"Stage1": "Stage1_TrainingGround.tscn",
}

var current_stage: Node = null
var current_stage_name: String = ""

signal stage_loaded(stage_name)
signal stage_unloaded(stage_name)
signal stage_completed(stage_name)

## ────────────────────────────────
## CHARGEMENT / DÉCHARGEMENT
## ────────────────────────────────

func start_stage(stage_name: String):
	if current_stage:
		unload_stage()

	var stage_file = STAGE_FILES.get(stage_name, stage_name + ".tscn")
	var stage_scene_path = stages_path.path_join(stage_file)

	if not ResourceLoader.exists(stage_scene_path):
		push_error("StageManager: Stage not found at " + stage_scene_path)
		return

	var packed_stage = load(stage_scene_path)
	if packed_stage == null:
		push_error("StageManager: Failed to load " + stage_scene_path)
		return

	current_stage = packed_stage.instantiate()
	current_stage_name = stage_name
	add_child(current_stage)

	_connect_stage_signals(current_stage)

	emit_signal("stage_loaded", stage_name)
	print("[StageManager] Loaded stage:", stage_name)

func unload_stage():
	if current_stage:
		emit_signal("stage_unloaded", current_stage_name)
		current_stage.queue_free()
		current_stage = null
		current_stage_name = ""

func restart_stage():
	if current_stage_name != "":
		start_stage(current_stage_name)

## ────────────────────────────────
## SIGNATURES / COMMUNICATION
## ────────────────────────────────

func _connect_stage_signals(stage: Node):
	if stage.has_signal("stage_complete"):
		stage.connect("stage_complete", Callable(self, "_on_stage_complete"))

func _on_stage_complete():
	print("[StageManager] Stage completed:", current_stage_name)
	emit_signal("stage_completed", current_stage_name)
