extends Control

# --- Raccourcis vers les sous-nœuds (adapter si besoin) ---
@onready var speed_label: Label = $SpeedPanel/SpeedLabel
@onready var gear_label: Label = $GearLabel if has_node("%GearLabel") else null
@onready var command_label: Label = $CommandPanel/CommandLabel if has_node("%CommandLabel") else null
@onready var pronunciation_label: Label = $CommandPanel/PronunciationLabel if has_node("%PronunciationLabel") else null
@onready var fuel_bar: ProgressBar = $FuelPanel/FuelBar if has_node("%FuelBar") else null
@onready var instructor_dialog: Label = $InstructorDialog if has_node("%InstructorDialog") else null
@onready var movement_indicator: Label = $MovementIndicator if has_node("%MovementIndicator") else null
@onready var log_container: VBoxContainer = $LogContainer if has_node("%LogContainer") else null
@onready var debug_overlay: Label = $DebugOverlay if has_node("%DebugOverlay") else null

# --- Timers internes ---
var current_command_timer := 0.0
var command_display_time := 3.0
var instructor_message_timer := 0.0

# --- Log à l’écran ---
var max_log_lines := 8
var log_fade_time := 0.35
var log_display_time := 3.0

# --- Debug Overlay ---
@export var tank_path: NodePath
var tank_ref: Node = null
var debug_visible := false

func _ready():
	_setup_ui()

	if tank_path and get_node_or_null(tank_path):
		tank_ref = get_node(tank_path)
	
	if debug_overlay:
		debug_overlay.visible = false
	
	if gear_label:
		gear_label.text = "Rapport : N"

func _setup_ui():
	if speed_label:
		speed_label.text = "Скорость: 0 км/ч"
	if command_label:
		command_label.text = ""
		command_label.modulate.a = 0.0
	if pronunciation_label:
		pronunciation_label.text = ""
		pronunciation_label.modulate.a = 0.0
	if fuel_bar:
		fuel_bar.value = 100.0
	if instructor_dialog:
		instructor_dialog.visible = false
		instructor_dialog.modulate.a = 0.0
	if movement_indicator:
		movement_indicator.visible = true
		movement_indicator.text = "СТОП"
		movement_indicator.modulate = Color.RED

func _process(delta):
	# Commandes et messages temporisés
	if current_command_timer > 0.0:
		current_command_timer -= delta
		if current_command_timer <= 0.0:
			hide_command()
	if instructor_message_timer > 0.0:
		instructor_message_timer -= delta
		if instructor_message_timer <= 0.0:
			hide_instructor_dialog()

	# --- Debug overlay ---
	if Input.is_action_just_pressed("ui_debug_menu"):
		debug_visible = !debug_visible
		if debug_overlay:
			debug_overlay.visible = debug_visible

	if debug_visible and debug_overlay and tank_ref:
		_update_debug_overlay()

# ------------------------------------------------------------
# 🧠 Fonctions publiques pour Tank / Instructor
# ------------------------------------------------------------

func update_speed(_speed_ms: float, speed_kmh: int) -> void:
	if speed_label:
		speed_label.text = "Скорость: %d км/ч" % speed_kmh

func update_gear_display(gear: int) -> void:
	if not gear_label:
		return
	var text := ""
	match gear:
		-1: text = "R"
		0: text = "N"
		_: text = str(gear)
	gear_label.text = "Rapport : %s" % text
	var t = create_tween()
	t.tween_property(gear_label, "scale", Vector2(1.2, 1.2), 0.1)
	t.tween_property(gear_label, "scale", Vector2(1.0, 1.0), 0.1)

func show_command(russian_text: String, pronunciation: String) -> void:
	if command_label and pronunciation_label:
		command_label.text = russian_text
		pronunciation_label.text = "(%s)" % pronunciation
		current_command_timer = command_display_time
		var t = create_tween()
		t.tween_property(command_label, "modulate:a", 1.0, 0.2)
		t.parallel().tween_property(pronunciation_label, "modulate:a", 1.0, 0.2)

func hide_command() -> void:
	if command_label and pronunciation_label:
		var t = create_tween()
		t.tween_property(command_label, "modulate:a", 0.0, 0.25)
		t.parallel().tween_property(pronunciation_label, "modulate:a", 0.0, 0.25)
		t.tween_callback(func():
			command_label.text = ""
			pronunciation_label.text = "")

func show_instructor_message(message: String, duration := 5.0) -> void:
	if instructor_dialog:
		instructor_dialog.text = message
		instructor_dialog.visible = true
		instructor_message_timer = duration
		var t = create_tween()
		t.tween_property(instructor_dialog, "modulate:a", 1.0, 0.2)

func hide_instructor_dialog() -> void:
	if instructor_dialog:
		var t = create_tween()
		t.tween_property(instructor_dialog, "modulate:a", 0.0, 0.25)
		t.tween_callback(func(): instructor_dialog.visible = false)

func update_movement_state(is_moving: bool, direction: String = "stopped") -> void:
	if movement_indicator:
		movement_indicator.visible = true
		match direction:
			"forward":
				movement_indicator.text = "ВПЕРЁД"
				movement_indicator.modulate = Color.GREEN
			"backward":
				movement_indicator.text = "НАЗАД"
				movement_indicator.modulate = Color.ORANGE
			_:
				movement_indicator.text = "СТОП"
				movement_indicator.modulate = Color.RED
	if speed_label:
		speed_label.modulate = (Color.GREEN if is_moving else Color.WHITE)

# ------------------------------------------------------------
# 📋 Log visuel (log_to_screen)
# ------------------------------------------------------------
func log_to_screen(text: String) -> void:
	if not log_container:
		return
	while log_container.get_child_count() >= max_log_lines:
		log_container.get_child(0).queue_free()

	var lbl := Label.new()
	lbl.text = text
	lbl.modulate.a = 0.0
	log_container.add_child(lbl)

	var t_in = create_tween()
	t_in.tween_property(lbl, "modulate:a", 1.0, log_fade_time)

	await get_tree().create_timer(log_display_time).timeout
	if is_instance_valid(lbl):
		var t_out = create_tween()
		t_out.tween_property(lbl, "modulate:a", 0.0, log_fade_time)
		t_out.tween_callback(func(): if is_instance_valid(lbl): lbl.queue_free())

# ------------------------------------------------------------
# 🧮 Debug Overlay (ancien HUDDebug fusionné)
# ------------------------------------------------------------
func _update_debug_overlay() -> void:
	if not tank_ref:
		return

	var dir := "stopped"
	if tank_ref.has_method("_get_direction_from_velocity"):
		dir = tank_ref._get_direction_from_velocity()

	var gear_text := "?"
	if tank_ref.has_variable("current_gear"):
		var g : int = tank_ref.current_gear
		match g:
			-1: gear_text = "R"
			0: gear_text = "N"
			_: gear_text = str(g)

	var speed_kmh := int(tank_ref.velocity.length() * 3.6)
	var pos : Vector2 = tank_ref.global_position

	debug_overlay.text = "=== DEBUG ===\n" \
	+ "Vitesse: %d km/h\n" % speed_kmh \
	+ "Rapport: %s\n" % gear_text \
	+ "Direction: %s\n" % dir \
	+ "Position: (%.1f, %.1f)" % [pos.x, pos.y]
