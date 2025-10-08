extends Node2D

@onready var input_assignment = $InputAssignmentScene
@onready var first_instructions = $FirstInstructionsScene
@onready var commander = %Commander
@onready var tank = get_node_or_null("/root/Game/Main/Characters/Tank")
@onready var hangar_door = %HangarDoor
@onready var door_trigger = %DoorTrigger
@onready var bench_trigger = %BenchTrigger


var phase := "ASSIGNMENT"

	# on démarre sur la phase d’assignation
func _ready():
	_connect_signals()

func _on_stage_loaded(stage_name: String):
	if stage_name == "Stage0":
		print("Stage0_Hangar initié")
		if commander and tank:
			tank.orders_source = commander
			print("[Link] Tank connected to Commander for Stage0.")



func _connect_signals():
	if input_assignment.has_signal("sequence_complete"):
		input_assignment.connect("sequence_complete", Callable(self, "_on_assignment_complete"))
	if bench_trigger:
		bench_trigger.connect("body_entered", Callable(self, "_on_bench_trigger"))
	if door_trigger:
		door_trigger.connect("body_entered", Callable(self, "_on_door_trigger"))

func _on_assignment_complete():
	phase = "TEST"
	first_instructions.visible = true
	input_assignment.visible = false
	if commander.has_method("start_test_sequence"):
		commander.start_test_sequence()

func _on_bench_trigger(body):
	if body.name == "RustyTank":
		print("Rusty near bench → reopen assignment")
		phase = "ASSIGNMENT"
		first_instructions.visible = false
		input_assignment.visible = true

func _on_door_trigger(body):
	if body.name == "RustyTank" and phase == "TEST":
		print("→ Leaving hangar")
		if hangar_door.has_method("open_door"):
			hangar_door.open_door()
		await get_tree().create_timer(2.0).timeout
		get_parent().emit_signal("stage_complete") # signal capté par StageManager
