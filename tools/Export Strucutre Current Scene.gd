extends Node

func _ready() -> void:
	var root := get_tree().current_scene
	if root == null:
		push_error("Aucune scène courante à exporter.")
		return
	var output := _scene_tree_as_text(root)
	var f := FileAccess.open("res://scene_structure.txt", FileAccess.WRITE)
	f.store_string(output)
	f.close()
	print("✅ Exporté vers res://scene_structure.txt")

func _scene_tree_as_text(node: Node, indent: int = 0) -> String:
	var prefix := "│   ".repeat(indent)
	var line := "%s%s (%s)\n" % [prefix, node.name, node.get_class()]
	for child in node.get_children():
		line += _scene_tree_as_text(child, indent + 1)
	return line
