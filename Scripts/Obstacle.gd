# Obstacle.gd
extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Ajouter au groupe des obstacles pour la détection
	add_to_group("obstacles")
	
	# Optionnel: rotation aléatoire pour varier
	rotation_degrees = randf_range(0, 0)
	
	# Vérifier que la collision existe
	if not collision:
		print("ATTENTION: CollisionShape2D manquant sur obstacle!")
	elif not collision.shape:
		print("ATTENTION: Forme de collision manquante sur obstacle!")
