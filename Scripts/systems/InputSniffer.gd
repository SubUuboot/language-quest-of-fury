extends Node

func _ready() -> void:
	print("👂 InputSniffer actif — appuie sur F1 pour test.")
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_devtools_menu"):
		print("✅ F1 capté par InputSniffer !")
