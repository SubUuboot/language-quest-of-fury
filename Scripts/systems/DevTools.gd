@tool

extends Control
class_name DevTools

signal devtools_toggled(is_open: bool)

const MAX_SIGNAL_HISTORY: int = 20
const SANDBOX_STAGE_KEYWORDS: Array[String] = ["sandbox", "debug", "test"]

var is_open: bool = false
var _sandbox_enabled: bool = false
var _sandbox_allowed: bool = false
var _current_stage_name: String = ""
var _listening_action: StringName = &""
var _mechanics_controls: Array[Dictionary] = []
var _signal_history: Array[String] = []
var _default_tank_params: Dictionary = {}
var _last_metrics_refresh: float = 0.0

var _tank: TankController2D = null
var _input_bootstrap: Node = null
var _stage_manager: Node = null
var _mother_ai: Node = null

@onready var _debug_menu: Control = %DebugMenu
@onready var _toggle_button: Button = %ToggleButton
@onready var _tabs_container: TabContainer = %TabsContainer
@onready var _sandbox_toggle: CheckButton = %SandboxToggle
@onready var _sandbox_status: Label = %SandboxStatus
@onready var _mechanics_status: Label = %MechanicsStatus
@onready var _reset_mechanics_button: Button = %ResetMechanicsButton
@onready var _use_engine_stall_toggle: CheckButton = %UseEngineStallToggle
@onready var _slider_track_accel: HSlider = %TrackAccelSlider
@onready var _slider_max_track_speed: HSlider = %MaxTrackSpeedSlider
@onready var _slider_rotation_gain: HSlider = %RotationGainSlider
@onready var _slider_friction: HSlider = %FrictionSlider
@onready var _slider_brake_power: HSlider = %BrakePowerSlider
@onready var _slider_visual_speed: HSlider = %VisualSpeedSlider
@onready var _slider_engine_idle: HSlider = %EngineIdleSlider
@onready var _slider_engine_max: HSlider = %EngineMaxSlider
@onready var _slider_throttle_gain: HSlider = %ThrottleGainSlider
@onready var _slider_rpm_decay: HSlider = %RpmDecaySlider
@onready var _slider_torque: HSlider = %TorqueSlider
@onready var _label_track_accel: Label = %TrackAccelValue
@onready var _label_max_track_speed: Label = %MaxTrackSpeedValue
@onready var _label_rotation_gain: Label = %RotationGainValue
@onready var _label_friction: Label = %FrictionValue
@onready var _label_brake_power: Label = %BrakePowerValue
@onready var _label_visual_speed: Label = %VisualSpeedValue
@onready var _label_engine_idle: Label = %EngineIdleValue
@onready var _label_engine_max: Label = %EngineMaxValue
@onready var _label_throttle_gain: Label = %ThrottleGainValue
@onready var _label_rpm_decay: Label = %RpmDecayValue
@onready var _label_torque: Label = %TorqueValue
@onready var _input_action_selector: OptionButton = %ActionSelector
@onready var _listen_button: Button = %ListenButton
@onready var _clear_button: Button = %ClearBindingButton
@onready var _reset_button: Button = %ResetBindingButton
@onready var _binding_status: Label = %BindingStatusLabel
@onready var _binding_details: RichTextLabel = %BindingDetails
@onready var _debug_tabs: TabContainer = %DebugTabs
@onready var _physics_info: RichTextLabel = %PhysicsInfo
@onready var _dialogue_info: RichTextLabel = %DialogueInfo
@onready var _signals_info: RichTextLabel = %SignalsInfo
@onready var _mother_ai_info: RichTextLabel = %MotherAIInfo
@onready var _log_console: RichTextLabel = %LogConsole
@onready var _metrics_overlay: Label = %MetricsOverlay

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return

	visible = false
	is_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sandbox_enabled = false
	_sandbox_allowed = OS.is_debug_build()

	_setup_ui()
	await _hook_input_bootstrap()
	_collect_stage_manager()
	await _collect_tank()
	_collect_mother_ai()
	_setup_mechanics_controls()
	_populate_action_selector()
	_connect_signals()
	_update_stage_lock()
	_update_sandbox_status()

	set_process(true)
	set_process_unhandled_input(true)
	print("🧩 DevTools prêt — appuyez sur F1 pour ouvrir/fermer.")

func _setup_ui() -> void:
	focus_mode = Control.FOCUS_ALL
	if _toggle_button and not _toggle_button.is_connected("pressed", Callable(self, "_on_toggle_button_pressed")):
		_toggle_button.pressed.connect(Callable(self, "_on_toggle_button_pressed"))
	if _sandbox_toggle and not _sandbox_toggle.is_connected("toggled", Callable(self, "_on_sandbox_toggled")):
		_sandbox_toggle.toggled.connect(Callable(self, "_on_sandbox_toggled"))
	if _reset_mechanics_button and not _reset_mechanics_button.is_connected("pressed", Callable(self, "_on_reset_mechanics_pressed")):
		_reset_mechanics_button.pressed.connect(Callable(self, "_on_reset_mechanics_pressed"))
	if _use_engine_stall_toggle and not _use_engine_stall_toggle.is_connected("toggled", Callable(self, "_on_use_engine_stall_toggled")):
		_use_engine_stall_toggle.toggled.connect(Callable(self, "_on_use_engine_stall_toggled"))
	if _input_action_selector and not _input_action_selector.is_connected("item_selected", Callable(self, "_on_action_selected")):
		_input_action_selector.item_selected.connect(Callable(self, "_on_action_selected"))
	if _listen_button and not _listen_button.is_connected("pressed", Callable(self, "_on_listen_button_pressed")):
		_listen_button.pressed.connect(Callable(self, "_on_listen_button_pressed"))
	if _clear_button and not _clear_button.is_connected("pressed", Callable(self, "_on_clear_binding_pressed")):
		_clear_button.pressed.connect(Callable(self, "_on_clear_binding_pressed"))
	if _reset_button and not _reset_button.is_connected("pressed", Callable(self, "_on_reset_binding_pressed")):
		_reset_button.pressed.connect(Callable(self, "_on_reset_binding_pressed"))

func _hook_input_bootstrap() -> void:
	var bootstrap: Node = get_tree().root.get_node_or_null("InputBootstrap")
	while bootstrap == null:
		await get_tree().process_frame
		bootstrap = get_tree().root.get_node_or_null("InputBootstrap")

	_input_bootstrap = bootstrap
	if bootstrap.has_method("await_ready"):
		await bootstrap.await_ready()

	var toggle_callable: Callable = Callable(self, "_on_devtools_toggle_requested")
	if bootstrap.has_signal("devtools_toggle_requested") and not bootstrap.is_connected("devtools_toggle_requested", toggle_callable):
		bootstrap.connect("devtools_toggle_requested", toggle_callable)
	var actions_callable: Callable = Callable(self, "_on_input_actions_ready")
	if bootstrap.has_signal("actions_ready") and not bootstrap.is_connected("actions_ready", actions_callable):
		bootstrap.connect("actions_ready", actions_callable)

func _collect_stage_manager() -> void:
	var root: Node = get_tree().root
	if root.has_node("Game/StageManager"):
		_stage_manager = root.get_node("Game/StageManager")
	elif root.has_node("StageManager"):
		_stage_manager = root.get_node("StageManager")
	if _stage_manager and _stage_manager.has_variable("current_stage_name"):
		_current_stage_name = _stage_manager.current_stage_name

func _collect_mother_ai() -> void:
	if Engine.has_singleton("MotherAI"):
		_mother_ai = Engine.get_singleton("MotherAI")
	elif get_tree().root.has_node("Game/MotherAI"):
		_mother_ai = get_tree().root.get_node("Game/MotherAI")

func _collect_tank() -> void:
	var attempts: int = 0
	while _tank == null and attempts < 240:
		var tanks: Array = get_tree().get_nodes_in_group("tank")
		if tanks.size() > 0:
			_tank = tanks[0] as TankController2D
		if _tank == null:
			await get_tree().process_frame
			attempts += 1
	if _tank:
		_default_tank_params = _capture_tank_defaults()

func _connect_signals() -> void:
	if _tank:
		var gear_callable: Callable = Callable(self, "_on_tank_gear_changed")
		if not _tank.is_connected("gear_changed", gear_callable):
			_tank.connect("gear_changed", gear_callable)
		var move_callable: Callable = Callable(self, "_on_tank_moved")
		if not _tank.is_connected("moved", move_callable):
			_tank.connect("moved", move_callable)
		var action_callable: Callable = Callable(self, "_on_tank_action")
		if not _tank.is_connected("action_performed", action_callable):
			_tank.connect("action_performed", action_callable)
		if not _tank.is_connected("tree_exited", Callable(self, "_on_tank_tree_exited")):
			_tank.tree_exited.connect(Callable(self, "_on_tank_tree_exited"))
	if _stage_manager:
		var loaded_callable: Callable = Callable(self, "_on_stage_loaded")
		if _stage_manager.has_signal("stage_loaded") and not _stage_manager.is_connected("stage_loaded", loaded_callable):
			_stage_manager.connect("stage_loaded", loaded_callable)
		var unloaded_callable: Callable = Callable(self, "_on_stage_unloaded")
		if _stage_manager.has_signal("stage_unloaded") and not _stage_manager.is_connected("stage_unloaded", unloaded_callable):
			_stage_manager.connect("stage_unloaded", unloaded_callable)
		var completed_callable: Callable = Callable(self, "_on_stage_completed")
		if _stage_manager.has_signal("stage_completed") and not _stage_manager.is_connected("stage_completed", completed_callable):
			_stage_manager.connect("stage_completed", completed_callable)
	if _mother_ai:
		var task_start_callable: Callable = Callable(self, "_on_mother_ai_task_started")
		if _mother_ai.has_signal("task_started") and not _mother_ai.is_connected("task_started", task_start_callable):
			_mother_ai.connect("task_started", task_start_callable)
		var task_complete_callable: Callable = Callable(self, "_on_mother_ai_task_completed")
		if _mother_ai.has_signal("task_completed") and not _mother_ai.is_connected("task_completed", task_complete_callable):
			_mother_ai.connect("task_completed", task_complete_callable)
		var log_callable: Callable = Callable(self, "_on_mother_ai_log_updated")
		if _mother_ai.has_signal("log_updated") and not _mother_ai.is_connected("log_updated", log_callable):
			_mother_ai.connect("log_updated", log_callable)

func _setup_mechanics_controls() -> void:
	_mechanics_controls.clear()
	if _tank == null:
		return
	_register_mechanic_control("track_accel", _slider_track_accel, _label_track_accel, "%.2f")
	_register_mechanic_control("max_track_speed", _slider_max_track_speed, _label_max_track_speed, "%.2f")
	_register_mechanic_control("rotation_gain", _slider_rotation_gain, _label_rotation_gain, "%.2f")
	_register_mechanic_control("friction", _slider_friction, _label_friction, "%.2f")
	_register_mechanic_control("brake_power", _slider_brake_power, _label_brake_power, "%.2f")
	_register_mechanic_control("visual_speed_factor", _slider_visual_speed, _label_visual_speed, "%.0f")
	_register_mechanic_control("engine_idle_rpm", _slider_engine_idle, _label_engine_idle, "%.0f")
	_register_mechanic_control("engine_max_rpm", _slider_engine_max, _label_engine_max, "%.0f")
	_register_mechanic_control("engine_throttle_rpm_gain", _slider_throttle_gain, _label_throttle_gain, "%.0f")
	_register_mechanic_control("engine_rpm_decay", _slider_rpm_decay, _label_rpm_decay, "%.0f")
	_register_mechanic_control("engine_torque_max", _slider_torque, _label_torque, "%.0f")
	_sync_mechanics_from_tank()

func _register_mechanic_control(property_name: String, slider: HSlider, label: Label, format: String) -> void:
	if slider == null:
		return
	slider.value_changed.connect(Callable(self, "_on_mechanic_slider_value_changed").bind(property_name, label, format))
	var entry: Dictionary = {
		"property": property_name,
		"slider": slider,
		"label": label,
		"format": format
	}
	_mechanics_controls.append(entry)

func _sync_mechanics_from_tank() -> void:
	if _tank == null:
		return
	for entry in _mechanics_controls:
		var property_name: String = entry["property"]
		var slider: HSlider = entry["slider"]
		var label: Label = entry["label"]
		var format: String = entry["format"]
		if slider:
			slider.set_block_signals(true)
			slider.value = _tank.get(property_name)
			slider.set_block_signals(false)
		if label:
			label.text = format % slider.value
	if _use_engine_stall_toggle:
		_use_engine_stall_toggle.set_block_signals(true)
		_use_engine_stall_toggle.button_pressed = _tank.use_engine_stall
		_use_engine_stall_toggle.set_block_signals(false)

func _capture_tank_defaults() -> Dictionary:
	var defaults: Dictionary = {}
	defaults["track_accel"] = _tank.track_accel
	defaults["max_track_speed"] = _tank.max_track_speed
	defaults["rotation_gain"] = _tank.rotation_gain
	defaults["friction"] = _tank.friction
	defaults["brake_power"] = _tank.brake_power
	defaults["visual_speed_factor"] = _tank.visual_speed_factor
	defaults["engine_idle_rpm"] = _tank.engine_idle_rpm
	defaults["engine_max_rpm"] = _tank.engine_max_rpm
	defaults["engine_throttle_rpm_gain"] = _tank.engine_throttle_rpm_gain
	defaults["engine_rpm_decay"] = _tank.engine_rpm_decay
	defaults["engine_torque_max"] = _tank.engine_torque_max
	defaults["use_engine_stall"] = _tank.use_engine_stall
	return defaults

func _on_mechanic_slider_value_changed(value: float, property_name: String, label: Label, format: String) -> void:
	if label:
		label.text = format % value
	_apply_mechanic_value(property_name, value)

func _apply_mechanic_value(property_name: String, value: float) -> void:
	if _tank == null:
		return
	if not _sandbox_enabled:
		_mechanics_status.text = "Sandbox disabled — live values restored."
		_sync_mechanics_from_tank()
		return
	_tank.set(property_name, value)
	_mechanics_status.text = "%s = %s" % [property_name, String.num(value, 2)]

func _restore_tank_defaults() -> void:
	if _tank == null or _default_tank_params.is_empty():
		return
	for key in _default_tank_params.keys():
		if key == "use_engine_stall":
			_tank.use_engine_stall = _default_tank_params[key]
		else:
			_tank.set(key, _default_tank_params[key])
	_sync_mechanics_from_tank()
	_mechanics_status.text = "Tank parameters restored."

func _populate_action_selector() -> void:
	if _input_action_selector == null:
		return
	_input_action_selector.clear()
	var actions: PackedStringArray = InputMap.get_actions()
	actions.sort()
	for action_name in actions:
		_input_action_selector.add_item(action_name)
	if actions.size() > 0:
		_input_action_selector.select(0)
		_refresh_binding_display(actions[0])

func _on_input_actions_ready() -> void:
	_populate_action_selector()

func _on_action_selected(index: int) -> void:
	var action_name: String = _get_selected_action()
	_refresh_binding_display(action_name)

func _on_listen_button_pressed() -> void:
	if not _sandbox_enabled:
		_binding_status.text = "Sandbox disabled — cannot listen."
		return
	var action_name: String = _get_selected_action()
	if action_name == "":
		_binding_status.text = "No action selected."
		return
	_listening_action = action_name
	_binding_status.text = "Listening for new input on %s..." % action_name

func _on_clear_binding_pressed() -> void:
	if not _sandbox_enabled:
		_binding_status.text = "Sandbox disabled — bindings unchanged."
		return
	var action_name: String = _get_selected_action()
	if action_name == "":
		return
	InputMap.action_erase_events(action_name)
	_save_bindings()
	_binding_status.text = "Cleared binding for %s." % action_name
	_refresh_binding_display(action_name)

func _on_reset_binding_pressed() -> void:
	if not _sandbox_enabled:
		_binding_status.text = "Sandbox disabled — defaults locked."
		return
	if _input_bootstrap and _input_bootstrap.has_method("repair_missing_bindings"):
		_input_bootstrap.repair_missing_bindings()
	var action_name: String = _get_selected_action()
	_refresh_binding_display(action_name)
	_binding_status.text = "Restored defaults."

func _save_bindings() -> void:
	if _input_bootstrap and _input_bootstrap.has_method("save_bindings"):
		_input_bootstrap.save_bindings()

func _get_selected_action() -> String:
	if _input_action_selector == null or _input_action_selector.item_count == 0:
		return ""
	var index: int = _input_action_selector.get_selected_id()
	if index < 0:
		index = 0
	return _input_action_selector.get_item_text(index)

func _refresh_binding_display(action_name: String) -> void:
	if _binding_details == null or action_name == "":
		return
	var events: Array = InputMap.action_get_events(action_name)
	if events.is_empty():
		_binding_details.text = "[i]No bindings assigned.[/i]"
	else:
		var lines: Array[String] = []
		for ev in events:
			lines.append("• %s" % _format_input_event(ev))
		_binding_details.text = "\n".join(lines)
	_binding_status.text = "Bindings listed for %s." % action_name

func _format_input_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		return OS.get_keycode_string(key_event.keycode)
	elif event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event
		return "Joy Button %d" % button_event.button_index
	elif event is InputEventJoypadMotion:
		var axis_event: InputEventJoypadMotion = event
		return "Joy Axis %d (%.1f)" % [axis_event.axis, axis_event.axis_value]
	return "Unknown"

func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == StringName():
		return
	var accepted: bool = false
	if event is InputEventKey:
		var key_event: InputEventKey = event
		accepted = key_event.pressed and not key_event.echo
	elif event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event
		accepted = button_event.pressed
	elif event is InputEventJoypadMotion:
		var axis_event: InputEventJoypadMotion = event
		accepted = absf(axis_event.axis_value) >= 0.5
	if not accepted:
		return
	var action_name: StringName = _listening_action
	_listening_action = &""
	var new_event: InputEvent = event.duplicate()
	if _input_bootstrap and _input_bootstrap.has_method("remap_action"):
		_input_bootstrap.remap_action(String(action_name), new_event)
	else:
		var action_text: String = String(action_name)
		InputMap.action_erase_events(action_text)
		InputMap.action_add_event(action_text, new_event)
		_save_bindings()
	_binding_status.text = "Assigned %s to %s." % [_format_input_event(new_event), action_name]
	_refresh_binding_display(String(action_name))
	get_viewport().set_input_as_handled()

func _on_sandbox_toggled(pressed: bool) -> void:
	if not _sandbox_allowed:
		_sandbox_toggle.set_block_signals(true)
		_sandbox_toggle.button_pressed = false
		_sandbox_toggle.set_block_signals(false)
		_update_sandbox_status("Sandbox locked — production build.")
		return
	if _sandbox_toggle.disabled:
		_sandbox_toggle.set_block_signals(true)
		_sandbox_toggle.button_pressed = false
		_sandbox_toggle.set_block_signals(false)
		_update_sandbox_status("Sandbox locked for stage %s." % _current_stage_name)
		return
	_sandbox_enabled = pressed
	if not _sandbox_enabled:
		_restore_tank_defaults()
	_update_sandbox_status()

func _update_stage_lock() -> void:
	if not _sandbox_allowed:
		if _sandbox_toggle:
			_sandbox_toggle.disabled = true
			_sandbox_toggle.button_pressed = false
		_sandbox_enabled = false
		_restore_tank_defaults()
		return
	var stage_safe: bool = _is_sandbox_stage(_current_stage_name)
	if _sandbox_toggle:
		_sandbox_toggle.disabled = not stage_safe
	if not stage_safe:
		_sandbox_enabled = false
		if _sandbox_toggle:
			_sandbox_toggle.button_pressed = false
		_restore_tank_defaults()
		_update_sandbox_status("Sandbox locked for stage %s." % (_current_stage_name if _current_stage_name != "" else "(none)"))
	else:
		_update_sandbox_status()

func _is_sandbox_stage(stage_name: String) -> bool:
	if stage_name == "":
		return true
	var lower: String = stage_name.to_lower()
	for keyword in SANDBOX_STAGE_KEYWORDS:
		if lower.contains(keyword):
			return true
	return false

func _update_sandbox_status(message: String = "") -> void:
	var text: String = message
	if text == "":
		text = "Sandbox enabled — editing live values." if _sandbox_enabled else "Sandbox disabled — live values restored."
	if _sandbox_status:
		_sandbox_status.text = text

func _on_reset_mechanics_pressed() -> void:
	if _tank == null:
		return
	_default_tank_params = _capture_tank_defaults()
	_restore_tank_defaults()

func _on_use_engine_stall_toggled(pressed: bool) -> void:
	if _tank == null:
		return
	if not _sandbox_enabled:
		_use_engine_stall_toggle.set_block_signals(true)
		_use_engine_stall_toggle.button_pressed = _tank.use_engine_stall
		_use_engine_stall_toggle.set_block_signals(false)
		_mechanics_status.text = "Sandbox disabled — stall unchanged."
		return
	_tank.use_engine_stall = pressed
	_mechanics_status.text = "use_engine_stall = %s" % ("true" if pressed else "false")

func _on_devtools_toggle_requested() -> void:
	_toggle_menu()

func _on_toggle_button_pressed() -> void:
	_toggle_menu()

func _toggle_menu() -> void:
	is_open = not is_open
	if is_open:
		raise()
	visible = is_open
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	z_index = 1024 if is_open else 0
	if _debug_menu:
		if is_open:
			_debug_menu.raise()
		_debug_menu.visible = is_open
		_debug_menu.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
		_debug_menu.z_index = 1024 if is_open else 0
	if is_open:
		if has_focus():
			release_focus()
		get_viewport().gui_release_focus()
		grab_focus()
		if _debug_menu:
			_debug_menu.grab_focus()
		_refresh_binding_display(_get_selected_action())
	else:
		if has_focus():
			release_focus()
		get_viewport().gui_release_focus()
		if _debug_menu and _debug_menu.has_focus():
			_debug_menu.release_focus()
		_listening_action = &""
	emit_signal("devtools_toggled", is_open)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED)
	print("🎛️ DevTools toggled → Tank input_enabled =", not is_open)
	print("🧭 DevTools:" + ("ouvert" if is_open else "fermé"))

func _append_signal_entry(entry: String) -> void:
	var timestamp: String = Time.get_time_string_from_system()
	var line: String = "[%s] %s" % [timestamp, entry]
	_signal_history.append(line)
	if _signal_history.size() > MAX_SIGNAL_HISTORY:
		_signal_history.pop_front()
	if _signals_info:
		_signals_info.text = "\n".join(_signal_history)
	_log_to_console(line)

func _log_to_console(message: String) -> void:
	if _log_console:
		_log_console.append_text("\n" + message)
		_log_console.scroll_to_line(_log_console.get_line_count())

func _on_tank_gear_changed(gear: int) -> void:
	_append_signal_entry("Tank gear changed → %d" % gear)

func _on_tank_moved(direction: String) -> void:
	_append_signal_entry("Tank moved %s" % direction)

func _on_tank_action(action: String) -> void:
	_append_signal_entry("Tank action performed: %s" % action)

func _on_tank_tree_exited() -> void:
	_tank = null
	_append_signal_entry("Tank node exited scene tree.")
	await _collect_tank()
	_setup_mechanics_controls()
	_connect_signals()

func _on_stage_loaded(stage_name: String) -> void:
	_current_stage_name = stage_name
	_append_signal_entry("Stage loaded: %s" % stage_name)
	_update_stage_lock()

func _on_stage_unloaded(stage_name: String) -> void:
	_append_signal_entry("Stage unloaded: %s" % stage_name)
	_current_stage_name = ""
	_update_stage_lock()

func _on_stage_completed(stage_name: String) -> void:
	_append_signal_entry("Stage completed: %s" % stage_name)

func _on_mother_ai_task_started(scene_name: String, action_name: String) -> void:
	_append_signal_entry("MotherAI task started: %s/%s" % [scene_name, action_name])

func _on_mother_ai_task_completed(scene_name: String, action_name: String) -> void:
	_append_signal_entry("MotherAI task completed: %s/%s" % [scene_name, action_name])

func _on_mother_ai_log_updated(entry: String) -> void:
	_append_signal_entry("MotherAI log → %s" % entry)

func _process(delta: float) -> void:
	_update_physics_panel()
	_update_dialogue_panel()
	_update_mother_ai_panel()
	_last_metrics_refresh += delta
	if _last_metrics_refresh >= 0.25:
		_update_metrics_overlay()
		_last_metrics_refresh = 0.0

func _update_physics_panel() -> void:
	if _physics_info == null:
		return
	if _tank == null:
		_physics_info.text = "Tank not available."
		return
	var speed: float = _tank.velocity.length()
	var rpm: float = _tank.engine_rpm
	var gear: int = _tank.current_gear
	var clutch_text: String = "true" if _tank.clutch_pressed else "false"
	var input_text: String = "true" if _tank.input_enabled else "false"
	var stage_text: String = _current_stage_name if _current_stage_name != "" else "(none)"
	var lines: Array[String] = []
	lines.append("[b]Tank Physics[/b]")
	lines.append("Stage: %s" % stage_text)
	lines.append("Speed: %.2f" % speed)
	lines.append("Engine RPM: %.0f" % rpm)
	lines.append("Gear: %d" % gear)
	lines.append("Clutch: %s" % clutch_text)
	lines.append("Input Enabled: %s" % input_text)
	lines.append("Sandbox: %s" % ("ON" if _sandbox_enabled else "OFF"))
	_physics_info.text = "\n".join(lines)

func _update_dialogue_panel() -> void:
	if _dialogue_info == null:
		return
	if DialogueSystem.dialogues.is_empty():
		_dialogue_info.text = "Dialogue database not loaded."
		return
	var role_lines: Array[String] = []
	for role in DialogueSystem.dialogues.keys():
		var role_data: Variant = DialogueSystem.dialogues[role]
		var entry_total: int = 0
		if role_data is Dictionary:
			var dict_data: Dictionary = role_data
			for key in dict_data.keys():
				var value: Variant = dict_data[key]
				if value is Array:
					entry_total += (value as Array).size()
		role_lines.append("%s → %d entries" % [role, entry_total])
	_dialogue_info.text = "[b]Dialogue System[/b]\n" + "\n".join(role_lines)

func _update_mother_ai_panel() -> void:
	if _mother_ai_info == null:
		return
	if _mother_ai == null:
		_mother_ai_info.text = "MotherAI offline."
		return
	var active_scenes_count: int = 0
	if _mother_ai.has_variable("active_scenes"):
		active_scenes_count = (_mother_ai.active_scenes as Dictionary).size()
	var queue_size: int = 0
	if _mother_ai.has_variable("task_queue"):
		queue_size = (_mother_ai.task_queue as Array).size()
	var busy_text: String = "true"
	if _mother_ai.has_variable("is_busy"):
		busy_text = "true" if _mother_ai.is_busy else "false"
	var lines: Array[String] = []
	lines.append("[b]MotherAI[/b]")
	lines.append("Active scenes: %d" % active_scenes_count)
	lines.append("Queue size: %d" % queue_size)
	lines.append("Busy: %s" % busy_text)
	_mother_ai_info.text = "\n".join(lines)

func _update_metrics_overlay() -> void:
	if _metrics_overlay == null:
		return
	var fps: float = Engine.get_frames_per_second()
	var stage_text: String = _current_stage_name if _current_stage_name != "" else "(none)"
	_metrics_overlay.text = "FPS: %.0f | Stage: %s | Sandbox: %s" % [fps, stage_text, "ON" if _sandbox_enabled else "OFF"]
