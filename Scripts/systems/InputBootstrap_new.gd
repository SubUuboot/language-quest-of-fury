# ================================================
# 🧭 INPUT BOOTSTRAP — SAVE/LOAD SYSTEM (PATCH v2.2)
# ================================================
# This script adds human-readable key labels to your input bindings file.
# Ce script ajoute des labels lisibles pour les humains dans le fichier JSON des touches.
# It preserves full backward compatibility with your previous JSON structure.
# Il reste rétrocompatible avec le format précédent.
# ================================================

extends Node

const BINDINGS_PATH: String = "user://input_bindings.json"

# Called on startup — load existing bindings if any
func _ready() -> void:
	_load_bindings()


# ================================================
# 🔹 SAVE CURRENT INPUT MAP TO JSON FILE
# ================================================
# Saves all InputMap actions into a readable JSON file with labels.
# Sauvegarde toutes les actions InputMap dans un JSON lisible avec les labels.
func save_bindings() -> void:
	var config: Dictionary = {}

	for action_name in InputMap.get_actions():
		var events: Array = []
		for e in InputMap.action_get_events(action_name):
			if e is InputEventKey:
				var label: String = OS.get_keycode_string(e.keycode)
				events.append({
					"type": "key",
					"keycode": e.keycode,
					"label": label
				})
			elif e is InputEventJoypadButton:
				events.append({
					"type": "joypad_button",
					"button_index": e.button_index,
					"label": "Joy Button %d" % e.button_index
				})
			elif e is InputEventJoypadMotion:
				events.append({
					"type": "joypad_axis",
					"axis": e.axis,
					"axis_value": e.axis_value,
					"label": "Joy Axis %d (%.1f)" % [e.axis, e.axis_value]
				})
			else:
				# Other input types (mouse, touch, etc.)
				events.append({
					"type": e.get_class(),
					"label": e.as_text()
				})

		config[action_name] = events

	var file := FileAccess.open(BINDINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(config)
		file.close()
		print("✅ Bindings saved to:", BINDINGS_PATH)
	else:
		push_error("[InputBootstrap] Failed to open file for writing at %s" % BINDINGS_PATH)


# ================================================
# 🔹 LOAD INPUT MAP FROM JSON FILE
# ================================================
# Loads previously saved bindings and applies them to the InputMap.
# Charge les bindings sauvegardés et les applique dans l'InputMap.
func _load_bindings() -> void:
	if not FileAccess.file_exists(BINDINGS_PATH):
		print("ℹ️ No bindings file found, using default InputMap.")
		return

	var file := FileAccess.open(BINDINGS_PATH, FileAccess.READ)
	if file == null:
		push_error("[InputBootstrap] Failed to open bindings file.")
		return

	var config: Variant = file.get_var()
	file.close()

	if config is Dictionary:
		for action_name in config.keys():
			InputMap.action_erase_events(action_name)
			for ev_dict in config[action_name]:
				var ev: InputEvent = null

				match ev_dict.get("type", ""):
					"key":
						var ev_key := InputEventKey.new()
						ev_key.keycode = ev_dict.get("keycode", 0)
						ev = ev_key
					"joypad_button":
						var ev_button := InputEventJoypadButton.new()
						ev_button.button_index = ev_dict.get("button_index", 0)
						ev = ev_button
					"joypad_axis":
						var ev_axis := InputEventJoypadMotion.new()
						ev_axis.axis = ev_dict.get("axis", 0)
						ev_axis.axis_value = ev_dict.get("axis_value", 0.0)
						ev = ev_axis
					_:
						# TODO: Handle mouse or other custom input events if needed
						pass

				if ev:
					InputMap.action_add_event(action_name, ev)

		print("✅ Bindings loaded successfully from:", BINDINGS_PATH)
	else:
		push_warning("[InputBootstrap] Invalid bindings format in file.")
