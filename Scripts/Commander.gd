extends Node

signal command_given(command: String)   # Signal envoyé au Tank
signal protocol_complete                # Signal émis quand le protocole est fini

@onready var hud = get_node("../HUDLayer/HUD")
@onready var tank = get_node("../Tank")

# Séquence fixe d’ordres de base
var commands: Array = ["forward", "stop", "left", "right", "backward"]
var current_index: int = 0
var awaiting_response: bool = false

func _ready() -> void:
	if tank and tank.has_signal("player_performed_action"):
		tank.player_performed_action.connect(_on_tank_action)
	start_protocol()

# --- Déroulement du protocole ---
func start_protocol() -> void:
	show_message("Протокол инициализации. Следуйте приказам.\n(Protocole d’activation. Suivez les ordres.)", 2.5)
	await get_tree().create_timer(2.5).timeout
	give_next_command()

func give_next_command() -> void:
	if current_index >= commands.size():
		show_message("Протокол завершён.\n(Protocole terminé.)", 3.0)
		emit_signal("protocol_complete")
		return

	var cmd: String = commands[current_index]
	if tank and tank.commands.has(cmd):
		var cmd_data = tank.commands[cmd]
		var text = "%s (%s)" % [cmd_data["russian"], cmd_data["pronunciation"]]
		show_message(text, 3.0)
	else:
		show_message("Erreur: commande inconnue", 2.0)

	emit_signal("command_given", cmd)
	awaiting_response = true

# --- Vérification du joueur ---
func _on_tank_action(action: String) -> void:
	if not awaiting_response:
		return

	var expected: String = commands[current_index]

	if action == expected:
		show_message("Хорошо. (Bien.)", 1.2)
		awaiting_response = false
		current_index += 1
		await get_tree().create_timer(1.0).timeout
		give_next_command()
	else:
		show_message("Повторите. (Répétez.)", 1.2)

# --- Affichage HUD ---
func show_message(text: String, duration: float) -> void:
	if hud:
		hud.show_instructor_message(text, duration)
