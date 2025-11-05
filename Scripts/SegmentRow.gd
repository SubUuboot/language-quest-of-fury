extends Node2D

# Chaque côté (extrême gauche, gauche, droite, extrême droite)
# a maintenant 3 listes : passables, piégeux, obstacles
@export var passable_ext_left: Array[PackedScene]
@export var tricky_ext_left: Array[PackedScene]
@export var obstacle_ext_left: Array[PackedScene]

@export var passable_left: Array[PackedScene]
@export var tricky_left: Array[PackedScene]
@export var obstacle_left: Array[PackedScene]

@export var passable_right: Array[PackedScene]
@export var tricky_right: Array[PackedScene]
@export var obstacle_right: Array[PackedScene]

@export var passable_ext_right: Array[PackedScene]
@export var tricky_ext_right: Array[PackedScene]
@export var obstacle_ext_right: Array[PackedScene]

# Taille d'une rangée (4 colonnes de 640px)
var size: Vector2i = Vector2i(2560, 640)

func generate_row_from_data(data: Array) -> void:
	# data = [?, ?, ?, ?] → converti en int (0=passable, 1=tricky, 2=obstacle)
	if data.size() < 4:
		push_warning("Row data trop courte: %s" % [data])
		return

	# nettoyer les slots
	for slot in [$Slot0, $Slot1, $Slot2, $Slot3]:
		for child in slot.get_children():
			child.queue_free()

	# générer les 4 colonnes avec la catégorie appropriée
	$Slot0.add_child(_pick_scene_for_column(0, int(data[0])).instantiate())
	$Slot1.add_child(_pick_scene_for_column(1, int(data[1])).instantiate())
	$Slot2.add_child(_pick_scene_for_column(2, int(data[2])).instantiate())
	$Slot3.add_child(_pick_scene_for_column(3, int(data[3])).instantiate())

# -------------------------------------------------------
# Sélectionne une scène selon la catégorie
# 0 = passable, 1 = tricky, 2 = obstacle
# -------------------------------------------------------
func _pick_scene_for_column(col: int, category: int) -> PackedScene:
	var pool: Array[PackedScene] = []

	match col:
		0:
			if category == 0:
				pool = passable_ext_left
			elif category == 1:
				pool = tricky_ext_left
			else:
				pool = obstacle_ext_left
		1:
			if category == 0:
				pool = passable_left
			elif category == 1:
				pool = tricky_left
			else:
				pool = obstacle_left
		2:
			if category == 0:
				pool = passable_right
			elif category == 1:
				pool = tricky_right
			else:
				pool = obstacle_right
		3:
			if category == 0:
				pool = passable_ext_right
			elif category == 1:
				pool = tricky_ext_right
			else:
				pool = obstacle_ext_right

	if pool.is_empty():
		push_error("⚠️ Pas de scène dispo pour col=%d catégorie=%d" % [col, category])
		return null

	return pool[randi() % pool.size()]
