@tool
extends EditorScript

func _run():
	var output := _dir_as_text("res://")
	var f := FileAccess.open("res://project_structure.txt", FileAccess.WRITE)
	f.store_string(output)
	f.close()
	print("📁 Exporté vers res://project_structure.txt")

func _dir_as_text(path: String, indent: int = 0) -> String:
	var dir := DirAccess.open(path)
	if dir == null:
		return ""
	var out := ""
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var prefix := "│   ".repeat(indent)
		out += "%s%s\n" % [prefix, name]
		if dir.current_is_dir():
			out += _dir_as_text(path + name + "/", indent + 1)
	dir.list_dir_end()
	return out
