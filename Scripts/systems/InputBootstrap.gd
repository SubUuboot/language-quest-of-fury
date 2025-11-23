# ================================================
# 🧭 INPUT BOOTSTRAP — SAVE/LOAD SYSTEM (PATCH v2.2)
# ================================================
<<<<<<< Updated upstream
# This script should adds human-readable key labels to your input bindings file in the future.
=======
# This script should add human-readable key labels to your input bindings file in the future.
>>>>>>> Stashed changes
# Ce script ajoute des labels lisibles pour les humains dans le fichier JSON des touches.
# It preserves full backward compatibility with your previous JSON structure.
# Il reste rétrocompatible avec le format précédent.
# ================================================
extends Node


signal actions_ready
signal devtools_toggle_requested

const DEFAULT_PATH := "res://Configs/default_bindings.json"
const USER_PATH := "user://user_bindings.json"

var _actions_loaded: bool = false
var _defaults: Dictionary = {}
var _user: Dictionary = {}
var _effective: Dictionary = {}

<<<<<<< Updated upstream
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
=======
func _ready() -> void:
	set_process_unhandled_input(true)
	_load_defaults()
	_load_user()
	_build_effective_map()
	_apply_effective_map()
	_actions_loaded = true
>>>>>>> Stashed changes
	emit_signal("actions_ready")
	print("🎮 [InputBootstrap] Input map ready.")
	print("🔥 Actions dans l’InputMap :", InputMap.get_actions())
	debug_action("ui_devtools_menu")
	debug_action("accelerate")
	debug_action("steer_left")
	debug_action("gear_up")



# ======================================================================
# LOAD DEFAULTS / USER
# ======================================================================

func _load_defaults() -> void:
	_defaults.clear()
	if not FileAccess.file_exists(DEFAULT_PATH):
		push_error("[InputBootstrap] Missing default bindings JSON at " + DEFAULT_PATH)
		return

	var file := FileAccess.open(DEFAULT_PATH, FileAccess.READ)
	if file == null:
		push_error("[InputBootstrap] Failed reading default bindings.")
		return

	var text := file.get_as_text()
	file.close()

	var parsed : Dictionary = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[InputBootstrap] Invalid JSON format in default bindings.")
		return

	_defaults = parsed


func _load_user() -> void:
	_user.clear()

	if not FileAccess.file_exists(USER_PATH):
		return

	var file := FileAccess.open(USER_PATH, FileAccess.READ)
	if file == null:
		push_warning("[InputBootstrap] Failed to open user bindings.")
		return

	var text := file.get_as_text()
	file.close()

	var parsed : Dictionary = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[InputBootstrap] User bindings corrupted, ignoring.")
		return

	_user = parsed


# ======================================================================
# MERGE
# ======================================================================

func _build_effective_map() -> void:
	_effective.clear()

	# Start from defaults
	for key in _defaults.keys():
		_effective[key] = _clone_array(_defaults[key])

	# Apply User overrides
	for key in _user.keys():
		_effective[key] = _clone_array(_user[key])


func _clone_array(arr: Array) -> Array:
	var out: Array = []
	for a in arr:
		out.append(a.duplicate(true))
	return out


# ======================================================================
# APPLY TO INPUTMAP
# ======================================================================

func _apply_effective_map() -> void:
	for action in InputMap.get_actions():
		InputMap.erase_action(action)

	for key in _effective.keys():
		InputMap.add_action(key)
		for ev_dict in _effective[key]:
			var ev := _deserialize_event(ev_dict)
			if ev != null:
				InputMap.action_add_event(key, ev)

	print("🎛️ [InputBootstrap] Effective bindings applied.")


func _deserialize_event(d: Dictionary) -> InputEvent:
	var t := String(d.get("type", ""))

	match t:
		"key":
			var e := InputEventKey.new()
			e.keycode = int(d.get("keycode", 0))
			return e
		"joypad_button":
			var e := InputEventJoypadButton.new()
			e.button_index = int(d.get("button_index", 0))
			return e
		"joy_axis":
			var e := InputEventJoypadMotion.new()
			e.axis = int(d.get("axis", 0))
			e.axis_value = float(d.get("axis_value", 0.0))
			return e
		_:
			return null


# ======================================================================
# SAVE USER BINDINGS
# ======================================================================

func save_user_bindings() -> bool:
	var file := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[InputBootstrap] Cannot write user bindings.")
		return false

	var json := JSON.stringify(_user, "\t")
	file.store_string(json)
	file.close()

	print("💾 [InputBootstrap] User bindings saved.")
	return true


# ======================================================================
# REMAP / RESET
# ======================================================================

func remap_action(action_name: String, ev: InputEvent) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, ev)

	_user[action_name] = [_serialize_event(ev)]
	_build_effective_map()
	save_user_bindings()


func reset_action(action_name: String) -> void:
	if _user.has(action_name):
		_user.erase(action_name)
		save_user_bindings()

	_build_effective_map()
	_apply_effective_map()


func reset_all() -> void:

	if FileAccess.file_exists(USER_PATH):
		var err: int = DirAccess.remove_absolute(USER_PATH)
		if err != OK:
			push_warning("[InputBootstrap] Failed to delete %s (err=%d)" % [USER_PATH, err])


	_user.clear()
	_build_effective_map()
	_apply_effective_map()


# ======================================================================
# SERIALIZATION
# ======================================================================

func _serialize_event(ev: InputEvent) -> Dictionary:
	var out: Dictionary = {}

	if ev is InputEventKey:
		out["type"] = "key"
		out["keycode"] = ev.keycode
	elif ev is InputEventJoypadButton:
		out["type"] = "joypad_button"
		out["button_index"] = ev.button_index
	elif ev is InputEventJoypadMotion:
		out["type"] = "joy_axis"
		out["axis"] = ev.axis
		out["axis_value"] = ev.axis_value

	return out


	# ======================================================================
	# TEST DEBUG
	# ======================================================================

func debug_action(name: String) -> void:
	print("🔍 Action:", name)
	print("  exists:", InputMap.has_action(name))
	print("  events:", InputMap.action_get_events(name))

# ======================================================================
# READY WAITER
# ======================================================================

func await_ready() -> void:
	if _actions_loaded:
		return
	await actions_ready
<<<<<<< Updated upstream

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
=======
>>>>>>> Stashed changes
