### ============================================================
### TankController2D.gd — Version stable (Godot 4.5)
### Réaliste, inertiel, orienté Vector2.UP (canon vers le haut)
### ============================================================

extends CharacterBody2D
class_name TankController2D

### ------------------------------------------------------------
### PARAMÈTRES GÉNÉRAUX
### ------------------------------------------------------------
@export var DEBUG_LOGS: bool = false
@export var debug_dashboard: bool = false

# Physique générale
@export var mass: float = 5000.0
@export var drag: float = 10.0
@export var brake_power: float = 1600.0
@export var track_accel: float = 8800.0
@export var max_track_speed: float = 200.0
@export var visual_speed_factor: float = 4.0

# Inertie et rotation
@export var lateral_friction: float = 8.0
@export var angular_damping: float = 3.0
@export var rotational_inertia: float = 0.7
@export var rotation_gain: float = 0.004

### ------------------------------------------------------------
### MOTEUR ET TRANSMISSION
### ------------------------------------------------------------
@export var use_gearbox: bool = true
@export var use_engine_stall: bool = false
@export var engine_idle_rpm: float = 800.0
@export var engine_throttle_rpm_gain: float = 220.0
@export var engine_torque: float = 2000.0
@export var max_gears: int = 4

var engine_on: bool = true
var engine_rpm: float = engine_idle_rpm
var gear: int = 0  # Démarre au neutre
var gear_ratios := {
	-1: -0.5,
	 0:  0.0,
	 1:  0.25,
	 2:  0.45,
	 3:  0.7,
	 4:  1.0
}

### ------------------------------------------------------------
### ÉTAT DU JOUEUR
### ------------------------------------------------------------
var throttle: float = 0.0
var steer: float = 0.0
var brake: float = 0.0
var clutch_pressed: bool = false

### ------------------------------------------------------------
### CHENILLES ET MOUVEMENT
### ------------------------------------------------------------
var left_track_speed: float = 0.0
var right_track_speed: float = 0.0
var left_target_speed: float = 0.0
var right_target_speed: float = 0.0
var angular_velocity: float = 0.0
var is_moving: bool = false
var prev_is_moving: bool = false

### ------------------------------------------------------------
### HUD INTÉGRÉ
### ------------------------------------------------------------
var hud_label: Label
var debug_action_label: Label
var action_display_time: float = 0.0
@export var action_message_duration: float = 1.0

### ------------------------------------------------------------
### SIGNALS
### ------------------------------------------------------------
signal player_performed_action(action: String)

### ------------------------------------------------------------
### INITIALISATION
### ------------------------------------------------------------
func _ready() -> void:
	if debug_dashboard:
		# HUD principal
		hud_label = Label.new()
		hud_label.position = Vector2(10, 10)
		hud_label.theme_type_variation = "Monospace"
		add_child(hud_label)
		# HUD actions
		debug_action_label = Label.new()
		debug_action_label.position = Vector2(10, 80)
		debug_action_label.theme_type_variation = "Monospace"
		add_child(debug_action_label)

	if DEBUG_LOGS:
		print("Tank initialisé — boîte active :", use_gearbox)

	connect("player_performed_action", Callable(self, "_on_player_action"))

### ------------------------------------------------------------
### BOUCLE PRINCIPALE
### ------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_process_inputs()
	_update_engine(delta)
	_compute_track_targets()
	_update_tracks(delta)
	_apply_movement(delta)
	_update_hud_display()

	# Effacement progressif du message ACTION
	if debug_action_label and action_display_time > 0.0:
		action_display_time -= delta
		if action_display_time <= 0.0:
			debug_action_label.text = ""

### ------------------------------------------------------------
### INPUTS JOUEUR
### ------------------------------------------------------------
func _process_inputs() -> void:
	var s := 0.0
	if Input.is_action_pressed("steer_left"): s -= 1.0
	if Input.is_action_pressed("steer_right"): s += 1.0
	steer = clamp(s, -1.0, 1.0)

	# Gestion du régime moteur (accélérateur = Espace)
	var target_throttle := 0.0
	if Input.is_action_pressed("accelerate"):
		target_throttle = 1.0
	elif Input.is_action_pressed("reverse"):
		target_throttle = -1.0

	# Lissage pour simuler le temps de montée/descente du régime
	var throttle_response := 2.0  # vitesse de réponse moteur
	throttle = move_toward(throttle, target_throttle, throttle_response * get_physics_process_delta_time())


	brake = float(Input.is_action_pressed("brake"))
	clutch_pressed = Input.is_action_pressed("clutch")

	# Gestion boîte
	if Input.is_action_just_pressed("gear_up"):
		var prev = gear
		gear = clamp(gear + 1, -1, max_gears)
		if gear != prev: player_performed_action.emit("gear_up")

	if Input.is_action_just_pressed("gear_down"):
		var prev = gear
		gear = clamp(gear - 1, -1, max_gears)
		if gear != prev: player_performed_action.emit("gear_down")

	# Signaux d’action HUD_DEBUG
	if Input.is_action_just_pressed("accelerate"): player_performed_action.emit("forward")
	if Input.is_action_just_pressed("reverse"): player_performed_action.emit("backward")
	if Input.is_action_just_pressed("steer_left"): player_performed_action.emit("left")
	if Input.is_action_just_pressed("steer_right"): player_performed_action.emit("right")
	if Input.is_action_just_pressed("brake"): player_performed_action.emit("brake")
	if Input.is_action_just_pressed("clutch"): player_performed_action.emit("clutch_press")
	if Input.is_action_just_released("clutch"): player_performed_action.emit("clutch_release")

### ------------------------------------------------------------
### MOTEUR
### ------------------------------------------------------------

func _update_engine(delta: float) -> void:
	if not engine_on:
		engine_rpm = 0.0
		return

	# --- Simulation du régime moteur ---
	var rpm_target: float = engine_idle_rpm + throttle * 2000.0  # montée RPM
	engine_rpm = move_toward(engine_rpm, rpm_target, 1000.0 * delta)

	# --- Couple moteur dépend du régime ---
	var rpm_factor: float = clamp((engine_rpm - engine_idle_rpm) / 3000.0, 0.0, 1.0)
	var torque: float = engine_torque * rpm_factor

	# --- Transmission vers les chenilles ---
	if gear != 0 and not clutch_pressed:
		var ratio: float = gear_ratios.get(gear, 0.0)
		var drive_force: float = torque * ratio
		var drive_accel: float = drive_force / mass
		var direction: Vector2 = Vector2.UP.rotated(rotation)
		velocity -= direction * drive_accel * delta * visual_speed_factor

	# --- Calage éventuel ---
	if use_engine_stall and not clutch_pressed and gear != 0:
		if velocity.length() < 0.2 and absf(throttle) < 0.05:
			engine_on = false
			if DEBUG_LOGS:
				print("Moteur calé.")


### ------------------------------------------------------------
### TRANSMISSION / CHENILLES
### ------------------------------------------------------------
func _compute_track_targets() -> void:
	var ratio: float = gear_ratios.get(gear, 0.0)
	var can_drive: bool = engine_on and (gear != 0) and not clutch_pressed
	var base: float = 0.0

	if can_drive:
		base = throttle * max_track_speed * abs(ratio)
		if ratio < 0.0:
			base = -base
	else:
		base = 0.0  # au neutre ou embrayé = pas de propulsion

	# Contrôle différentiel (accélération par chenille)
	var left_input := throttle - steer
	var right_input := throttle + steer

	left_target_speed = clamp(left_input * ratio * max_track_speed, -max_track_speed, max_track_speed)
	right_target_speed = clamp(right_input * ratio * max_track_speed, -max_track_speed, max_track_speed)

### ------------------------------------------------------------
### INERTIE DES CHENILLES
### ------------------------------------------------------------
func _update_tracks(delta: float) -> void:
	left_track_speed = move_toward(left_track_speed, left_target_speed, track_accel * delta)
	right_track_speed = move_toward(right_track_speed, right_target_speed, track_accel * delta)

### ------------------------------------------------------------
### MOUVEMENT GLOBAL (physique inertielle)
### ------------------------------------------------------------
func _apply_movement(delta: float) -> void:
	var forward_speed := 0.5 * (left_track_speed + right_track_speed)
	var target_angular_velocity := (right_track_speed - left_track_speed) * rotation_gain
	angular_velocity = lerp(angular_velocity, target_angular_velocity, rotational_inertia)

	var _forward_dir := Vector2.UP.rotated(rotation)
	var local_velocity := velocity.rotated(-rotation)

	# Friction latérale
	local_velocity.x = move_toward(local_velocity.x, 0.0, lateral_friction * delta)

	# Frein moteur + inertie
	if absf(throttle) < 0.05 or gear == 0:
		local_velocity.y = move_toward(local_velocity.y, 0.0, drag * delta)
	else:
		local_velocity.y = move_toward(local_velocity.y, forward_speed * visual_speed_factor, track_accel * delta)

	velocity = local_velocity.rotated(rotation)
	
	# Évite les dérives parasites sur les axes très faibles
	if velocity.length() < 0.05:
		velocity = Vector2.ZERO

	

	if brake > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, brake_power * brake * delta)

	rotation += angular_velocity * delta
	angular_velocity = move_toward(angular_velocity, 0.0, angular_damping * delta)

	var collision := move_and_collide(velocity * delta)
	if collision:
		# On annule la composante de vitesse dans la normale de contact
		var n: Vector2 = collision.get_normal()
		velocity = velocity.slide(n) * 0.3  # perte d’énergie à l’impact


	is_moving = velocity.length() > 0.5
	if prev_is_moving and not is_moving:
		player_performed_action.emit("stop")
	prev_is_moving = is_moving

### ------------------------------------------------------------
### HUD_DEBUG
### ------------------------------------------------------------
func _update_hud_display() -> void:
	if not debug_dashboard or hud_label == null:
		return

	var speed_kmh := velocity.length() * 3.6
	var gear_name := "N" if gear == 0 else ("R" if gear < 0 else str(gear))
	hud_label.text = "SPD: %3.0f km/h\nGEAR: %s\nRPM: %4.0f\nTHR: %.1f" % [
		speed_kmh, gear_name, engine_rpm, throttle
	]

func _on_player_action(action: String) -> void:
	if debug_action_label:
		debug_action_label.text = "ACTION: %s" % action
		action_display_time = action_message_duration

### ------------------------------------------------------------
### UTILITAIRES
### ------------------------------------------------------------
func get_speed_kmh() -> float:
	return velocity.length() * 3.6

func restart_engine() -> void:
	if not engine_on:
		engine_on = true
		engine_rpm = engine_idle_rpm

### ------------------------------------------------------------
### ANIMATIONS (compatibilité InputAssigner)
### ------------------------------------------------------------
func play_animation(animation_name: String) -> void:
	var anim: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
	if anim and anim.has_animation(animation_name):
		anim.play(animation_name)
	elif DEBUG_LOGS:
		print("⚠️ Animation '%s' non trouvée." % animation_name)
