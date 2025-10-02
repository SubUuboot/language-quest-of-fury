# Level.gd
extends Node2D

@export var obstacle_count = 20
@export var ground_tiles_count = 50

@onready var tank = $Tank

var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var ground_scene = preload("res://scenes/Ground.tscn")

func _ready():
	generate_obstacles()
	generate_ground()
	place_checkpoints()

func generate_obstacles():
	for i in range(obstacle_count):
		var obstacle = obstacle_scene.instantiate()
		add_child(obstacle)
		
		# Position aléatoire mais loin du point de départ
		var pos = Vector2(
			randf_range(-500, 500),
			randf_range(-500, 500)
		)
		
		# Éviter de spawn trop près du tank
		if pos.distance_to(tank.position) < 200:
			pos = pos.normalized() * 250
		
		obstacle.position = pos

func generate_ground():
	for i in range(ground_tiles_count):
		var ground = ground_scene.instantiate()
		add_child(ground)
		
		ground.position = Vector2(
			randf_range(-600, 600),
			randf_range(-600, 600)
		)

func place_checkpoints():
	# Pour plus tard: points de contrôle pour les missions
	pass
