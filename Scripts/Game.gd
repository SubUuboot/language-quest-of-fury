extends Node

@onready var main_scene = $Main
@onready var segments_root = $Segments
@onready var debug_overlay: Label = $Game/Main/HUD/DebugOverlay

@export var DEBUG_MODE: bool = true

var row_scene: PackedScene = preload("res://Scenes/Segments/SegmentRow.tscn")

func _ready() -> void:
	log_to_screen("Game init...")
	generate_valid_course(8)	# génère 8 rangées valides pour tester

# -------------------------------------------------------
# Génération avec pathfinder
# -------------------------------------------------------
func generate_valid_course(num_rows: int) -> void:
	var attempts := 0
	while true:
		attempts += 1
		var rows: Array = generate_course_data(num_rows)  # Array de Array[bool]
		
		debug_print_rows(rows)
		show_debug_overlay(rows)
		
		if path_exists(rows):
			log_to_screen("Parcours valide trouvé en %d essai(s)" % attempts)
			build_course(rows)
			return
		else:
			log_to_screen("Parcours invalide, on réessaie...")

# -------------------------------------------------------
# Génère les données brutes (sans rien afficher)
# Chaque rangée est Array[bool] de taille 4
# -------------------------------------------------------
func generate_course_data(num_rows: int) -> Array:
	var rows: Array = []
	for i in range(num_rows):
		var row: Array = []
		for col in range(4):
			# 80% libre, 20% bloqué
			row.append(randf() < 0.8)
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

		# Passe les booléens à SegmentRow
		row.generate_row_from_data(row_data)

		y_offset += row.size.y

		# connecter les zones de validation
		for zone in row.get_tree().get_nodes_in_group("validation_zones"):
			var instructor = main_scene.get_node("Instructor")
			if not zone.tank_entered.is_connected(instructor._on_zone_reached):
				zone.tank_entered.connect(instructor._on_zone_reached)

# -------------------------------------------------------
# Vérifie qu'il existe au moins un chemin du haut vers le bas
# -------------------------------------------------------
func path_exists(rows: Array) -> bool:
	var open_positions: Array = [0, 1, 2, 3]  # colonnes possibles au départ

	for row in rows:
		var new_positions: Array = []
		for pos in open_positions:
			# colonne actuelle
			if row[pos]:
				new_positions.append(pos)
			# gauche
			if pos > 0 and row[pos - 1]:
				new_positions.append(pos - 1)
			# droite
			if pos < 3 and row[pos + 1]:
				new_positions.append(pos + 1)
		open_positions = new_positions.duplicate()
		if open_positions.is_empty():
			return false
	return true

# -------------------------------------------------------
# Debug : affiche la grille générée dans la console
# -------------------------------------------------------
func debug_print_rows(rows: Array) -> void:
	log_to_screen("\n--- DEBUG COURSE ---")
	var i := 0
	for row in rows:
		var text := "Row %d: " % i
		for val in row:
			text += ("1 " if val else "0 ")
		log_to_screen(text)
		i += 1
	log_to_screen("--- END COURSE ---\n")

# -------------------------------------------------------
# Debug : affiche la grille dans le HUD (Label DebugOverlay)
# -------------------------------------------------------
func show_debug_overlay(rows: Array) -> void:
	if not DEBUG_MODE or not debug_overlay:
		return
	
	var text := ""
	var i := 0
	for row in rows:
		text += "Row %d: " % i
		for val in row:
			text += ("1 " if val else "0 ")
		text += "\n"
		i += 1
	
	debug_overlay.text = text # Alimente le Label DebugOverlay dans le HUDLayer

# -------------------------------------------------------
# Utilitaire : print + affichage à l'écran
# -------------------------------------------------------
func log_to_screen(msg: String) -> void:
	print(msg)
	if DEBUG_MODE and debug_overlay:
		debug_overlay.text += msg + "\n"
