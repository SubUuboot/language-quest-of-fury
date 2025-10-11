extends CharacterBody2D
class_name TankController2D

signal moved(direction: String)
signal gear_changed(gear: int)
signal action_performed(action: String)

@export var acceleration := 4.0
@export var max_speed_forward := 10.0
@export var max_speed_reverse := 5.0
@export var rotation_speed := 2.0
@export var friction := 2.5
@export var gear_ratios := [-1.0, 0.0, 0.4, 0.6, 0.8, 1.0]

@export var debug_dashboard: bool = true
var _debug_label: Label

@export var input_accelerate := "accelerate"
@export var input_brake := "brake"
@export var input_steer_left := "steer_left"
@export var input_steer_right := "steer_right"
@export var input_gear_up := "gear_up"
@export var input_gear_down := "gear_down"

@export var hud_path: NodePath
@export var instructor_path: NodePath
var hud_ref: Node = null
var instructor_ref: Node = null

var current_gear: int = 0
var current_engine_force := 0.0
# (supprimé la redéclaration de velocity)
var _previous_direction: String = "stopped"
var _previous_gear: int = 0
var _movement_threshold := 0.05

func _ready() -> void:
	
	if debug_dashboard:
		_create_debug_hud()
	
	
	if hud_path and get_node_or_null(hud_path):
		hud_ref = get_node(hud_path)
	else:
		push_warning("HUD non assigné pour %s" % name)
	if instructor_path and get_node_or_null(instructor_path):
		instructor_ref = get_node(instructor_path)
	emit_signal("gear_changed", current_gear)
	_previous_gear = current_gear

	if hud_ref and hud_ref.has_method("update_gear_display"):
		self.gear_changed.connect(hud_ref.update_gear_display)


func _get_direction_from_velocity() -> String:
	if velocity.length() < _movement_threshold:
		return "stopped"
	var forward := transform.x.normalized()
	return "forward" if velocity.dot(forward) > 0 else "backward"

# ==========================================================
# Contrôle des chenilles indépendantes (réaliste)
# ==========================================================

@export var track_accel: float = 6.0
@export var max_track_speed: float = 10.0
@export var rotation_gain: float = 0.8
@export var drag: float = 2.5

var left_track_speed: float = 0.0
var right_track_speed: float = 0.0
var left_target_speed: float = 0.0
var right_target_speed: float = 0.0

func _process_inputs(delta: float) -> void:
	var accel_forward: float = Input.get_action_strength("accelerate")  # ESPACE
	var accel_reverse: float = Input.get_action_strength("brake")       # CTRL
	var turn_left: float = Input.get_action_strength("steer_left")      # Q
	var turn_right: float = Input.get_action_strength("steer_right")    # D

	# Détermination de la direction de chaque chenille
	left_target_speed = 0.0
	right_target_speed = 0.0

	# --- Marche avant / arrière ---
	if accel_forward > 0.0:
		left_target_speed += max_track_speed
		right_target_speed += max_track_speed
	elif accel_reverse > 0.0:
		left_target_speed -= max_track_speed
		right_target_speed -= max_track_speed

	# --- Rotation sur place ---
	if current_gear != 0:
		if turn_left > 0.0:
			left_target_speed -= max_track_speed
			right_target_speed += max_track_speed
		elif turn_right > 0.0:
			left_target_speed += max_track_speed
			right_target_speed -= max_track_speed


	# --- Lissage de la vitesse de chaque chenille ---
	left_track_speed = move_toward(left_track_speed, left_target_speed, track_accel * delta)
	right_track_speed = move_toward(right_track_speed, right_target_speed, track_accel * delta)


func _physics_process(delta: float) -> void:
	_process_inputs(delta)

	# Moyenne des chenilles = déplacement avant/arrière
	var forward_speed: float = (left_track_speed + right_track_speed) * 0.5
	# Différence des chenilles = rotation
	var rotation_speed: float = (right_track_speed - left_track_speed) * rotation_gain

	# Direction du tank (vers le haut)
	var forward_dir: Vector2 = transform.y.normalized() * -1.0


	# Application de la vitesse
	velocity = forward_dir * forward_speed
	rotation += rotation_speed * delta

	# Friction (ralentit progressivement quand aucune touche n’est pressée)
	if absf(left_target_speed) < 0.1 and absf(right_target_speed) < 0.1:
		left_track_speed = move_toward(left_track_speed, 0.0, drag * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, drag * delta)
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

	move_and_slide()
	_update_debug_hud()




func _update_direction_and_notify() -> void:
	var dir := _get_direction_from_velocity()
	if dir != _previous_direction:
		emit_signal("moved", dir)
		_previous_direction = dir
		if hud_ref and hud_ref.has_method("log_to_screen"):
			hud_ref.log_to_screen("Déplacement : %s" % dir)
	if _previous_gear != current_gear:
		emit_signal("gear_changed", current_gear)
		_previous_gear = current_gear
		if hud_ref and hud_ref.has_method("log_to_screen"):
			hud_ref.log_to_screen("Rapport : %d" % current_gear)

func _update_hud_state() -> void:
	if not hud_ref:
		return
	var speed_kmh := int(velocity.length() * 3.6)
	if hud_ref.has_method("update_speed"):
		hud_ref.update_speed(velocity.length(), speed_kmh)
	var dir := _get_direction_from_velocity()
	if hud_ref.has_method("update_movement_state"):
		hud_ref.update_movement_state(dir != "stopped", dir)
		
		



# ==========================================================
# HUD DEBUG MINIMAL
# ==========================================================



func _create_debug_hud() -> void:
	_debug_label = Label.new()
	_debug_label.name = "DebugHUD"
	_debug_label.position = Vector2(10, 10)
	_debug_label.theme_type_variation = "Monospace"
	_debug_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_debug_label.add_theme_font_size_override("font_size", 14)
	add_child(_debug_label)


func _update_debug_hud() -> void:
	if not debug_dashboard or _debug_label == null:
		return

	var left: float = left_track_speed
	var right: float = right_track_speed
	var avg: float = (left + right) * 0.5
	var speed_kmh: float = velocity.length() * 3.6
	var rot_deg: float = fmod(rad_to_deg(rotation), 360.0)


	_debug_label.text = "🧭 DEBUG TANK\n" + \
		"Left track:  %.2f\n" % left + \
		"Right track: %.2f\n" % right + \
		"Avg speed:   %.2f\n" % avg + \
		"Speed (km/h):%3.1f\n" % speed_kmh + \
		"Rotation:    %.1f°" % rot_deg
