extends Node

signal command_given(command: String)
signal protocol_completed()


@export var hud_path: NodePath
@onready var hud: Node = null
@export var tank_path: NodePath
@onready var tank: Node = null
@onready var command_timer: Timer = $CommandTimer

@export var input_grace_time: float = 0.4
var last_input_time: float = 0.0
var last_input_action: String = ""

var current_sequence: Array[String] = []
var current_index: int = 0
var awaiting_response := false
var response_timeout := 5.0

func _ready() -> void:
	
	if hud_path and get_node_or_null(hud_path):
		hud = get_node(hud_path)
	else:
		push_warning("HUD non assigné dans %s" % name)

	if tank_path and get_node_or_null(tank_path):
		tank = get_node(tank_path)
	else:
		push_warning("Tank non assigné dans %s" % name)
	tank = get_node_or_null(tank_path)
	hud = get_node_or_null(hud_path)
	
	print("Commander init! HUD:", hud != null, " Tank:", tank != null)

	# Charger dialogues si nécessaire
	if DialogueSystem.dialogues.is_empty():
		DialogueSystem.load_dialogues("res://Content/RussianTraining/Dialogues/dialogues.json")

	if command_timer:
		command_timer.timeout.connect(_on_command_timeout)
	if tank and tank.has_signal("player_performed_action"):
		tank.player_performed_action.connect(_on_tank_action)

	_start_protocol()

# ------------------------------------
# Protocole d’activation
# ------------------------------------
func _start_protocol() -> void:
	_show_dialogue("intro", "init", 3.0)

	# Séquence fixe de commandes basiques
	current_sequence = ["forward", "stop", "left", "stop", "right", "stop", "backward", "stop"]
	current_index = 0

	await get_tree().create_timer(3.0).timeout
	_give_next_command()

func _end_protocol() -> void:
	_show_dialogue("intro", "end", 3.0)
	emit_signal("protocol_completed")

# ------------------------------------
# Commandes
# ------------------------------------
func _give_next_command() -> void:
	if current_index >= current_sequence.size():
		_end_protocol()
		return

	var cmd_id: String = current_sequence[current_index]
	var cmd = DialogueSystem.get_dialogue("commander", "commands", cmd_id)
	if cmd.is_empty():
		current_index += 1
		_give_next_command()
		return

	if hud:
		hud.show_instructor_message("%s (%s)" % [cmd["text"], cmd["translation"]], response_timeout)

	emit_signal("command_given", cmd_id)
	awaiting_response = true
	if command_timer:
		command_timer.start(response_timeout)

	var now := Time.get_ticks_msec() / 1000.0
	if last_input_action == cmd_id and (now - last_input_time) <= input_grace_time:
		_check_player_action(cmd_id)

# ------------------------------------
# Validation
# ------------------------------------
func _on_command_timeout() -> void:
	if awaiting_response:
		_show_dialogue("feedback", "repeat", 1.5)
		_give_next_command()

func _check_player_action(action: String) -> void:
	if not awaiting_response:
		return

	var expected: String = current_sequence[current_index]
	if action == expected:
		awaiting_response = false
		if command_timer:
			command_timer.stop()
		_show_dialogue("feedback", "good", 1.2)
		current_index += 1
		await get_tree().create_timer(1.0).timeout
		_give_next_command()
	else:
		_show_dialogue("feedback", "repeat", 1.2)

func _on_tank_action(action: String) -> void:
	last_input_time = Time.get_ticks_msec() / 1000.0
	last_input_action = action
	_check_player_action(action)

# ------------------------------------
# Utilitaire JSON
# ------------------------------------
func _show_dialogue(category: String, id: String, duration: float = 1.5) -> void:
	var d = DialogueSystem.get_dialogue("commander", category, id)
	if not d.is_empty() and hud:
		hud.show_instructor_message("%s (%s)" % [d["text"], d["translation"]], duration)
