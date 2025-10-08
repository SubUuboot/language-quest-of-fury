extends Node

signal command_given(command: String)
signal lesson_completed()

@export var hud_path: NodePath
@onready var hud: Node = null
@export var tank_path: NodePath
@onready var tank: Node = null
@onready var command_timer: Timer = $CommandTimer

@export var input_grace_time: float = 0.4
var last_input_time: float = 0.0
var last_input_action: String = ""

var successes: int = 0
var failures: int = 0

var current_lesson: Dictionary = {}
var current_command_index: int = 0
var awaiting_response := false
var response_timeout := 6.0

func _ready() -> void:
	hud = get_node_or_null(hud_path)
	tank = get_node_or_null(hud_path)
	print("Instructor init! HUD:", hud != null, " Tank:", tank != null)

	# Charger les dialogues au lancement si pas déjà fait
	if DialogueSystem.dialogues.is_empty():
		DialogueSystem.load_dialogues("res://Content/RussianTraining/Dialogues/dialogues.json")

	if command_timer:
		command_timer.timeout.connect(_on_command_timeout)
	if tank and tank.has_signal("player_performed_action"):
		tank.player_performed_action.connect(_on_tank_action)

	# Démarrer sur la première leçon
	start_lesson("hangar_exit")

# ------------------------------------
# Gestion des leçons
# ------------------------------------
func start_lesson(lesson_id: String) -> void:
	current_lesson = DialogueSystem.get_lesson("instructor", lesson_id)
	if current_lesson.is_empty():
		push_error("❌ Leçon introuvable: " + lesson_id)
		return

	current_command_index = 0
	if hud:
		hud.show_instructor_message(current_lesson["instructions"], 3.5)
	await get_tree().create_timer(3.5).timeout
	_give_next_command()

func _give_next_command() -> void:
	var cmds: Array = current_lesson["commands"]
	if current_command_index >= cmds.size():
		_show_feedback("complete", 2.0)
		emit_signal("lesson_completed")
		return

	var command_key: String = cmds[current_command_index]
	var cmd = DialogueSystem.get_dialogue("instructor", "commands", command_key)
	if cmd.is_empty():
		current_command_index += 1
		_give_next_command()
		return

	if hud:
		hud.show_instructor_message("%s (%s)" % [cmd["text"], cmd["translation"]], response_timeout)

	emit_signal("command_given", command_key)
	awaiting_response = true
	if command_timer:
		command_timer.start(response_timeout)

	var now := Time.get_ticks_msec() / 1000.0
	if last_input_action == command_key and (now - last_input_time) <= input_grace_time:
		_check_player_action(command_key)

# ------------------------------------
# Feedback et validation
# ------------------------------------
func _on_command_timeout() -> void:
	if awaiting_response:
		_show_feedback("repeat", 1.5)
		_give_next_command()

func _check_player_action(action: String) -> void:
	if not awaiting_response:
		return

	var cmds: Array = current_lesson["commands"]
	var expected: String = String(cmds[current_command_index])
	if action == expected:
		awaiting_response = false
		if command_timer:
			command_timer.stop()
		_show_feedback("good", 1.2)
		current_command_index += 1
		await get_tree().create_timer(1.0).timeout
		_give_next_command()
	else:
		_show_feedback("wrong", 1.2)

func _on_tank_action(action: String) -> void:
	last_input_time = Time.get_ticks_msec() / 1000.0
	last_input_action = action
	_check_player_action(action)

# ------------------------------------
# Utilitaires DialogueSystem
# ------------------------------------
func _show_feedback(id: String, duration: float = 1.5) -> void:
	var d = DialogueSystem.get_dialogue("instructor", "feedback", id)
	if not d.is_empty() and hud:
		hud.show_instructor_message("%s (%s)" % [d["text"], d["translation"]], duration)

# ------------------------------------
# Appelé quand le tank entre dans une zone de validation
# ------------------------------------
func _on_zone_reached(zone: Area2D) -> void:
	print("Zone atteinte :", zone.name)

	if zone.has_meta("expected_command"):
		var expected: String = zone.get_meta("expected_command")

		# Vérifie la dernière action jouée
		if last_input_action == expected:
			successes += 1
			print("✅ Réussi ! Action correcte :", expected)
			_show_feedback("good", 1.5)
		else:
			failures += 1
			print("❌ Raté ! Attendu :", expected, " → reçu :", last_input_action)
			_show_feedback("wrong", 1.5)
	else:
		# Zone neutre, juste un checkpoint
		print("Checkpoint neutre atteint.")
		_show_feedback("repeat", 1.0)

	# Debug score actuel
	print("Score actuel : ", successes, " réussites / ", failures, " échecs")
