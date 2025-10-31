extends Control
class_name DevTools

signal devtools_toggled(is_open: bool)

var is_open: bool = false

func _ready() -> void:
	# Démarre caché et prêt à écouter F1 (ou l'action associée)
	hide()
	set_process_input(true)
	print("🧩 DevTools prêt — appuyez sur F1 pour ouvrir/fermer.")

func _input(event: InputEvent) -> void:
	# F1 est mappé à l’action "ui_devtools_menu" par InputBootstrap
	if event.is_action_pressed("ui_devtools_menu"):
		print("🎛️ Entrée DevTools détectée (F1).")
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	hide()
	set_process_input(true)
	is_open = not is_open
	visible = is_open

	# Émet un signal global pour informer les autres systèmes (TankController, etc.)
	emit_signal("devtools_toggled", is_open)

	# Gestion du curseur souris : visible quand le menu est ouvert
	if is_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Journalisation
	if is_open:
		print("🧭 DevTools ouvert.")
	else:
		print("✅ DevTools fermé.")
