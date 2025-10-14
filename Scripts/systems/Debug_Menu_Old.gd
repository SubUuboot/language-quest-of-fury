extends Control
signal value_changed(setting: String, value: float)

@onready var shake_slider: HSlider = $Panel/TabBar/TabContainer/CamPage/Shake/ShakeSlider
@onready var zoom_slider: HSlider = $Panel/TabBar/TabContainer/CamPage/Zoom/ZoomSlider
@onready var close_button: Button = $Panel/TabBar/TabContainer/Button
@onready var settings := get_node_or_null("res://Core/Config/SettingsManager.gd")
@onready var accel_slider: HSlider = $Panel/TabBar/TabContainer/EnginePage/Puissance/TrackAccelSlider
@onready var speed_slider: HSlider = $"Panel/TabBar/TabContainer/EnginePage/Vitesse max/MaxSpeedSlider"
@onready var brake_slider: HSlider = $Panel/TabBar/TabContainer/EnginePage/Frein/BrakeSlider
@onready var rotation_slider: HSlider = $Panel/TabBar/TabContainer/EnginePage/Rotation/RotationSlider
@onready var inertia_slider: HSlider = $Panel/TabBar/TabContainer/EnginePage/Inertie/InertiaSlider

var is_open: bool = true

func _ready() -> void:
	
	if settings:
		settings.load()

		# Appliquer les valeurs sauvegardées (si elles existent)
		shake_slider.value = settings.get_value("camera_shake", 0.0)
		zoom_slider.value = settings.get_value("camera_zoom_base", 1.0)
		accel_slider.value = settings.get_value("track_accel", 8800.0)
		speed_slider.value = settings.get_value("max_track_speed", 200.0)
		brake_slider.value = settings.get_value("brake_power", 1600.0)
		rotation_slider.value = settings.get_value("rotation_gain", 0.004)
		inertia_slider.value = settings.get_value("inertia_blend", 0.5)
	else:
		# Configuration par défaut si aucun SettingsManager
		shake_slider.min_value = 0.0
		shake_slider.max_value = 2.0
		shake_slider.step = 0.05
		shake_slider.value = 0.0

		zoom_slider.min_value = 0.5
		zoom_slider.max_value = 2.0
		zoom_slider.step = 0.05
		zoom_slider.value = 1.0

	# Connect signaux
	shake_slider.value_changed.connect(func(v: float) -> void:
		emit_signal("value_changed", "camera_shake", v))
	zoom_slider.value_changed.connect(func(v: float) -> void:
		emit_signal("value_changed", "camera_zoom_base", v))
	close_button.pressed.connect(_toggle_visibility)

	# Autoriser souris visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Raccourci F1 pour ouvrir / fermer
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_F1:
		_toggle_visibility()

func _toggle_visibility() -> void:
	is_open = not is_open
	visible = is_open

	# Gestion de la souris
	if is_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
