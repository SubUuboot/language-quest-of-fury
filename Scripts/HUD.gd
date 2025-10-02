extends Control

@onready var speed_label = $SpeedPanel/SpeedLabel
@onready var command_label = $CommandPanel/CommandLabel
@onready var pronunciation_label = $CommandPanel/PronunciationLabel
@onready var fuel_bar = $FuelPanel/FuelBar
@onready var instructor_dialog = $InstructorDialog
@onready var movement_indicator = $MovementIndicator

var current_command_timer := 0.0
var command_display_time := 3.0
var instructor_message_timer := 0.0

func _ready():
	setup_ui()
	if command_label: command_label.modulate.a = 0.0
	if pronunciation_label: pronunciation_label.modulate.a = 0.0
	if instructor_dialog:
		instructor_dialog.modulate.a = 0.0
		instructor_dialog.visible = false

	# --- TEST : force une commande au lancement ---
	show_command("ТЕСТ", "TEST")

func setup_ui():
	if speed_label: speed_label.text = "Скорость: 0 км/ч"
	if command_label: command_label.text = ""
	if pronunciation_label: pronunciation_label.text = ""
	if fuel_bar: fuel_bar.value = 100
	if instructor_dialog: instructor_dialog.visible = false

func _process(delta):
	if current_command_timer > 0:
		current_command_timer -= delta
		if current_command_timer <= 0:
			hide_command()
	if instructor_message_timer > 0:
		instructor_message_timer -= delta
		if instructor_message_timer <= 0:
			hide_instructor_dialog()

func update_speed(_speed_ms: float, speed_kmh: int):
	if speed_label:
		speed_label.text = "Скорость: %d км/ч" % speed_kmh

func show_command(russian_text: String, pronunciation: String):
	if command_label and pronunciation_label:
		command_label.text = russian_text
		pronunciation_label.text = "(%s)" % pronunciation
		current_command_timer = command_display_time
		var tween = create_tween()
		tween.tween_property(command_label, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(pronunciation_label, "modulate:a", 1.0, 0.2)

func hide_command():
	if command_label and pronunciation_label:
		var tween = create_tween()
		tween.tween_property(command_label, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(pronunciation_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			command_label.text = ""
			pronunciation_label.text = ""
		)

func update_fuel(fuel_percent: float):
	if fuel_bar:
		fuel_bar.value = fuel_percent
		if fuel_percent < 20:
			fuel_bar.tint_progress = Color.RED
		elif fuel_percent < 50:
			fuel_bar.tint_progress = Color.ORANGE
		else:
			fuel_bar.tint_progress = Color.GREEN

func show_instructor_message(message: String, duration := 5.0):
	if instructor_dialog:
		instructor_dialog.text = message
		instructor_dialog.visible = true
		instructor_message_timer = duration
		var tween = create_tween()
		tween.tween_property(instructor_dialog, "modulate:a", 1.0, 0.25)

func hide_instructor_dialog():
	if instructor_dialog:
		var tween = create_tween()
		tween.tween_property(instructor_dialog, "modulate:a", 0.0, 0.35)
		tween.tween_callback(func(): instructor_dialog.visible = false)

func show_instructor_command(russian_text: String, pronunciation: String):
	show_command(russian_text, pronunciation)
	if command_label:
		var tween = create_tween()
		tween.tween_property(command_label, "scale", Vector2(1.2, 1.2), 0.08)
		tween.tween_property(command_label, "scale", Vector2(1.0, 1.0), 0.08)

func update_movement_state(is_moving: bool):
	if movement_indicator:
		movement_indicator.visible = true
		if is_moving:
			movement_indicator.modulate = Color.GREEN
			movement_indicator.text = "ДВИЖЕНИЕ"
		else:
			movement_indicator.modulate = Color.RED
			movement_indicator.text = "СТОП"
	if speed_label:
		speed_label.modulate = Color.GREEN if is_moving else Color.WHITE
