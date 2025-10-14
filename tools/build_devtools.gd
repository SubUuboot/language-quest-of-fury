extends Node

# Utilitaire : ajoute un enfant et assigne son owner (et optionnellement ancre/plein écran pour Control)
func _add(child: Node, parent: Node, root_owner: Node, full_rect: bool = false) -> Node:
	parent.add_child(child)
	child.owner = root_owner
	if full_rect and child is Control:
		child.set_anchors_preset(Control.PRESET_FULL_RECT)
	return child

func _ready() -> void:
	print("🔧 Génération de DevTools avec owners...")

	# Racine de la scène à sauvegarder
	var devtools := Node.new()
	devtools.name = "DevTools"
	# le root s’appartient à lui-même

	# DebugMenu (Control plein écran en overlay)
	var debug_menu := _add(Control.new(), devtools, devtools, true)
	debug_menu.name = "DebugMenu"
	debug_menu.visible = true

	# ToggleButton (en haut à gauche)
	var toggle_button := _add(Button.new(), debug_menu, devtools)
	toggle_button.name = "ToggleButton"
	toggle_button.text = "Toggle Debug"
	toggle_button.position = Vector2(16, 16)
	toggle_button.connect("pressed", Callable(self, "_toggle_menu").bind(debug_menu))

	# TabsContainer (plein écran sous le bouton)
	var tabs := _add(TabContainer.new(), debug_menu, devtools, true)
	tabs.name = "TabsContainer"
	tabs.position = Vector2(0, 48) # petit offset sous le bouton

	# === Onglet Tank ===
	var tank_tab := _add(VBoxContainer.new(), tabs, devtools)
	tank_tab.name = "Tank"

	for label_name in ["Speed", "Gear", "Fuel"]:
		var lbl := _add(Label.new(), tank_tab, devtools)
		lbl.name = label_name
		lbl.text = "%s: -" % label_name

	# === Onglet Camera ===
	var camera_tab := _add(VBoxContainer.new(), tabs, devtools)
	camera_tab.name = "Camera"

	for label_name in ["Zoom", "OffsetX", "OffsetY"]:
		var lbl2 := _add(Label.new(), camera_tab, devtools)
		lbl2.name = label_name
		lbl2.text = "%s: -" % label_name

	# === Onglet System ===
	var sys_tab := _add(VBoxContainer.new(), tabs, devtools)
	sys_tab.name = "System"

	for label_name in ["FPS", "Delta"]:
		var lbl3 := _add(Label.new(), sys_tab, devtools)
		lbl3.name = label_name
		lbl3.text = "%s: -" % label_name

	# KeyListener (Node simple)
	var key_listener := _add(Node.new(), debug_menu, devtools)
	key_listener.name = "KeyListener"

	# LogConsole (RichTextLabel à part)
	var log_console := _add(RichTextLabel.new(), devtools, devtools)
	log_console.name = "LogConsole"
	log_console.text = "[b]Log Console initialized[/b]"
	log_console.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_console.size_flags_vertical = Control.SIZE_FILL
	# position/fenêtrage simple
	if log_console is Control:
		(log_console as Control).position = Vector2(16, 300)
		(log_console as Control).custom_minimum_size = Vector2(400, 160)

	# MetricsOverlay
	var metrics := _add(Label.new(), devtools, devtools)
	metrics.name = "MetricsOverlay"
	metrics.text = "Metrics: ---"
	if metrics is Control:
		(metrics as Control).position = Vector2(16, 480)

	print("✅ DevTools tree built, owners set.")

	# Sauvegarde : pack le root (devtools)
	var scene := PackedScene.new()
	var pack_err := scene.pack(devtools)
	if pack_err != OK:
		push_error("❌ Error packing DevTools scene: %s" % pack_err)
		return

	var save_err := ResourceSaver.save(scene, "res://Scenes/DevTools.tscn") # Godot 4.x : (Resource, path)
	if save_err == OK:
		print("💾 Saved to res://Scenes/DevTools.tscn")
	else:
		push_error("❌ Failed to save DevTools scene, error code: %s" % save_err)

func _toggle_menu(menu: Control) -> void:
	menu.visible = not menu.visible
	print("🔁 DebugMenu visibility ->", menu.visible)
