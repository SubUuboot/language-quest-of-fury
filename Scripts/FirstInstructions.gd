extends Node
signal sequence_complete

@export var commander_path: NodePath
@export var rusty_path: NodePath
@export var tank_path: NodePath
@export var door_path: NodePath

@onready var commander = get_node_or_null(commander_path)
@onready var rusty = get_node_or_null(rusty_path)
@onready var tank = get_node_or_null(tank_path)
@onready var hangar_door = get_node_or_null(door_path)

var sequence = [
	{"action": "accelerate", "dialogue": "Rusty, avance."},
	{"action": "reverse", "dialogue": "Recule."},
	{"action": "steer_left", "dialogue": "Tourne à gauche."},
	{"action": "steer_right", "dialogue": "Tourne à droite."},
]

var current_order = ""

func _ready():
	print("[FirstInstructions] Sequence started.")
	_start_next_order()

func _start_next_order():
	if sequence.is_empty():
		_finish_sequence()
		return

	var order = sequence.pop_front()
	current_order = order["action"]
	if commander:
		commander.play_dialogue(order["dialogue"])
	else:
		print("[Commander]: %s" % order["dialogue"])

func _process(_delta):
	if current_order == "":
		return

#	if Input.is_action_just_pressed(current_order):
#		print("[Rusty]: %s done" % current_order)
#		current_order = ""
#		await get_tree().create_timer(1.2).timeout
#		_start_next_order()

func _finish_sequence():
	print("[FirstInstructions] Sequence complete.")
	if hangar_door and hangar_door.has_method("open_door"):
		hangar_door.open_door()
	emit_signal("sequence_complete")
