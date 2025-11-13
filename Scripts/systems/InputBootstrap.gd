# ================================================
# 🧭 INPUT BOOTSTRAP — SAVE/LOAD SYSTEM (PATCH v2.2)
# ================================================
# This script should adds human-readable key labels to your input bindings file in the future.
# Ce script ajoute des labels lisibles pour les humains dans le fichier JSON des touches.
# It preserves full backward compatibility with your previous JSON structure.
# Il reste rétrocompatible avec le format précédent.
# ================================================

extends Node

signal actions_ready
signal devtools_toggle_requested

var _actions_registered: bool = false

const BINDINGS_PATH: String = "user://input_bindings.json"

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
                entry["type"] = "joypad_button"
                entry["button_index"] = ev.button_index
        elif ev is InputEventJoypadMotion:
                entry["type"] = "joy_axis"
                entry["axis"] = ev.axis
                entry["axis_value"] = ev.axis_value
        return entry


# ================================================
# 🔹 LOAD INPUT MAP FROM JSON FILE
# ================================================
# Loads previously saved bindings and applies them to the InputMap.
# Charge les bindings sauvegardés et les applique dans l'InputMap.
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

	# On supporte 2 formats:
	# 1) Ancien format binaire (store_var)
	# 2) Nouveau format JSON lisible (store_string)
	var config: Dictionary = {}
	var ok: bool = false

	# Tentative 1: lecture binaire (store_var)
	file.seek(0)
	var bin_try: Variant = file.get_var(true)  # allow_objects = true au cas où
	if typeof(bin_try) == TYPE_DICTIONARY:
		config = bin_try as Dictionary
		ok = true
	else:
		# Tentative 2: JSON texte
		file.seek(0)
		var text: String = file.get_as_text()

		# Option A: parse statique
		var parsed_any: Variant = JSON.parse_string(text)
		if typeof(parsed_any) == TYPE_DICTIONARY:
			config = parsed_any as Dictionary
			ok = true
		else:
			# Option B: parseur objet, pour logs plus précis
			var json := JSON.new()
			var parse_err: Error = json.parse(text)
			if parse_err == OK:
				var data_any: Variant = json.get_data()
				if typeof(data_any) == TYPE_DICTIONARY:
					config = data_any as Dictionary
					ok = true

	file.close()

	if not ok:
		push_warning("[InputBootstrap] Format de bindings invalide dans le fichier.")
		return

	# Applique proprement les événements
	for action_name_any in config.keys():
		var action_name: String = String(action_name_any)
		InputMap.action_erase_events(action_name)

		var events_any: Variant = config[action_name]
		var events_list: Array = (events_any as Array)

		for ev_any in events_list:
			var ev_dict: Dictionary = (ev_any as Dictionary)
			var ev_type_any: Variant = ev_dict.get("type", "")
			var ev_type: String = String(ev_type_any)

			var ev: InputEvent = null
			match ev_type:
				"key":
					var ev_key := InputEventKey.new()
					ev_key.keycode = int(ev_dict.get("keycode", 0))
					ev = ev_key
				"joypad_button":
					var ev_button := InputEventJoypadButton.new()
					ev_button.button_index = int(ev_dict.get("button_index", 0))
					ev = ev_button
				"joypad_axis":
					var ev_axis := InputEventJoypadMotion.new()
					ev_axis.axis = int(ev_dict.get("axis", 0))
					ev_axis.axis_value = float(ev_dict.get("axis_value", 0.0))
					ev = ev_axis
				_:
					# TODO/À FAIRE: gérer souris / autres types si tu les sauvegardes un jour
					pass

			if ev != null:
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
