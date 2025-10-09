extends Node

## Initialise les entrées par défaut du jeu.
## Appelé au démarrage (autoload ou scène d’intro).
func _ready():
	# === Transmission ===
	_ensure_action("gear_up",   [KEY_KP_ADD])      # Pavé num +
	_ensure_action("gear_down", [KEY_KP_ENTER])    # Pavé num Entrée
	_ensure_action("clutch",    [KEY_KP_0])        # Pavé num 0

	# === Conduite du tank ===
	_ensure_action("accelerate", [KEY_SPACE])
	_ensure_action("brake",      [KEY_CTRL])
	_ensure_action("steer_left", [KEY_Q])
	_ensure_action("steer_right",[KEY_D])

	# === Réservé pour la tourelle ===
	_ensure_action("turret_left",  [KEY_LEFT])
	_ensure_action("turret_right", [KEY_RIGHT])

	# === Reste compatible avec d’anciens scripts ===
	# (utile si certains appels utilisent encore "move_forward" etc.)

	# === Debug / Interface ===
	_ensure_action("toggle_debug", [KEY_F3])

	print("🎮 InputBootstrap initialisé avec les bindings par défaut.")

func _ensure_action(action_name: String, scancodes: Array[int] = []) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for code in scancodes:
		var ev := InputEventKey.new()
		ev.keycode = code as Key # ← cast explicite ici
		if not _has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)

func _has_event(action_name: String, event: InputEventKey) -> bool:
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and e.keycode == event.keycode:
			return true
	return false
