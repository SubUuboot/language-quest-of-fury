extends Area2D

@export var zone_id: String = ""	# ex: "cross", "climb", "stop"

signal tank_entered(zone_id: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("tank"):	# ajoute ton Tank à un groupe "tank"
		emit_signal("tank_entered", zone_id)
