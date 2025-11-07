@tool

extends Control
class_name DevTools


signal devtools_toggled(is_open: bool)

var is_open: bool = false

@onready var _debug_menu: Control = %DebugMenu
@onready var _toggle_button: Button = %DebugMenu/ToggleButton
@onready var _tabs_container: TabContainer = %DebugMenu/TabsContainer

func _ready() -> void:
	visible = false
	is_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _debug_menu:
		_debug_menu.visible = false
		_debug_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await _hook_input_bootstrap()
	_bind_ui_controls()
	print("🧩 DevTools prêt — appuyez sur F1 pour ouvrir/fermer.")

func _hook_input_bootstrap() -> void:
	var bootstrap: Node = get_tree().root.get_node_or_null("InputBootstrap")
	while bootstrap == null:
		await get_tree().process_frame
		bootstrap = get_tree().root.get_node_or_null("InputBootstrap")
	if bootstrap.has_method("await_ready"):
		await bootstrap.await_ready()
	var toggle_callable: Callable = Callable(self, "_on_devtools_toggle_requested")
	if not bootstrap.is_connected("devtools_toggle_requested", toggle_callable):
		bootstrap.connect("devtools_toggle_requested", toggle_callable)

func _bind_ui_controls() -> void:
	focus_mode = Control.FOCUS_ALL
	if _toggle_button:
		var button_callable: Callable = Callable(self, "_on_toggle_button_pressed")
		if not _toggle_button.is_connected("pressed", button_callable):
			_toggle_button.pressed.connect(button_callable)
	if _tabs_container:
		_tabs_container.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_devtools_toggle_requested() -> void:
	_toggle_menu()

func _on_toggle_button_pressed() -> void:
	_toggle_menu()

func _toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	if _debug_menu:
		_debug_menu.visible = is_open
		_debug_menu.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	if is_open:
		grab_focus()
	emit_signal("devtools_toggled", is_open)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED)
	print("🎛️ DevTools toggled → Tank input_enabled =", not is_open)
	print("🧭 DevTools:" + ("ouvert" if is_open else "fermé"))
