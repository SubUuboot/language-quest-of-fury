@tool

extends Control
class_name DevTools


signal devtools_toggled(is_open: bool)

var is_open: bool = false

func _ready() -> void:
	# --- Sécurité : forcer la création du binding F1 ---
	if not InputMap.has_action("ui_devtools_menu"):
		InputMap.add_action("ui_devtools_menu")

	var f1_event := InputEventKey.new()
	f1_event.keycode = KEY_F1

	# Efface les anciens events s'ils existent (pour éviter doublon)
	InputMap.action_erase_events("ui_devtools_menu")
	InputMap.action_add_event("ui_devtools_menu", f1_event)

	print("🧩 [DevTools] Binding F1 vérifié ou recréé manuellement.")

	# --- Activation du traitement d’input global ---
	hide()
	set_process_unhandled_input(true)

	print("🧩 DevTools prêt — appuyez sur F1 pour ouvrir/fermer.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_devtools_menu"):
		print("🎛️ [DevTools] F1 détecté via _unhandled_input()")
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	is_open = not is_open
	visible = is_open

	# Cherche le sous-node "DebugMenu" et le rend visible uniquement quand ouvert
	var debug_menu: Control = get_node_or_null("DebugMenu")
	if debug_menu:
		debug_menu.visible = is_open

	emit_signal("devtools_toggled", is_open)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED)

	print("🎛️ DevTools toggled → Tank input_enabled =", not is_open)
	print("🧭 DevTools:" + ("ouvert" if is_open else "fermé"))
