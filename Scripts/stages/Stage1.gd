extends Node2D
signal stage_complete

func _ready():
	print("Stage 1 ready.")
	# Exemple : démarrage du tutoriel, dialogues, etc.
	$Main.start_tutorial()

func complete_stage():
	print("Stage 1 completed.")
	emit_signal("stage_complete")
