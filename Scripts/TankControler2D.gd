### ============================================================
### TankController2D.gd — Version refactorisée (Godot 4.5)
### Objectif : comportement réaliste de tank à chenilles indépendantes
### ============================================================

extends CharacterBody2D
class_name TankController2D

### ------------------------------------------------------------
### PARAMÈTRES GÉNÉRAUX (exposés à l’éditeur)
### ------------------------------------------------------------
@export var DEBUG_LOGS: bool = false
@export var debug_dashboard: bool = false	# affichage HUD intégré minimal

### === Physique et échelle visuelle ===
@export var mass: float = 5000.0				# masse fictive
@export var drag: float = 10.0					# résistance inertielle (faible = plus d'inertie)
@export var brake_power: float = 1600.0			# frein principal
@export var track_accel: float = 8800.0			# accélération des chenilles
@export var max_track_speed: float = 200.0		# vitesse max réelle (m/s)
@export var visual_speed_factor: float = 4.0	# multiplicateur visuel pour compenser les échelles de scène
@export var lateral_friction: float = 8.0		# force qui empêche la dérive latérale
@export var angular_damping: float = 3.0			# vitesse à laquelle la rotation ralentit
@export var rotational_inertia: float = 0.7		# 0 = pas d'inertie, 1 = conserve tout le mouvement


### === Moteur + boîte ===
@export var use_gearbox: bool = true
@export var use_engine_stall: bool = false
@export var engine_idle_rpm: float = 800.0
@export var engine_throttle_rpm_gain: float = 220.0
@export var engine_torque: float = 2000.0
@export var max_gears: int = 4
@export var rotation_gain: float = 0.004			# rotation du châssis = (vR - vL) * rotation_gain

var engine_on: bool = true
var engine_rpm: float = engine_idle_rpm
var gear: int = 1
var gear_ratios: Dictionary = {
	-1: -0.5,
	 0:  0.0,
	 1:  0.25,
	 2:  0.45,
	 3:  0.7,
	 4:  1.0
}

### === États du joueur ===
var throttle: float = 0.0		# -1..1
var steer: float = 0.0			# -1..1
var brake: float = 0.0			# 0..1
var clutch_pressed: bool = false

### === Chenilles ===
var left_track_speed: float = 0.0
var right_track_speed: float = 0.0
var left_target_speed: float = 0.0
var right_target_speed: float = 0.0

### === Mouvement global ===
var angular_velocity: float = 0.0
var is_moving: bool = false
var prev_is_moving: bool = false

### === HUD intégré minimal ===
var hud_label: Label
var debug_action_label: Label				# label secondaire pour les actions
var action_display_time: float = 0.0			# chrono restant avant effacement
@export var action_message_duration: float = 1.0	# durée d’affichage du message HUD_DEBUG



### ------------------------------------------------------------
### SIGNALS
### ------------------------------------------------------------
signal player_performed_action(action: String)



### ------------------------------------------------------------
### INITIALISATION
### ------------------------------------------------------------


func _ready() -> void:
	# --- HUD minimal existant ---
	if debug_dashboard:
		hud_label = Label.new()
		hud_label.position = Vector2(10, 10)
		hud_label.theme_type_variation = "Monospace"
		add_child(hud_label)

		# --- HUD_Debug secondaire : actions signalées ---
		debug_action_label = Label.new()
		debug_action_label.position = Vector2(10, 80)
		debug_action_label.theme_type_variation = "Monospace"
		add_child(debug_action_label)
		
	if DEBUG_LOGS:
		print("Tank initialisé avec HUD:", debug_dashboard)

	# --- Connexion du signal interne pour affichage ---
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
	
		# --- Gestion du HUD_DEBUG temporaire ---
	if debug_action_label and action_display_time > 0.0:
		action_display_time -= delta
		if action_display_time <= 0.0:
			debug_action_label.text = ""



### ------------------------------------------------------------
### INPUTS JOUEUR — version enrichie (AZERTY / actions signalées)
### ------------------------------------------------------------
func _process_inputs() -> void:
	# --- Direction (leviers ou palonniers) ---
	var s: float = 0.0
	if Input.is_action_pressed("steer_left"): s -= 1.0
	if Input.is_action_pressed("steer_right"): s += 1.0
	steer = clamp(s, -1.0, 1.0)

	# --- Accélérateur / régime moteur ---
	var t: float = 0.0
	if Input.is_action_pressed("accelerate"): t += 1.0
	if Input.is_action_pressed("reverse"): t -= 1.0
	throttle = clamp(t, -1.0, 1.0)

	# --- Frein / embrayage ---
	brake = float(Input.is_action_pressed("brake"))
	clutch_pressed = Input.is_action_pressed("clutch")

	# --- Gestion de la boîte de vitesses ---
	if Input.is_action_just_pressed("gear_up"):
		var prev = gear
		gear = clamp(gear + 1, -1, max_gears)
		if gear != prev:
			player_performed_action.emit("gear_up")
			if DEBUG_LOGS: print("↑ Passage au rapport ", gear)

	if Input.is_action_just_pressed("gear_down"):
		var prev = gear
		gear = clamp(gear - 1, -1, max_gears)
		if gear != prev:
			player_performed_action.emit("gear_down")
			if DEBUG_LOGS: print("↓ Rapport descendu à ", gear)

	# --- Émissions de signaux d’action pour HUD_DEBUG ---
	if Input.is_action_just_pressed("steer_left"):
		player_performed_action.emit("left")
	elif Input.is_action_just_pressed("steer_right"):
		player_performed_action.emit("right")

	if Input.is_action_just_pressed("accelerate"):
		player_performed_action.emit("forward")
	elif Input.is_action_just_released("accelerate"):
		player_performed_action.emit("coast")

	if Input.is_action_just_pressed("reverse"):
		player_performed_action.emit("backward")

	if Input.is_action_just_pressed("brake"):
		player_performed_action.emit("brake")

	if Input.is_action_pressed("clutch") and not clutch_pressed:
		player_performed_action.emit("clutch_press")
	elif Input.is_action_just_released("clutch"):
		player_performed_action.emit("clutch_release")

	# --- Log optionnel pour debug ---
	if DEBUG_LOGS:
		if throttle != 0.0 or steer != 0.0:
			print("Throttle:", throttle, " Steer:", steer, " Gear:", gear)


### ------------------------------------------------------------
### MOTEUR ET COUPLE
### ------------------------------------------------------------
func _update_engine(delta: float) -> void:
	if not engine_on:
		engine_rpm = 0.0
		return
	
	# régime = ralenti + charge
	engine_rpm = max(engine_idle_rpm, engine_rpm + throttle * engine_throttle_rpm_gain * delta)
	
	# simulation de calage
	if use_engine_stall and not clutch_pressed and gear != 0:
		if velocity.length() < 0.2 and absf(throttle) < 0.05:
			engine_on = false
			if DEBUG_LOGS: print("Moteur calé.")

### ------------------------------------------------------------
### TRANSMISSION / CHENILLES
### ------------------------------------------------------------
func _compute_track_targets() -> void:
	var ratio: float = gear_ratios.get(gear, 0.0)
	var can_drive: bool = engine_on and (gear != 0)
	var base: float = 0.0

	if can_drive:
		base = throttle * max_track_speed * abs(ratio)
		if ratio < 0.0:
			base = -base
	
	# Contrôle différentiel complet :
	#   - steer = manette en ciseaux : gauche ↔ droite
	#   - throttle = manettes en avant/arrière
	var left_input: float = throttle - steer
	var right_input: float = throttle + steer
	
	left_target_speed = clamp(left_input * abs(ratio) * max_track_speed, -max_track_speed, max_track_speed)
	right_target_speed = clamp(right_input * abs(ratio) * max_track_speed, -max_track_speed, max_track_speed)

### ------------------------------------------------------------
### MISE À JOUR DES CHENILLES (inertie)
### ------------------------------------------------------------
func _update_tracks(delta: float) -> void:
	left_track_speed = move_toward(left_track_speed, left_target_speed, track_accel * delta)
	right_track_speed = move_toward(right_track_speed, right_target_speed, track_accel * delta)

### ------------------------------------------------------------
### MOUVEMENT GLOBAL — version améliorée (physique inertielle)
### ------------------------------------------------------------
func _apply_movement(delta: float) -> void:
	# --- Calcul de la vitesse résultante des chenilles ---
	# Moyenne des vitesses de chenilles = propulsion avant / arrière
	var forward_speed: float = 0.5 * (left_track_speed + right_track_speed)

	# Différence des vitesses de chenilles = rotation du châssis
	var target_angular_velocity: float = (right_track_speed - left_track_speed) * rotation_gain

	# Interpolation progressive de la rotation (inertie angulaire)
	angular_velocity = lerp(angular_velocity, target_angular_velocity, rotational_inertia)

	# --- Conversion de la vitesse locale en direction du tank ---
	var forward_dir: Vector2 = Vector2.UP.rotated(rotation)
	var _right_dir: Vector2 = Vector2.RIGHT.rotated(rotation)

	# Construction du vecteur vitesse cible (avant seulement)
	var desired_velocity: Vector2 = forward_dir * forward_speed * visual_speed_factor

	# --- Gestion de l’inertie linéaire ---
	# On travaille dans le repère local pour séparer la friction longitudinale et latérale.
	var local_velocity: Vector2 = velocity.rotated(-rotation)

	# Appliquer la friction latérale (forte résistance au glissement de côté)
	local_velocity.x = move_toward(local_velocity.x, 0.0, lateral_friction * delta)

	# Appliquer une friction longitudinale douce (frein moteur)
	if absf(throttle) < 0.05:
		local_velocity.y = move_toward(local_velocity.y, 0.0, drag * 0.2 * delta)
	else:
		local_velocity.y = move_toward(local_velocity.y, desired_velocity.length(), track_accel * delta)

	# --- Reconversion en coordonnées monde ---
	velocity = local_velocity.rotated(rotation)

	# --- Frein manuel ---
	if brake > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, brake_power * brake * delta)

	# --- Application de la rotation et amortissement progressif ---
	rotation += angular_velocity * delta
	angular_velocity = move_toward(angular_velocity, 0.0, angular_damping * delta)

	# --- Mouvement final ---
	move_and_slide()

	# --- État de mouvement (pour HUD / événements) ---
	is_moving = velocity.length() > 0.5
	if prev_is_moving and not is_moving:
		player_performed_action.emit("stop")
	prev_is_moving = is_moving


### ------------------------------------------------------------
### HUD INTÉGRÉ (pour test uniquement)
### ------------------------------------------------------------
func _update_hud_display() -> void:
	if not debug_dashboard or hud_label == null:
		return
	
	var speed_kmh: float = velocity.length() * 3.6
	var gear_name: String = "N" if gear == 0 else ("R" if gear < 0 else str(gear))
	
	hud_label.text = "SPD: %3.0f km/h\nGEAR: %s\nRPM: %4.0f\nTHR: %.1f" % [
		speed_kmh,
		gear_name,
		engine_rpm,
		throttle
	]

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
### ANIMATIONS (compatibilité avec InputAssigner)
### ------------------------------------------------------------
func play_animation(animation_name: String) -> void:
	var anim: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
	if anim and anim.has_animation(animation_name):
		anim.play(animation_name)
	elif DEBUG_LOGS:
		print("⚠️ Animation '%s' non trouvée." % animation_name)


### ------------------------------------------------------------
### CALLBACKS HUD_DEBUG
### ------------------------------------------------------------
### ------------------------------------------------------------
### CALLBACKS HUD_DEBUG
### ------------------------------------------------------------
func _on_player_action(action: String) -> void:
	if debug_action_label:
		debug_action_label.text = "ACTION: %s" % action
		action_display_time = action_message_duration	# redémarre le chrono d’affichage
