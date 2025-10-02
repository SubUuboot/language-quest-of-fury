extends Node2D

@onready var commander = %Commander
@onready var instructor = %Instructor
@onready var hangar_door = %HangarDoor

func _ready() -> void:
	# Désactive Instructor au départ
	instructor.set_process(false)
	# PAS de .visible si Instructor hérite de Node
	# si tu veux masquer visuellement, fais hériter d’un CanvasLayer/Control

	if commander and commander.has_signal("protocol_complete"):
		commander.protocol_complete.connect(_on_protocol_complete)

func _on_protocol_complete() -> void:
	# Ouvre la porte du hangar
	if hangar_door.has_method("open_door"):
		hangar_door.open_door()
	
	# Transition vers l’Instructor après un petit délai
	await get_tree().create_timer(2.0).timeout
	
	# Désactive le Commander
	commander.set_process(false)
	# idem : commander.visible seulement si Node2D/Control
	
	# Active l’Instructor
	instructor.set_process(true)
	if instructor.has_method("start_training"):
		instructor.start_training()
