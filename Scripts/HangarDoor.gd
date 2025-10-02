extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer



func _ready() -> void:
	var commander = get_node("../Commander") # ajuste le chemin selon ta scène
	if commander and commander.has_signal("protocol_complete"):
		commander.protocol_complete.connect(_on_protocol_complete)

func _on_protocol_complete() -> void:
	if anim and anim.has_animation("open"):
		anim.play("open")

func open_door() -> void:
	if anim and anim.has_animation("open"):
		anim.play("open")
