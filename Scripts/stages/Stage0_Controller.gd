extends Node2D

enum Phase { ASSIGNMENT, TEST, EXIT }

@onready var input_assignment = $InputAssignmentScene
@onready var first_instructions = $FirstInstructionsScene
@onready var commander = %Commander
@onready var hangar_door = %HangarDoor
@onready var door_trigger = %DoorTrigger
@onready var bench_trigger = %BenchTrigger
@onready var stage_manager_local = %Stage0_Manager

@onready var tank_controller = get_node_or_null("/root/Game/Main/Characters/Tank")
var phase: Phase = Phase.ASSIGNMENT

func _ready():
	_connect_signals()
	_on_stage_loaded("Stage0")

func _connect_signals():
	if stage_manager_local:
		stage_manager_local.connect("bench_conditions_met", Callable(self, "_on_bench_conditions_met"))

	if input_assignment.has_signal("sequence_complete") and \
		not input_assignment.is_connected("sequence_complete", Callable(self, "_on_assignment_complete")):
		input_assignment.connect("sequence_complete", Callable(self, "_on_assignment_complete"))

	if bench_trigger and not bench_trigger.is_connected("body_entered", Callable(self, "_on_bench_trigger")):
		bench_trigger.connect("body_entered", Callable(self, "_on_bench_trigger"))

	if door_trigger and not door_trigger.is_connected("body_entered", Callable(self, "_on_door_trigger")):
		door_trigger.connect("body_entered", Callable(self, "_on_door_trigger"))

func _on_stage_loaded(stage_name: String):
	if stage_name == "Stage0":
		print("Stage0_Hangar initié")
		if commander and tank_controller:
			if "orders_source" in tank_controller:
				tank_controller.orders_source = commander
				print("[Link] Tank connected to Commander for Stage0.")
			else:
				print("[Warn] TankController2D n’a pas de variable orders_source.")

func _on_bench_conditions_met():
	if phase != Phase.ASSIGNMENT:
		print("Bench conditions met → starting assignment phase.")
		phase = Phase.ASSIGNMENT
		input_assignment.visible = true
		first_instructions.visible = false
		# Désactiver les contrôles pendant la séquence
		tank_controller.set_process(false)

func _on_assignment_complete():
	phase = Phase.TEST
	first_instructions.visible = true
	input_assignment.visible = false
	tank_controller.set_process(true)
	if commander and commander.has_method("start_test_sequence"):
		commander.start_test_sequence()

func _on_bench_trigger(body):
	if body.name == "RustyTank" and phase == Phase.TEST:
		print("Rusty near bench → reopen assignment")
		phase = Phase.ASSIGNMENT
		first_instructions.visible = false
		input_assignment.visible = true

func _on_door_trigger(body):
	if body.name == "RustyTank" and phase == Phase.TEST:
		print("→ Leaving hangar")
		if hangar_door and hangar_door.has_method("open_door"):
			hangar_door.open_door()
		await get_tree().create_timer(2.0).timeout
		if get_parent().has_signal("stage_complete"):
			get_parent().emit_signal("stage_complete")
