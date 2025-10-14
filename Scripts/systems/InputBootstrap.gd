extends Node

## Initialise les entrées par défaut du jeu.
## Appelé au démarrage (autoload ou scène d’intro).
func _ready():
	# === Transmission ===
	_ensure_action("gear_up",   [KEY_KP_ADD])      # Pavé num +
	_ensure_action("gear_down", [KEY_KP_ENTER, JOY_BUTTON_RIGHT_SHOULDER])    # Pavé num Entrée
	_ensure_action("clutch",    [KEY_KP_0, JOY_BUTTON_X])        # Pavé num 0

	# === Conduite du tank ===
	_ensure_action("engine_start",[KEY_E, JOY_BUTTON_START])
	_ensure_action("accelerate", [KEY_SPACE, JOY_BUTTON_A])
	_ensure_action("brake",      [KEY_CTRL, JOY_BUTTON_B])
	_ensure_action("steer_left", [KEY_Q, JOY_AXIS_LEFT_X])
	_ensure_action("steer_right",[KEY_D, -JOY_AXIS_LEFT_X])


	# === Réservé pour la tourelle ===
	_ensure_action("turret_left",  [KEY_LEFT, JOY_AXIS_RIGHT_X])
	_ensure_action("turret_right", [KEY_RIGHT, JOY_AXIS_RIGHT_X])


	print("🎮 InputBootstrap initialisé avec les bindings par défaut.")

	# === Debug / Interface ===

	_ensure_action("ui_debug_menu", [KEY_F1])


	print("🎮 binding de débug initialisé dans InputBootstrap.")


func _ensure_action(action_name: String, scancodes: Array[int] = []) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for code in scancodes:
		if code == 0:
			continue  # évite les touches invalides
		var ev := InputEventKey.new()
		ev.keycode = code as Key # ← cast explicite ici
		if not _has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)

func _has_event(action_name: String, event: InputEventKey) -> bool:
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and e.keycode == event.keycode:
			return true
	return false

func reset_all_inputs() -> void:
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
	print("🧹 Toutes les actions ont été nettoyées.")
