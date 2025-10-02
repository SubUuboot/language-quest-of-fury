extends Node2D

@export var size: Vector2i = Vector2i(640, 640)   # hauteur * largeur standard (10 tiles × 64px)

func _ready() -> void:
	print("Segment prêt :", name, " largeur déclarée =", size.x, " hauteur déclarée =", size.y)
