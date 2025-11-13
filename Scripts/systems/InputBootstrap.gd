extends Node

signal actions_ready
signal devtools_toggle_requested

var _actions_registered: bool = false

## ============================================================
## InputBootstrap
## Initialise les entrées par défaut du jeu (clavier + manette).
## Appelé automatiquement au démarrage (autoload).
## ============================================================

const BINDINGS_PATH := "user://input_bindings.json"
const DEFAULT_BINDINGS := {
        "gear_up": [KEY_P, JOY_BUTTON_RIGHT_SHOULDER],
        "gear_down": [KEY_M, JOY_BUTTON_LEFT_SHOULDER],
        "clutch": [KEY_O, JOY_BUTTON_X],
        "engine_start": [KEY_E, JOY_BUTTON_START],
        "accelerate": [KEY_SPACE, JOY_BUTTON_A],
        "brake": [KEY_L, JOY_BUTTON_B],
        "steer_left": [KEY_Q, JOY_AXIS_LEFT_X],
        "steer_right": [KEY_D, -JOY_AXIS_LEFT_X],
        "turret_left": [KEY_LEFT, JOY_AXIS_RIGHT_X],
        "turret_right": [KEY_RIGHT, -JOY_AXIS_RIGHT_X],
        "ui_devtools_menu": [KEY_F1],
}

func _ready() -> void:
        set_process_unhandled_input(true)
        # --- Tente de recharger les bindings personnalisés ---
        load_bindings()
        _ensure_default_bindings()

        # === Key non reconnues pour l'instant ===
        #_ensure_action("gear_up",   [KEY_KP_ADD, JOY_BUTTON_RIGHT_SHOULDER])   # Pavé num + / R1
        #_ensure_action("gear_down", [KEY_KP_ENTER, JOY_BUTTON_LEFT_SHOULDER])  # Pavé num Entrée / L1
        #_ensure_action("clutch",    [KEY_KP_0, JOY_BUTTON_X])                  # Pavé num 0 / X

        # === Transmission ===
        _ensure_action("gear_up", DEFAULT_BINDINGS["gear_up"])    # Pavé num + / R1
        _ensure_action("gear_down", DEFAULT_BINDINGS["gear_down"])   # Pavé num Entrée / L1
        _ensure_action("clutch", DEFAULT_BINDINGS["clutch"])                  # Pavé num 0 / X

        # === Conduite du tank ===
        _ensure_action("engine_start", DEFAULT_BINDINGS["engine_start"])
        _ensure_action("accelerate", DEFAULT_BINDINGS["accelerate"])
        _ensure_action("brake", DEFAULT_BINDINGS["brake"])
        _ensure_action("steer_left", DEFAULT_BINDINGS["steer_left"])                # axe analogique gauche
        _ensure_action("steer_right", DEFAULT_BINDINGS["steer_right"])               # axe analogique gauche inversé

        # === Tourelle ===
        _ensure_action("turret_left", DEFAULT_BINDINGS["turret_left"])
        _ensure_action("turret_right", DEFAULT_BINDINGS["turret_right"])

        # === Debug / Interface ===
        _ensure_action("ui_devtools_menu", DEFAULT_BINDINGS["ui_devtools_menu"])  # utilisé par DevTools


	print("🎮 [InputBootstrap] Bindings clavier/manette initiaux enregistrés.")
	print("🧩 [InputBootstrap] DevTools (F1) activé.")

	_actions_registered = true
	emit_signal("actions_ready")

	print("🎛️ [Debug] Actions disponibles:", InputMap.get_actions())
	for a in InputMap.get_actions():
		if a == "ui_devtools_menu":
			print("🎛️ [Debug] Action 'ui_devtools_menu' events:", InputMap.action_get_events(a))


		# --- Vérifie et recrée le binding F1 si vide ---
	var events := InputMap.action_get_events("ui_devtools_menu")
	if events.is_empty():
		var ev := InputEventKey.new()
		ev.keycode = KEY_F1
		InputMap.action_add_event("ui_devtools_menu", ev)
		print("🧩 [Hotfix] F1 rebind → ui_devtools_menu")


func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey:
		print("⌨️ Key pressed:", OS.get_keycode_string(event.keycode), "handled=", event.is_action_pressed("ui_devtools_menu"))

	if not _actions_registered:
		return
	if event.is_action_pressed("ui_devtools_menu"):
		print("🎛️ [TEST] F1 capté par InputBootstrap")
		emit_signal("devtools_toggle_requested")
		get_viewport().set_input_as_handled()

func await_ready() -> void:
	if _actions_registered:
		return
	await actions_ready

func is_ready() -> bool:
	return _actions_registered

# ------------------------------------------------------------
# Enregistre ou met à jour une action d'entrée donnée.
# Détecte automatiquement le type (touche, bouton ou axe).
# ------------------------------------------------------------
func _ensure_default_bindings() -> void:
        for action_name in DEFAULT_BINDINGS.keys():
                _ensure_action(action_name, DEFAULT_BINDINGS[action_name])

func _ensure_action(action_name: String, inputs: Array, force_defaults: bool = false) -> void:
        if not InputMap.has_action(action_name):
                InputMap.add_action(action_name)

        var existing_events: Array = InputMap.action_get_events(action_name)
        if force_defaults:
                InputMap.action_erase_events(action_name)
                existing_events.clear()

        if not force_defaults and not existing_events.is_empty():
                return

        for input in inputs:
                if input == 0:
                        continue

                var ev: InputEvent = _event_from_input(input)
                if ev == null:
                        continue
                if force_defaults or not _has_event(action_name, ev):
                        InputMap.action_add_event(action_name, ev)

func _event_from_input(input: int) -> InputEvent:
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
        return ev


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

        if save_bindings():
                print("🎛️ [InputBootstrap] Bindings sauvegardés après remap.")

# ------------------------------------------------------------
# SAUVEGARDE ET CHARGEMENT DES BINDINGS UTILISATEUR
# ------------------------------------------------------------

# Sauvegarde tous les bindings actuels dans un fichier JSON
func save_bindings() -> bool:
        var data: Dictionary = {}
        for action in InputMap.get_actions():
                var events: Array = []
                for ev in InputMap.action_get_events(action):
                        var entry := _serialize_event(ev)
                        if entry.is_empty():
                                continue
                        events.append(entry)
                data[action] = events

        var file := FileAccess.open(BINDINGS_PATH, FileAccess.WRITE)
        if file == null:
                push_warning("[InputBootstrap] Impossible d’écrire dans " + BINDINGS_PATH)
                return false

        file.store_string(JSON.stringify(data, "\t"))  # indenté pour lisibilité
        file.close()
        print("💾 [InputBootstrap] Bindings sauvegardés dans", BINDINGS_PATH)
        return true

func _serialize_event(ev: InputEvent) -> Dictionary:
        var entry: Dictionary = {}
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
        return entry


# Recharge les bindings depuis le fichier JSON s’il existe
# ------------------------------------------------------------
# Recharge les bindings depuis le fichier JSON s’il existe,
# sans jamais casser les contrôles par défaut.
# ------------------------------------------------------------
func load_bindings() -> void:
        if not FileAccess.file_exists(BINDINGS_PATH):
                print("📁 [InputBootstrap] Aucun fichier de bindings trouvé — valeurs par défaut conservées.")
                return

        var file := FileAccess.open(BINDINGS_PATH, FileAccess.READ)
        if not file:
                push_warning("[InputBootstrap] Échec de lecture du fichier " + BINDINGS_PATH)
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
# Restaure les bindings par défaut pour une action précise
# ------------------------------------------------------------
func restore_default_binding(action_name: String) -> bool:
        if not DEFAULT_BINDINGS.has(action_name):
                push_warning("[InputBootstrap] Aucun binding par défaut pour '%s'." % action_name)
                return false
        _ensure_action(action_name, DEFAULT_BINDINGS[action_name], true)
        print("🧩 [InputBootstrap] Action '%s' réinitialisée sur les valeurs par défaut." % action_name)
        return true

# ------------------------------------------------------------
# AUTO-RÉPARATION DES BINDINGS
# Compare les actions actuelles à celles attendues par défaut
# et recrée celles qui manquent ou sont vides.
# ------------------------------------------------------------
func repair_missing_bindings() -> void:
        for action_name in DEFAULT_BINDINGS.keys():
                if not InputMap.has_action(action_name):
                        print("🧩 [InputBootstrap] Action manquante '%s' recréée." % action_name)
                        _ensure_action(action_name, DEFAULT_BINDINGS[action_name])
                        continue

                var events := InputMap.action_get_events(action_name)
                if events.is_empty():
                        print("🧩 [InputBootstrap] Action '%s' vide — réinitialisée." % action_name)
                        _ensure_action(action_name, DEFAULT_BINDINGS[action_name])

        print("🔧 [InputBootstrap] Vérification et réparation des bindings terminée.")
