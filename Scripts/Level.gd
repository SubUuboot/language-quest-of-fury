# Level.gd
extends Node2D

@export var nombre_obstacles = 0
@export var nombre_sols = 50

var tank: CharacterBody2D

func _ready():
	# Chercher le Tank dans la scène parente
	tank = get_node_or_null("../Tank")
	
	if tank:
		generer_obstacles()
		generer_sols()
		placer_points_controle()
	else:
		print("Avertissement: Tank non trouvé, génération sans référence")

func generer_obstacles():
	var scene_obstacle = load("res://Scenes/obstacles/Obstacle.tscn")
	if not scene_obstacle:
		print("Erreur: Scène Obstacle non trouvée")
		return
	
	for i in range(nombre_obstacles):
		var obstacle = scene_obstacle.instantiate()
		add_child(obstacle)
		
		var pos = Vector2(
			randf_range(-1050, 1050),
			randf_range(-1050, 1050)
		)
		
		# Si on a une référence au tank, éviter de spawn trop près
		if tank and pos.distance_to(tank.position) < 1200:
			pos = pos.normalized() * 1250
		
		obstacle.position = pos

func generer_sols():
	var scene_sol = load("res://Scenes/Segments/Ground.tscn")
	if not scene_sol:
		print("Erreur: Scène Ground non trouvée")
		return
	
	for i in range(nombre_sols):
		var sol = scene_sol.instantiate()
		add_child(sol)
		

func placer_points_controle():
	# À implémenter plus tard
	pass
