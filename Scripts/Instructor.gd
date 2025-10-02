extends Node

signal command_given(command: String)                # Émis à chaque ordre
signal lesson_started(index: int, name: String)      # Début de leçon
signal lesson_completed(index: int)                  # Fin de leçon
signal training_completed                            # Toutes les leçons terminées

@onready var hud = get_node("../HUDLayer/HUD")
@onready var tank = get_node("../Tank")
@onready var command_timer: Timer = $CommandTimer

@export var response_timeout: float = 6.0            # Temps pour répondre à un ordre
@export var input_grace_time: float = 0.4            # Valide si le joueur a fait l’action juste avant l’ordre

# Mémoire de la dernière action
var last_input_time: float = 0.0
var last_input_action: String = ""

# Leçons séquencées (à enrichir ensuite)
var lessons: Array[Dictionary] = [
	{
		"name": "Piste de roulage — sortie hangar",
		"instructions": "On y va. Exécute les ordres sur la piste.",
		"commands": ["forward","stop","left","forward","stop","right","forward","stop","backward","stop"]
	},
	
	{
	"name": "Parcours d’obstacles — fossé et butte",
	"instructions": "Montre que tu peux franchir les obstacles. Pas d’excuses.",
	"commands": ["forward","cross","stop","forward","climb","stop"]
	}
]


# État interne
var _current_lesson: int = 0
var _current_cmd_index: int = 0
var _awaiting_response: bool = false
var _pending_command: String = ""
var _order_token: int = 0   # Incrémente à chaque nouvel ordre pour éviter conflits timeout/succès

# Feedback phrases
var phrases_ok: Array[Dictionary] = [
	{"text":"Хорошо.", "translation":"Bien."},
	{"text":"Верно.",  "translation":"Correct."}
]
var phrases_retry: Array[Dictionary] = [
	{"text":"Повторите.", "translation":"Répétez."},
	{"text":"Не то.",      "translation":"Pas ça."}
]
var phrase_intro: String = "Следуйте моим приказам."  # Suivez mes ordres.

func _ready() -> void:
	if command_timer:
		command_timer.timeout.connect(_on_command_timeout)
	if tank and tank.has_signal("player_performed_action"):
		tank.player_performed_action.connect(_on_tank_action)
	
	# Connecter toutes les zones de validation
	for zone in get_tree().get_nodes_in_group("validation_zones"):
		zone.tank_entered.connect(_on_zone_reached)

func _on_zone_reached(zone_id: String) -> void:
	if not _awaiting_response:
		return
	if zone_id == _pending_command:
		_try_validate_current(_order_token)	# succès

# Appelé depuis Main.gd après la fin du Commander
func start_training() -> void:
	_start_lesson(0)

# -------------------------
#  GESTION DES LEÇONS
# -------------------------
func _start_lesson(index: int) -> void:
	if index >= lessons.size():
		_finish_training()
		return

	_current_lesson = index
	_current_cmd_index = 0
	_awaiting_response = false
	_pending_command = ""

	var lesson: Dictionary = lessons[_current_lesson]
	emit_signal("lesson_started", _current_lesson, String(lesson.get("name","")))

	var intro_msg: String = String(lesson.get("instructions", phrase_intro))
	_show_msg(intro_msg, 2.5)
	await get_tree().create_timer(2.5).timeout
	_give_next_command()

func _give_next_command() -> void:
	var lesson: Dictionary = lessons[_current_lesson]

	# Conversion Array générique -> Array[String]
	var raw_cmds: Array = lesson.get("commands", [])
	var cmds: Array[String] = []
	for c in raw_cmds:
		if typeof(c) == TYPE_STRING:
			cmds.append(c)

	if cmds.is_empty():
		push_warning("⚠️ Leçon vide: %s" % [lesson])
		_complete_current_lesson()
		return

	if _current_cmd_index >= cmds.size():
		_complete_current_lesson()
		return

	var command_key: String = cmds[_current_cmd_index]

	# Vérifie que la commande existe dans le Tank
	if not (tank and tank.commands.has(command_key)):
		push_warning("⚠️ Commande inconnue côté Tank: %s" % command_key)
		_current_cmd_index += 1
		_give_next_command()
		return

	var cmd_data: Dictionary = tank.commands[command_key]
	var text := "%s (%s)" % [
		String(cmd_data.get("russian","")),
		String(cmd_data.get("pronunciation",""))
	]

	_show_msg(text, response_timeout)
	emit_signal("command_given", command_key)

	_pending_command = command_key
	_awaiting_response = true
	_order_token += 1
	var my_token := _order_token

	if command_timer:
		command_timer.start(response_timeout)

	# Validation immédiate si action déjà faite juste avant
	var now := Time.get_ticks_msec() / 1000.0
	if last_input_action == command_key and (now - last_input_time) <= input_grace_time:
		_try_validate_current(my_token)

func _complete_current_lesson() -> void:
	emit_signal("lesson_completed", _current_lesson)
	_current_lesson += 1
	if _current_lesson < lessons.size():
		await get_tree().create_timer(1.5).timeout
		_start_lesson(_current_lesson)
	else:
		_finish_training()

func _finish_training() -> void:
	_show_msg("Этап завершён. (Étape terminée.)", 2.5)
	emit_signal("training_completed")

# -------------------------
#  VALIDATION
# -------------------------
func _on_tank_action(action: String) -> void:
	last_input_time = Time.get_ticks_msec() / 1000.0
	last_input_action = action

	if not _awaiting_response:
		return
	if action != _pending_command:
		_say_retry()
		return

	_try_validate_current(_order_token)

func _on_command_timeout() -> void:
	if _awaiting_response:
		_say_retry()
		_awaiting_response = false
		_pending_command = ""
		await get_tree().create_timer(0.6).timeout
		_give_next_command()

func _try_validate_current(token: int) -> void:
	if token != _order_token or not _awaiting_response:
		return

	_awaiting_response = false
	_pending_command = ""
	if command_timer and command_timer.time_left > 0.0:
		command_timer.stop()

	_say_ok()
	_current_cmd_index += 1
	await get_tree().create_timer(0.8).timeout
	_give_next_command()

# -------------------------
#  FEEDBACK / HUD
# -------------------------
func _say_ok() -> void:
	var p: Dictionary = phrases_ok[randi() % phrases_ok.size()]
	_show_msg("%s (%s)" % [p["text"], p["translation"]], 1.0)

func _say_retry() -> void:
	var p: Dictionary = phrases_retry[randi() % phrases_retry.size()]
	_show_msg("%s (%s)" % [p["text"], p["translation"]], 1.0)

func _show_msg(text: String, duration: float) -> void:
	if hud:
		hud.show_instructor_message(text, duration)
