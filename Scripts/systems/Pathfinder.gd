extends Node

@onready var main_scene = $Main
@onready var segments_root = $Segments

@export var DEBUG_MODE: bool = true
var row_scene: PackedScene = preload("res://Scenes/Segments/SegmentRow.tscn")

func _ready() -> void:
	print("Game init...")
	generate_valid_course(8)  # génère 8 rangées pour tester

# -------------------------------------------------------
# Génération avec pathfinder
# -------------------------------------------------------
func generate_valid_course(num_rows: int) -> void:
	var attempts := 0
	while true:
		attempts += 1
		var rows: Array = generate_course_data(num_rows)  # Array de Array[int]
		debug_print_rows(rows)

		if path_exists(rows):
			print("✅ Parcours valide trouvé en %d essai(s)" % attempts)
			build_course(rows)
			return
		else:
			print("❌ Parcours invalide, on réessaie...")

# -------------------------------------------------------
# Génère les données brutes (0=passable, 1=tricky, 2=obstacle)
# -------------------------------------------------------
func generate_course_data(num_rows: int) -> Array:
	var rows: Array = []
	for i in range(num_rows):
		var row: Array = []
		for col in range(4):
			var r = randf()
			if r < 0.7:
				row.append(0)  # 70% passable
			elif r < 0.9:
				row.append(1)  # 20% tricky
			else:
				row.append(2)  # 10% obstacle
		rows.append(row)
	return rows

# -------------------------------------------------------
# Construit la scène avec les rangées validées
# -------------------------------------------------------
func build_course(rows: Array) -> void:
	# Nettoyer les anciens segments
	for child in segments_root.get_children():
		child.queue_free()

	var y_offset := 0
	for row_data in rows:
		var row = row_scene.instantiate()
		segments_root.add_child(row)
		row.position = Vector2(0, -y_offset)

		# Passe les entiers (0/1/2) à SegmentRow
		row.generate_row_from_data(row_data)

		y_offset += row.size.y

		# connecter les zones de validation
		for zone in row.get_tree().get_nodes_in_group("validation_zones"):
			var instructor = main_scene.get_node("Instructor")
			if not zone.tank_entered.is_connected(instructor._on_zone_reached):
				zone.tank_entered.connect(instructor._on_zone_reached)

# -------------------------------------------------------
# Vérifie qu'il existe au moins un chemin du haut vers le bas
# (0=passable, 1=tricky → comptés comme valides, 2=obstacle = bloqué)
# -------------------------------------------------------
func path_exists(rows: Array) -> bool:
	var open_positions: Array = [0, 1, 2, 3]  # colonnes possibles au départ

	for row in rows:
		var new_positions: Array = []
		for pos in open_positions:
			# colonne actuelle
			if row[pos] != 2:  # obstacle = 2 → bloqué
				new_positions.append(pos)
			# gauche
			if pos > 0 and row[pos - 1] != 2:
				new_positions.append(pos - 1)
			# droite
			if pos < 3 and row[pos + 1] != 2:
				new_positions.append(pos + 1)
		open_positions = new_positions.duplicate()
		if open_positions.is_empty():
			return false
	return true

# -------------------------------------------------------
# Debug : affiche la grille générée dans la console
# -------------------------------------------------------
func debug_print_rows(rows: Array) -> void:
	print("\n--- DEBUG COURSE ---")
	var i := 0
	for row in rows:
		var text := "Row %d: " % i
		for val in row:
			match val:
				0: text += "0 "  # passable
				1: text += "1 "  # tricky
				2: text += "X "  # obstacle
		print(text)
		i += 1
	print("--- END COURSE ---\n")
