extends Node
class_name DialoguesLoader

var dialogues: Dictionary = {}

func load_dialogues(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ Impossible de charger " + path)
		return
	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if parsed == null:
		push_error("❌ Erreur JSON dans " + path)
		return
	dialogues = parsed
	print("✅ Dialogues chargés depuis", path, "(", dialogues.keys(), ")")

# Récupérer une réplique individuelle
func get_dialogue(role: String, category: String, id: String) -> Dictionary:
	if dialogues.has(role):
		var role_data = dialogues[role]
		if role_data.has(category):
			for entry in role_data[category]:
				if entry["id"] == id:
					return entry
	return {}

# Récupérer une leçon entière
func get_lesson(role: String, lesson_id: String) -> Dictionary:
	if dialogues.has(role):
		var role_data = dialogues[role]
		if role_data.has("lessons"):
			for lesson in role_data["lessons"]:
				if lesson["id"] == lesson_id:
					return lesson
	return {}
