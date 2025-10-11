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
	var accel_input: float = Input.get_action_strength(input_accelerate)
	var brake_input: float = Input.get_action_strength(input_brake)
	var steer_left: bool = Input.is_action_pressed(input_steer_left)
	var steer_right: bool = Input.is_action_pressed(input_steer_right)
	var gear_up: bool = Input.is_action_just_pressed(input_gear_up)
	var gear_down: bool = Input.is_action_just_pressed(input_gear_down)

	# --- Signaux d’action ---
	if accel_input > 0.1:
		emit_signal("action_performed", "accelerate")
	if brake_input > 0.1:
		emit_signal("action_performed", "brake")
	if steer_left:
		emit_signal("action_performed", "turn_left")
	if steer_right:
		emit_signal("action_performed", "turn_right")

	# --- Gestion de la boîte ---
	if gear_up:
		current_gear = clamp(current_gear + 1, 0, gear_ratios.size() - 1)
		emit_signal("gear_changed", current_gear)
	if gear_down:
		current_gear = clamp(current_gear - 1, 0, gear_ratios.size() - 1)
		emit_signal("gear_changed", current_gear)

	# --- Calcul du couple moteur ---
	var gear_ratio: float = float(gear_ratios[current_gear])
	var has_traction: bool = absf(gear_ratio) > 0.001
	var throttle_force: float = acceleration * accel_input * gear_ratio

	# Simule le comportement moteur (inertie + montée progressive)
	var target_force: float = throttle_force
	current_engine_force = lerp(current_engine_force, target_force, 2.5 * delta)

	# --- Rotation réaliste : dépendante du mouvement ---
	var steer_input: float = 0.0
	if steer_left: steer_input -= 1.0
	if steer_right: steer_input += 1.0

	# On ne peut tourner que si le moteur entraîne les chenilles
	if has_traction and accel_input > 0.05:
		rotation += steer_input * rotation_speed * delta * sign(gear_ratio)

	# --- Frein manuel ---
	if brake_input > 0.1:
		current_engine_force = 0.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)




func _physics_process(delta: float) -> void:
	_process_inputs(delta)

	var forward: Vector2 = -transform.y.normalized()

	# Appliquer la poussée moteur uniquement si un rapport est engagé
	if absf(float(gear_ratios[current_gear])) > 0.001:
		velocity += forward * current_engine_force * delta
	else:
		# point mort = perte de vitesse naturelle (roue libre)
		velocity = velocity.move_toward(Vector2.ZERO, friction * 0.5 * delta)

	var speed_limit: float = absf(float(gear_ratios[current_gear])) * max_speed_forward
	if velocity.length() > speed_limit:
		velocity = velocity.normalized() * speed_limit

	# Friction naturelle si moteur au ralenti
	if absf(current_engine_force) < 0.001:
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
