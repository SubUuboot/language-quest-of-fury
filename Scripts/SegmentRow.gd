extends Node2D

@export var segment_scenes_ext_left: Array[PackedScene]
@export var segment_scenes_left: Array[PackedScene]
@export var segment_scenes_right: Array[PackedScene]
@export var segment_scenes_ext_right: Array[PackedScene]

var size: Vector2i = Vector2i(2560, 640)	# 4 colonnes de 640 px

func generate_row_from_data(data: Array) -> void:
	# data = [?, ?, ?, ?] → converti en bool
	if data.size() < 4:
		push_warning("Row data trop courte: %s" % [data])
		return

	# clean les slots
	for slot in [$Slot0, $Slot1, $Slot2, $Slot3]:
		for child in slot.get_children():
			child.queue_free()

	# appliquer les 4 colonnes
	$Slot0.add_child(_pick_scene(segment_scenes_ext_left, bool(data[0])).instantiate())
	$Slot1.add_child(_pick_scene(segment_scenes_left, bool(data[1])).instantiate())
	$Slot2.add_child(_pick_scene(segment_scenes_right, bool(data[2])).instantiate())
	$Slot3.add_child(_pick_scene(segment_scenes_ext_right, bool(data[3])).instantiate())
	
	print("Row data=", data, " pools sizes: L=", segment_scenes_ext_left.size(),
	" M-L=", segment_scenes_left.size(),
	" M-R=", segment_scenes_right.size(),
	" R=", segment_scenes_ext_right.size())


func _pick_scene(pool: Array[PackedScene], passable: bool) -> PackedScene:
	# Convention : pool[0] = libre, pool[1] = bloqué
	if pool.is_empty():
		push_error("Segment pool vide !")
		return null
	if pool.size() == 1:
		return pool[0]
	return pool[0] if passable else pool[1]
