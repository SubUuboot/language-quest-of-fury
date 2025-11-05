extends Node

signal bench_conditions_met

@onready var bench_trigger: Area2D = %BenchTrigger
@onready var bench: StaticBody2D = $"../../Environment/Bench"
@onready var input_assignment_scene: Node = $"../InputAssignmentScene"

# Tank et Rusty sont persistants dans Main
var tank: Node = null
var rusty: Node = null
var sequence_active := false

func _ready():
	
	var main = get_tree().get_root().get_node("Game/Main/Characters")
	tank = main.get_node("Tank")
	rusty = main.get_node("Rusty")

# Empêche InputAssignmentScene de s’exécuter au chargement
	if input_assignment_scene:
		input_assignment_scene.process_mode = Node.PROCESS_MODE_DISABLED
		input_assignment_scene.set_process(false)
		input_assignment_scene.set_process_input(false)
		input_assignment_scene.set_process_unhandled_input(false)
		input_assignment_scene.set_process_unhandled_key_input(false)


	if bench_trigger:
		bench_trigger.connect("body_entered", Callable(self, "_on_bench_trigger_entered"))

func _on_bench_trigger_entered(body: Node):
	if sequence_active:
		return
	if body == tank and _is_rusty_inside_tank() and _is_tank_on_bench():
		_start_input_assignment()

func _is_rusty_inside_tank() -> bool:
	# À adapter selon ta logique (flag, variable, parent, etc.)
	return rusty.get("is_embarked") == true

func _is_tank_on_bench() -> bool:
	# Vérifie si le centre du tank est proche du banc
	var dist = bench.global_position.distance_to(tank.global_position)
	return dist < 50.0  # ajustable selon la taille de ton banc

func _start_input_assignment():
	sequence_active = true
	print("Conditions remplies → activation InputAssignmentScene")
	
	if input_assignment_scene:
		input_assignment_scene.process_mode = Node.PROCESS_MODE_INHERIT
		input_assignment_scene.set_process(true)
		input_assignment_scene.set_process_input(true)
		input_assignment_scene.set_process_unhandled_input(true)
		input_assignment_scene.set_process_unhandled_key_input(true)
	
	emit_signal("bench_conditions_met")
