extends Control
class_name DebugMenu

# --- Références principales ---
@onready var tabs_container: TabContainer = $TabsContainer
@onready var toggle_button: Button = $ToggleButton
@onready var key_listener: Node = $KeyListener
@onready var log_console: RichTextLabel = $"../LogConsole" if has_node("../LogConsole") else null
@onready var metrics_overlay: Label = $"../MetricsOverlay" if has_node("../MetricsOverlay") else null

# --- État interne ---
var is_open: bool = false
var refresh_interval: float = 0.2
var _time_since_update: float = 0.0
var tank: Node = null

# --- Signaux ---
signal menu_toggled(is_open: bool)

# --- Cycle de vie ---
func _ready() -> void:
	
	await get_tree().process_frame  # ⏳ attend une frame que les autoloads soient prêts
	
	if Engine.has_singleton("InputBootstrap"):
		print("✅ InputBootstrap est chargé et accessible !")
	else:
		push_warning("⚠️ InputBootstrap n'est PAS chargé au moment de _ready() !")
	
	tank = get_tree().get_first_node_in_group("tank")
	if tank == null:
		push_warning("[DebugMenu] Aucun tank trouvé dans la scène.")
	mouse_filter = Control.MOUSE_FILTER_STOP  # bloque la souris pour les clics de jeu

# --- Vérifie que l’action F1 existe, sinon la crée ---
	if Engine.has_singleton("InputBootstrap"):
		InputBootstrap._ensure_action("ui_debug_menu", [KEY_F1])
	else:
		# fallback de secours si l’autoload n’existe pas encore
		if not InputMap.has_action("ui_debug_menu"):
			InputMap.add_action("ui_debug_menu")
			var ev := InputEventKey.new()
			ev.keycode = KEY_F1
			InputMap.action_add_event("ui_debug_menu", ev)
			print("[DebugMenu] ui_debug_menu ajoutée manuellement (fallback).")
	if not InputMap.has_action("ui_debug_menu"):
	# --- Positionnement et état initial ---
		set_as_top_level(true)
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL

		visible = false
		if toggle_button:
			toggle_button.pressed.connect(_on_toggle_button_pressed)

		set_process_input(true)
		set_process(true)
		print("[DebugMenu] Ready.")
	
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_button_pressed)

	set_process_input(true)
	set_process(true)
	print("[DebugMenu] Ready.")

# --- Gestion clavier ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug_menu"):
		_toggle_menu()

# --- Rafraîchissement périodique ---
func _process(delta: float) -> void:
	if not visible:
		return
	_time_since_update += delta
	if _time_since_update >= refresh_interval:
		_update_values()
		_time_since_update = 0.0

# --- Ouverture / fermeture du menu ---
func _toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	emit_signal("menu_toggled", is_open)

	# 🖱️ Gestion de la souris et des contrôles du joueur
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED)

	# 🔒 Suspension des actions de gameplay
	_toggle_game_input(not is_open)

	print("[DebugMenu] Toggled: ", is_open)

func _on_toggle_button_pressed() -> void:
	_toggle_menu()

# --- Suspension / reprise des contrôles du jeu ---
func _toggle_game_input(enable: bool) -> void:
	# Cherche le tank dans la scène et active/désactive son contrôle
	var tank := get_tree().get_first_node_in_group("tank")
	if tank and tank.has_method("set_input_enabled"):
		tank.set_input_enabled(enable)

	# Vide les événements clavier/manette pour éviter les touches bloquées
	if not enable:
		Input.flush_buffered_events()


# --- Rafraîchissement des valeurs ---
func _update_values() -> void:
	var debug_data: Dictionary = {
		"Tank": {"Speed": 45.2, "Gear": 3, "Fuel": 82.4},
		"Camera": {"Zoom": 1.1, "OffsetX": 15, "OffsetY": -8},
		"System": {"FPS": Engine.get_frames_per_second(), "Delta": Engine.get_physics_ticks_per_second()}
	}

	for tab_name in debug_data.keys():
		_update_tab(tab_name, debug_data[tab_name])

func _update_tab(tab_name: String, values: Dictionary) -> void:
	var tab: VBoxContainer = tabs_container.get_node_or_null(tab_name)
	if tab == null:
		return
	for child in tab.get_children():
		if child is Label:
			var key: String = child.name
			if values.has(key):
				child.text = "%s: %s" % [key, str(values[key])]

# --- API publique ---
func register_data_source(tab_name: String, callback: Callable) -> void:
	# Permet à d’autres scripts d’enregistrer une source de données (ex: TankController2D)
	# callback doit retourner un Dictionary {variable: valeur}
	pass
