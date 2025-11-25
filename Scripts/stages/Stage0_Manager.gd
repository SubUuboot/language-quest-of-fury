extends Node

signal bench_conditions_met

@onready var bench_trigger: Area2D = %BenchTrigger
@onready var door_trigger: Area2D = %DoorTrigger
@onready var bench: StaticBody2D = $"../../Environment/Bench"
@onready var input_assignment_scene: Node = $"../InputAssignmentScene"

var tank: Node
var rusty: Node
var stage_manager: Node

var sequence_active := false


func _ready():

	# Récupération propre du StageManager (autoload)
	stage_manager = StageManager

	# Récupération du tank + rusty dans Main
	var chars = get_node("/root/Game/Main/Characters")
	tank = chars.get_node("Tank")
	rusty = chars.get_node("Rusty")

	# On connecte les triggers
	if bench_trigger:
		bench_trigger.body_entered.connect(_on_bench_trigger_entered)

	if door_trigger:
		door_trigger.body_entered.connect(_on_door_trigger_entered)

	# Désactiver l'input assignment au démarrage
	_disable_input_assignment()


# -----------------------------
# BENCH TRIGGER
# -----------------------------

func _on_bench_trigger_entered(body: Node):
	if sequence_active:
		return

	if not body.is_in_group("tank"):
		return

	if not _is_rusty_inside_tank():
		return

	if not _is_tank_on_bench():
		return

	_start_input_assignment()


func _is_rusty_inside_tank() -> bool:
	return rusty.get("is_embarked") == true


func _is_tank_on_bench() -> bool:
	return bench.global_position.distance_to(tank.global_position) < 50.0


func _start_input_assignment():
	sequence_active = true
	_enable_input_assignment()
	emit_signal("bench_conditions_met")


func _disable_input_assignment():
	if not input_assignment_scene:
		return

	input_assignment_scene.process_mode = Node.PROCESS_MODE_DISABLED
	input_assignment_scene.set_process(false)
	input_assignment_scene.set_process_input(false)
	input_assignment_scene.set_process_unhandled_input(false)
	input_assignment_scene.set_process_unhandled_key_input(false)


func _enable_input_assignment():
	if not input_assignment_scene:
		return

	input_assignment_scene.process_mode = Node.PROCESS_MODE_INHERIT
	input_assignment_scene.set_process(true)
	input_assignment_scene.set_process_input(true)
	input_assignment_scene.set_process_unhandled_input(true)
	input_assignment_scene.set_process_unhandled_key_input(true)


# -----------------------------
# DOOR TRIGGER
# -----------------------------

func _on_door_trigger_entered(body: Node):
	if not body.is_in_group("tank"):
		return

	print("DoorTrigger: Tank detected")
	_exit_hangar()


func _exit_hangar():
	print("Exiting hangar…")
	stage_manager.go_to_stage("Stage1_TrainingGround")
