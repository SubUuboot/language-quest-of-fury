@tool
extends EditorPlugin

var popup : AcceptDialog

func _enter_tree() -> void:
	add_tool_menu_item("Export Structure", Callable(self, "_show_export_menu"))
	print("🔧 Structure Exporter chargé dans le menu Tools.")

func _exit_tree() -> void:
	remove_tool_menu_item("Export Structure")

# --- Popup principal ---
func _show_export_menu() -> void:
	if popup == null:
		popup = AcceptDialog.new()
		popup.name = "ExportStructureDialog"
		popup.title = "Exporter la structure"
		popup.dialog_text = "Choisis ce que tu veux exporter :"
		add_child(popup)

		var btn_scene := Button.new()
		btn_scene.text = "Exporter la scène courante"
		btn_scene.connect("pressed", Callable(self, "_export_scene"))
		popup.add_child(btn_scene)

		var btn_project := Button.new()
		btn_project.text = "Exporter la structure du projet"
		btn_project.connect("pressed", Callable(self, "_export_project"))
		popup.add_child(btn_project)

		var btn_mermaid := Button.new()
		btn_mermaid.text = "Exporter en Mermaid"
		btn_mermaid.connect("pressed", Callable(self, "_export_mermaid"))
		popup.add_child(btn_mermaid)

		var btn_clip := Button.new()
		btn_clip.text = "📋 Copier la scène dans le presse-papiers"
		btn_clip.connect("pressed", Callable(self, "_copy_scene_to_clipboard"))
		popup.add_child(btn_clip)

	popup.popup_centered(Vector2(380, 200))

# --- Export de la scène courante ---
func _export_scene() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Aucune scène chargée.")
		return

	var text := _scene_to_text(root)
	var file := FileAccess.open("res://scene_structure.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("✅ Export scène → res://scene_structure.txt")

# --- Copier la scène dans le presse-papiers ---
func _copy_scene_to_clipboard() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Aucune scène chargée.")
		return
	var text := _scene_to_text(root)
	DisplayServer.clipboard_set(text)
	print("📋 Structure copiée dans le presse-papiers !")

func _scene_to_text(node: Node, indent: int = 0) -> String:
	var prefix := "│   ".repeat(indent)
	var line := "%s%s (%s)\n" % [prefix, node.name, node.get_class()]
	for child in node.get_children():
		line += _scene_to_text(child, indent + 1)
	return line

# --- Export du projet ---
func _export_project() -> void:
	var output := _dir_to_text("res://")
	var file := FileAccess.open("res://project_structure.txt", FileAccess.WRITE)
	file.store_string(output)
	file.close()
	print("📁 Export projet → res://project_structure.txt")

func _dir_to_text(path: String, indent: int = 0) -> String:
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
			out += _dir_to_text(path + name + "/", indent + 1)
	dir.list_dir_end()
	return out

# --- Export Mermaid ---
func _export_mermaid() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Aucune scène ouverte.")
		return
	var mermaid := "```mermaid\ngraph TD\n" + _scene_to_mermaid(root) + "```\n"
	var file := FileAccess.open("res://scene_mermaid.md", FileAccess.WRITE)
	file.store_string(mermaid)
	file.close()
	print("🧭 Export Mermaid → res://scene_mermaid.md")

func _scene_to_mermaid(node: Node) -> String:
	var lines := ""
	for child in node.get_children():
		lines += "    %s[%s] --> %s[%s]\n" % [node.name, node.get_class(), child.name, child.get_class()]
		lines += _scene_to_mermaid(child)
	return lines
