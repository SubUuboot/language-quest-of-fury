extends Node
signal sequence_complete

enum State { INIT, AWAIT_INPUT, VALIDATE, CONFIRM, COMPLETE }

var bindings = {}
var current_action = ""
var state = State.INIT
var config = ConfigFile.new()
var order_index = 0

@onready var dialogue_sync = $DialogueSync
@onready var ui = $"../UI"
@onready var tank = get_node_or_null("/root/Game/Main/Characters/Tank")
@onready var mother_ai = $"../../../../../MotherAI"

var orders = [
	{"action": "accelerate", "dialogue": "FORWARD", "prompt": "Push the levers to move forward"},
	{"action": "steer_left", "dialogue": "LEFT TURN", "prompt": "Pull the lever to turn left"},
	{"action": "steer_right", "dialogue": "RIGHT TURN", "prompt": "Pull the lever to turn right"},
	{"action": "brake", "dialogue": "BRAKE", "prompt": "Pump the brakes"},
	{"action": "clutch", "dialogue": "CLUTCH", "prompt": "Double-pump the clutch"},
	{"action": "gear_up", "dialogue": "GEAR UP", "prompt": "High gear shift"},
	{"action": "gear_down", "dialogue": "GEAR DOWN", "prompt": "Low gear shift"},
]

func _ready():
	
	# si la scène est désactivée, ne rien faire
	if not is_inside_tree():
		return
		
	if tank == null:
		push_warning("Tank non trouvé dans la scène principale.")
		
	if not dialogue_sync:
		push_error("DialogueSync introuvable — vérifie la scène InputAssignmentScene.tscn")
	if not tank:
		push_warning("Tank non trouvé dans la scène principale.")
	if not mother_ai:
		push_warning("MotherAI non trouvé (autoload manquant ?)")
	dialogue_sync.play_commander_line("INITIATE CONTROL MAPPING SEQUENCE")
	next_order()

func next_order():
	if order_index >= orders.size():
		dialogue_sync.play_commander_line("SEQUENCE COMPLETE")
		save_bindings()
		state = State.COMPLETE
		emit_signal("sequence_complete")
		return

	var order = orders[order_index]
	current_action = order["action"]
	ui.update_prompt(order["prompt"])
	dialogue_sync.play_commander_line(order["dialogue"])
	state = State.AWAIT_INPUT

func _input(event):
	if state == State.AWAIT_INPUT and event is InputEventKey and event.pressed:
		var key_name = OS.get_keycode_string(event.keycode)
		if key_name in bindings.values():
			ui.feedback("Key already assigned!")
			dialogue_sync.play_technician_line("Uh, that one's already in use, sir...")
			return
		bindings[current_action] = key_name
		ui.feedback("Assigned %s to %s" % [key_name, current_action])
		dialogue_sync.play_technician_line("Got it. Rusty seems to respond.")
		simulate_tank_reaction(current_action)
		state = State.VALIDATE
		await get_tree().create_timer(1.5).timeout
		order_index += 1
		next_order()

func simulate_tank_reaction(action):
	if not tank:
		push_warning("simulate_tank_reaction() appelé sans tank valide.")
		return
	match action:
		"accelerate": tank.play_animation("idle_rev")
		"steer_left": tank.play_animation("left_torque")
		"fire": tank.play_animation("barrel_charge")
	if mother_ai and mother_ai.has_method("play_animation"):
		mother_ai.play_animation("arm_adjust")

func save_bindings():
	for action in bindings.keys():
		config.set_value("controls", action, bindings[action])
	config.save("user://controls.cfg")
