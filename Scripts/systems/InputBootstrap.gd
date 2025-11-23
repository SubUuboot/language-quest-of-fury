# ================================================
# 🧭 INPUT BOOTSTRAP — SAVE/LOAD SYSTEM (PATCH v2.2)
# ================================================
# This script should add human-readable key labels to your input bindings file in the future.
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

func _ready() -> void:
	set_process_unhandled_input(true)
	_load_defaults()
	_load_user()
	_build_effective_map()
	_apply_effective_map()
	_actions_loaded = true
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
