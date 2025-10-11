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

func _process_inputs(delta: float) -> void:
	var accel_input := Input.get_action_strength(input_accelerate)
	var brake_input := Input.get_action_strength(input_brake)
	var steer_left := Input.is_action_pressed(input_steer_left)
	var steer_right := Input.is_action_pressed(input_steer_right)
	var gear_up := Input.is_action_just_pressed(input_gear_up)
	var gear_down := Input.is_action_just_pressed(input_gear_down)
	
	if accel_input > 0.1:
		emit_signal("action_performed", "accelerate")
	if brake_input > 0.1:
		emit_signal("action_performed", "brake")
	if steer_left:
		emit_signal("action_performed", "turn_left")
	if steer_right:
		emit_signal("action_performed", "turn_right")


	if gear_up:
		current_gear = clamp(current_gear + 1, -1, gear_ratios.size() - 1)
		emit_signal("gear_changed", current_gear)
	if gear_down:
		current_gear = clamp(current_gear - 1, -1, gear_ratios.size() - 1)
		emit_signal("gear_changed", current_gear)

	if steer_left:
		rotation -= rotation_speed * delta
	if steer_right:
		rotation += rotation_speed * delta

	# ✅ Typage explicite du ratio
	var gear_ratio: float = 0.0
	if current_gear + 1 < gear_ratios.size():
		gear_ratio = float(gear_ratios[current_gear + 1])

	var _max_speed := max_speed_forward if gear_ratio >= 0 else max_speed_reverse
	current_engine_force = acceleration * accel_input * sign(gear_ratio)

	if brake_input > 0.1:
		current_engine_force = 0.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func _physics_process(delta: float) -> void:
	_process_inputs(delta)
	var forward := transform.x.normalized()
	velocity += forward * current_engine_force * delta

	var speed_limit := (max_speed_forward if current_gear >= 0 else max_speed_reverse)
	if velocity.length() > speed_limit:
		velocity = velocity.normalized() * speed_limit

	if current_engine_force == 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_direction_and_notify()
	_update_hud_state()

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
