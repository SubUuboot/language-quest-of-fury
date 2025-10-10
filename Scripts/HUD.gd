extends Control

# --- Raccourcis vers les sous-nœuds (adapter si tes scènes diffèrent) ---
@onready var speed_label: Label = $SpeedPanel/SpeedLabel
@onready var command_label: Label = $CommandPanel/CommandLabel
@onready var pronunciation_label: Label = $CommandPanel/PronunciationLabel
@onready var fuel_bar: ProgressBar = $FuelPanel/FuelBar
@onready var instructor_dialog: Label = $InstructorDialog
@onready var movement_indicator: Label = $MovementIndicator

# Zone de log visuel (optionnelle)
@onready var log_container: VBoxContainer = $"%LogContainer" if has_node("%LogContainer") else null

# --- Timers internes ---
var current_command_timer := 0.0
var command_display_time := 3.0
var instructor_message_timer := 0.0

# --- Log à l’écran ---
var max_log_lines := 8
var log_fade_time := 0.35
var log_display_time := 3.0

func _ready():
	_setup_ui()
	# Exemple de test visuel non bloquant :
	# show_command("ТЕСТ", "TEST")

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
	if current_command_timer > 0.0:
		current_command_timer -= delta
		if current_command_timer <= 0.0:
			hide_command()
	if instructor_message_timer > 0.0:
		instructor_message_timer -= delta
		if instructor_message_timer <= 0.0:
			hide_instructor_dialog()

# ------------------------------------------------------------
# API publique utilisée par d’autres scripts (Instructor, Tank, etc.)
# ------------------------------------------------------------

func update_speed(_speed_ms: float, speed_kmh: int) -> void:
	if speed_label:
		speed_label.text = "Скорость: %d км/ч" % speed_kmh

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
			pronunciation_label.text = ""
		)

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

func show_instructor_command(russian_text: String, pronunciation: String) -> void:
	show_command(russian_text, pronunciation)
	if command_label:
		var t = create_tween()
		t.tween_property(command_label, "scale", Vector2(1.2, 1.2), 0.08)
		t.tween_property(command_label, "scale", Vector2(1.0, 1.0), 0.08)

func update_movement_state(is_moving: bool) -> void:
	if movement_indicator:
		movement_indicator.visible = true
		if is_moving:
			movement_indicator.modulate = Color.GREEN
			movement_indicator.text = "ДВИЖЕНИЕ"
		else:
			movement_indicator.modulate = Color.RED
			movement_indicator.text = "СТОП"
	if speed_label:
		speed_label.modulate = (Color.GREEN if is_moving else Color.WHITE)

# ------------------------------------------------------------
# Log visuel : log_to_screen()
# ------------------------------------------------------------

func log_to_screen(text: String) -> void:
	if not log_container:
		return
	# Limiter le nombre de lignes visibles
	while log_container.get_child_count() >= max_log_lines:
		var first = log_container.get_child(0)
		first.queue_free()

	var lbl := Label.new()
	lbl.text = text
	lbl.modulate.a = 0.0
	log_container.add_child(lbl)

	var t_in = create_tween()
	t_in.tween_property(lbl, "modulate:a", 1.0, log_fade_time)

	# Disparition après délai
	await get_tree().create_timer(log_display_time).timeout
	if is_instance_valid(lbl):
		var t_out = create_tween()
		t_out.tween_property(lbl, "modulate:a", 0.0, log_fade_time)
		t_out.tween_callback(func():
			if is_instance_valid(lbl):
				lbl.queue_free())
