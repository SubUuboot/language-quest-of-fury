extends Node

## ============================================================
## InputBootstrap
## Initialise les entrées par défaut du jeu (clavier + manette).
## Appelé automatiquement au démarrage (autoload).
## ============================================================

func _ready() -> void:
	# --- Tente de recharger les bindings personnalisés ---
	load_bindings()
	repair_missing_bindings()
	
	# === Transmission ===
	_ensure_action("gear_up",   [KEY_KP_ADD, JOY_BUTTON_RIGHT_SHOULDER])   # Pavé num + / R1
	_ensure_action("gear_down", [KEY_KP_ENTER, JOY_BUTTON_LEFT_SHOULDER])  # Pavé num Entrée / L1
	_ensure_action("clutch",    [KEY_KP_0, JOY_BUTTON_X])                  # Pavé num 0 / X

	# === Conduite du tank ===
	_ensure_action("engine_start", [KEY_E, JOY_BUTTON_START])
	_ensure_action("accelerate",   [KEY_SPACE, JOY_BUTTON_A])
	_ensure_action("brake",        [KEY_CTRL, JOY_BUTTON_B])
	_ensure_action("steer_left",   [KEY_Q, JOY_AXIS_LEFT_X])               # axe analogique gauche
	_ensure_action("steer_right",  [KEY_D, -JOY_AXIS_LEFT_X])              # axe analogique gauche inversé

	# === Tourelle ===
	_ensure_action("turret_left",  [KEY_LEFT, JOY_AXIS_RIGHT_X])
	_ensure_action("turret_right", [KEY_RIGHT, -JOY_AXIS_RIGHT_X])

	# === Debug / Interface ===
	_ensure_action("ui_devtools_menu", [KEY_F1])  # utilisé par DevTools


	print("🎮 [InputBootstrap] Bindings clavier/manette initiaux enregistrés.")
	print("🧩 [InputBootstrap] DevTools (F1) activé.")


# ------------------------------------------------------------
# Enregistre ou met à jour une action d'entrée donnée.
# Détecte automatiquement le type (touche, bouton ou axe).
# ------------------------------------------------------------
func _ensure_action(action_name: String, inputs: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for input in inputs:
		if input == 0:
			continue

		var ev: InputEvent = null

		# --- Clavier ---
		if typeof(input) == TYPE_INT and input < 1000:
			ev = InputEventKey.new()
			ev.keycode = input

		# --- Boutons de manette ---
		elif input >= JOY_BUTTON_A and input <= JOY_BUTTON_RIGHT_STICK:
			ev = InputEventJoypadButton.new()
			ev.button_index = input

		# --- Axes de manette ---
		elif abs(input) >= JOY_AXIS_LEFT_X and abs(input) <= JOY_AXIS_RIGHT_Y:
			ev = InputEventJoypadMotion.new()
			ev.axis = abs(input)
			ev.axis_value = 1.0 if input > 0 else -1.0

		# --- Validation et ajout ---
		if ev and not _has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)


# ------------------------------------------------------------
# Vérifie si une action possède déjà un événement donné
# (évite les doublons clavier/manette/axe)
# ------------------------------------------------------------
func _has_event(action_name: String, event: InputEvent) -> bool:
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and event is InputEventKey and e.keycode == event.keycode:
			return true
		if e is InputEventJoypadButton and event is InputEventJoypadButton and e.button_index == event.button_index:
			return true
		if e is InputEventJoypadMotion and event is InputEventJoypadMotion and e.axis == event.axis and e.axis_value == event.axis_value:
			return true
	return false


# ------------------------------------------------------------
# Supprime tous les événements enregistrés (debug / reset total)
# ------------------------------------------------------------
func reset_all_inputs() -> void:
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
	print("🧹 [InputBootstrap] Toutes les actions ont été nettoyées.")

# ------------------------------------------------------------
# Remappe dynamiquement une action existante
# Permet de changer la touche, le bouton ou l’axe d’un binding
# ------------------------------------------------------------
func remap_action(action_name: String, new_input: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		push_warning("[InputBootstrap] Action '%s' inexistante — création automatique." % action_name)
		InputMap.add_action(action_name)

	# Efface les événements précédents
	InputMap.action_erase_events(action_name)

	# Ajoute le nouvel événement
	InputMap.action_add_event(action_name, new_input)

	# Journalise le changement
	var input_label := ""
	if new_input is InputEventKey:
		input_label = OS.get_keycode_string(new_input.keycode)
	elif new_input is InputEventJoypadButton:
		input_label = "Button %d" % new_input.button_index
	elif new_input is InputEventJoypadMotion:
		input_label = "Axis %d (%.1f)" % [new_input.axis, new_input.axis_value]

	print("🎛️ [InputBootstrap] Action '%s' remappée sur %s" % [action_name, input_label])
	
	save_bindings()
	print("🎛️ [InputBootstrap] bindings sauvegarder dans user://bindings.json" )

# ------------------------------------------------------------
# SAUVEGARDE ET CHARGEMENT DES BINDINGS UTILISATEUR
# ------------------------------------------------------------

const BINDINGS_FILE := "user://bindings.json"

# Sauvegarde tous les bindings actuels dans un fichier JSON
func save_bindings() -> void:
	var data: Dictionary = {}
	for action in InputMap.get_actions():
		var events: Array = []
		for ev in InputMap.action_get_events(action):
			var entry := {}
			if ev is InputEventKey:
				entry["type"] = "key"
				entry["keycode"] = ev.keycode
			elif ev is InputEventJoypadButton:
				entry["type"] = "joy_button"
				entry["button_index"] = ev.button_index
			elif ev is InputEventJoypadMotion:
				entry["type"] = "joy_axis"
				entry["axis"] = ev.axis
				entry["axis_value"] = ev.axis_value
			events.append(entry)
		data[action] = events

	var file := FileAccess.open(BINDINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))  # indenté pour lisibilité
		file.close()
		print("💾 [InputBootstrap] Bindings sauvegardés dans", BINDINGS_FILE)
	else:
		push_warning("[InputBootstrap] Impossible d’écrire dans " + BINDINGS_FILE)


# Recharge les bindings depuis le fichier JSON s’il existe
# ------------------------------------------------------------
# Recharge les bindings depuis le fichier JSON s’il existe,
# sans jamais casser les contrôles par défaut.
# ------------------------------------------------------------
func load_bindings() -> void:
	if not FileAccess.file_exists(BINDINGS_FILE):
		print("📁 [InputBootstrap] Aucun fichier de bindings trouvé — valeurs par défaut conservées.")
		return

	var file := FileAccess.open(BINDINGS_FILE, FileAccess.READ)
	if not file:
		push_warning("[InputBootstrap] Échec de lecture du fichier " + BINDINGS_FILE)
		return

	var content := file.get_as_text()
	file.close()

	var result: Variant = JSON.parse_string(content)
	if typeof(result) != TYPE_DICTIONARY:
		push_warning("[InputBootstrap] Fichier de bindings corrompu ou vide — valeurs par défaut conservées.")
		return

	# Vérifie que le fichier contient au moins une action cohérente
	var valid_entries := 0
	for action_name in result.keys():
		if typeof(result[action_name]) == TYPE_ARRAY and result[action_name].size() > 0:
			valid_entries += 1
	if valid_entries == 0:
		push_warning("[InputBootstrap] Aucun binding valide trouvé — valeurs par défaut conservées.")
		return

	print("🔁 [InputBootstrap] Fichier de bindings utilisateur détecté, application en cours…")

	# Recharge uniquement les actions connues et valides
	for action_name in result.keys():
		if not InputMap.has_action(action_name):
			print("[InputBootstrap] ⚠️ Action inconnue '%s' ignorée." % action_name)
			continue

		# Nettoie uniquement cette action (pas tout)
		InputMap.action_erase_events(action_name)

		for entry in result[action_name]:
			var ev: InputEvent = null
			match entry.get("type", ""):
				"key":
					ev = InputEventKey.new()
					ev.keycode = entry.get("keycode", 0)
				"joy_button":
					ev = InputEventJoypadButton.new()
					ev.button_index = entry.get("button_index", 0)
				"joy_axis":
					ev = InputEventJoypadMotion.new()
					ev.axis = entry.get("axis", 0)
					ev.axis_value = entry.get("axis_value", 1.0)
			if ev:
				InputMap.action_add_event(action_name, ev)

	print("✅ [InputBootstrap] Bindings personnalisés appliqués sans perte de commandes.")


# ------------------------------------------------------------
# AUTO-RÉPARATION DES BINDINGS
# Compare les actions actuelles à celles attendues par défaut
# et recrée celles qui manquent ou sont vides.
# ------------------------------------------------------------
func repair_missing_bindings() -> void:
	var required_actions := {
		"gear_up": [KEY_KP_ADD, JOY_BUTTON_RIGHT_SHOULDER],
		"gear_down": [KEY_KP_ENTER, JOY_BUTTON_LEFT_SHOULDER],
		"clutch": [KEY_KP_0, JOY_BUTTON_X],
		"engine_start": [KEY_E, JOY_BUTTON_START],
		"accelerate": [KEY_SPACE, JOY_BUTTON_A],
		"brake": [KEY_CTRL, JOY_BUTTON_B],
		"steer_left": [KEY_Q, JOY_AXIS_LEFT_X],
		"steer_right": [KEY_D, -JOY_AXIS_LEFT_X],
		"turret_left": [KEY_LEFT, JOY_AXIS_RIGHT_X],
		"turret_right": [KEY_RIGHT, -JOY_AXIS_RIGHT_X],
		"ui_devtools_menu": [KEY_F1],
	}

	for action_name in required_actions.keys():
		if not InputMap.has_action(action_name):
			print("🧩 [InputBootstrap] Action manquante '%s' recréée." % action_name)
			_ensure_action(action_name, required_actions[action_name])
			continue

		var events := InputMap.action_get_events(action_name)
		if events.is_empty():
			print("🧩 [InputBootstrap] Action '%s' vide — réinitialisée." % action_name)
			_ensure_action(action_name, required_actions[action_name])

	print("🔧 [InputBootstrap] Vérification et réparation des bindings terminée.")
