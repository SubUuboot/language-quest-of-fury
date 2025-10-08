# TankController2D.gd — drop-in pour remplacer Tank.gd (Godot 4,5, 2D)
extends CharacterBody2D
class_name TankController2D

# ======== Comportement modulable ========
@export var use_engine: bool = true          # faux => pilotage direct des chenilles par throttle
@export var use_gearbox: bool = true
@export var use_inertia: bool = true
@export var use_engine_stall: bool = false   # calage possible si on ne débraye pas à très basse vitesse

@export var DEBUG_LOGS := false
@export var debug_dashboard: bool = false    # à brancher plus tard sur un HUD technique

# ======== Paramètres physiques généraux ========
@export var mass := 5000.0                # kg fictifs (influence surtout l'intuition)
@export var drag := 10.0                     # frottements/roulement (vitesse revient lentement vers 0)
@export var brake_power := 1600.0             # frein principal (ui_accept)
@export var track_accel := 8800.0             # accélération des chenilles (m/s² “effectif”)
@export var max_track_speed := 200.0          # m/s par chenille à plein régime (avant ratio)
@export var rotation_gain := 0.004            # gain rotation = (vR - vL) * rotation_gain

# ======== Moteur + boîte ========
@export var engine_idle_rpm := 800.0
@export var engine_torque := 2000.0          # couple fictif
@export var engine_throttle_rpm_gain := 220.0
var engine_on := true
var engine_rpm := engine_idle_rpm

# -1=R, 0=N, 1..4
@export var max_gears := 4
var gear := 1
var gear_ratios := {
	-1: -0.6,
	 0:  0.0,
	 1:  0.45,
	 2:  0.65,
	 3:  0.85,
	 4:  1.0
}

# ======== État contrôle joueur ========
var throttle := 0.0      # -1..1 (ui_down..ui_up)
var steer := 0.0         # -1..1 (ui_left..ui_right)
var brake := 0.0         # 0..1
var clutch_pressed := false

# ======== Chenilles ========
var left_track_speed := 0.0       # vitesse actuelle m/s
var right_track_speed := 0.0
var left_target_speed := 0.0      # cible m/s
var right_target_speed := 0.0

# ======== État mouvement/HUD ========
var angular_velocity := 0.0
var is_moving := false
var prev_is_moving := false

# ======== Références de scène ========
@export var debug_menu_path: NodePath
@onready var debug_menu = %DebugMenu
@onready var cam_rig: Node2D = $CameraRig2D
@onready var cam: Camera2D = $CameraRig2D/Camera2D
@onready var sprite: Sprite2D = $HullBody
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var hud_path: NodePath
@onready var hud: Node = null

@export var orders_path: NodePath
@onready var orders_source: Node = null

# ======== Effets Visuels et Animations ========
@onready var exhaust_smoke: GPUParticles2D = $ExhaustSmoke

@export var camera_shake_intensity: float = 0.0	# 0 = off au démarrage (tu régleras en jeu)
@export var camera_zoom_base: float = 1.0			# zoom “de base” (1.0 = natif)
@export var camera_zoom_dynamic_gain: float = 0.10	# intensité du zoom auto selon la vitesse

# ======== Commandes (inchangé) ========
var commands: Dictionary = {
	"forward":  {"russian": "Вперёд!",    "pronunciation": "Вперёд!"},
	"backward": {"russian": "Назад!",     "pronunciation": "Назад!"},
	"left":     {"russian": "Налево!",    "pronunciation": "Налево!"},
	"right":    {"russian": "Направо!",   "pronunciation": "Направо!"},
	"faster":   {"russian": "Быстрее!",   "pronunciation": "Быстрее!"},
	"slower":   {"russian": "Медленнее!", "pronunciation": "Медленнее!"},
	"stop":     {"russian": "Стоп!",      "pronunciation": "Стоп!"},
	"climb":    {"russian": "Вверх!",     "pronunciation": "Vverkh!"},
	"cross":    {"russian": "Переправа!", "pronunciation": "Pereprava!"}
}

signal player_performed_action(action: String)

# ==========================================================
# =============== INITIALISATION ============================
# ==========================================================

func _ready() -> void:
	hud = get_node_or_null(hud_path)
	orders_source = get_node_or_null(orders_path)
	
	debug_menu.value_changed.connect(_on_debug_value_changed)
	debug_menu = get_node_or_null(debug_menu_path)
	if debug_menu and debug_menu.has_signal("value_changed"):
		debug_menu.connect("value_changed", Callable(self, "_on_debug_value_changed"))
	if cam:
		cam.make_current()

func _on_debug_value_changed(setting: String, value: float) -> void:
	match setting:
		"camera_shake":
			camera_shake_intensity = value
		"camera_zoom_base":
			camera_zoom_base = max(value, 0.01)

	if DEBUG_LOGS:
		print("Tank2D initialisé — HUD:", hud != null, " OrdersSource:", orders_source != null)

	if orders_source and orders_source.has_signal("command_given"):
		orders_source.connect("command_given", Callable(self, "_on_command_received"))

	if not use_gearbox:
		gear = 1

# ==========================================================
# =============== BOUCLE PRINCIPALE =========================
# ==========================================================

func _physics_process(delta: float) -> void:
	_process_inputs()
	_update_engine(delta)
	_compute_track_targets()
	_update_tracks(delta)
	_apply_movement(delta)
	_apply_inertia_tension(delta)
	_update_heat_distortion(delta)
	_update_exhaust(delta) 
	_apply_camera_shake(delta)
	_update_hud_display()

# ==========================================================
# =============== Inputs ====================================
# ==========================================================

func _process_inputs() -> void:
	# --- Steering ---
	var steer_strength: float = 0.0
	if InputMap.has_action("steer_left") and Input.is_action_pressed("steer_left"):
		steer_strength -= 1.0
	if InputMap.has_action("steer_right") and Input.is_action_pressed("steer_right"):
		steer_strength += 1.0
	steer = clamp(steer_strength, -1.0, 1.0)

	# --- Throttle / Accélérateur ---
	var throttle_strength: float = 0.0
	if InputMap.has_action("accelerate"):
		throttle_strength += Input.get_action_strength("accelerate")
	if InputMap.has_action("move_forward"): # compat ancien mapping
		throttle_strength += Input.get_action_strength("move_forward")
	throttle = clamp(throttle_strength, -1.0, 1.0)

	# --- Frein manuel ---
	var brake_strength: float = 0.0
	if InputMap.has_action("brake"):
		brake_strength = Input.get_action_strength("brake")
	brake = clamp(brake_strength, 0.0, 1.0)

	# --- Marche arrière ---
	# Si aucune touche "accelerate" n'est pressée et une "move_backward" existe
	if InputMap.has_action("move_backward"):
		if Input.is_action_pressed("move_backward"):
			throttle = -1.0

	# --- Embrayage / Boîte de vitesses ---
	clutch_pressed = false
	if InputMap.has_action("clutch"):
		clutch_pressed = Input.is_action_pressed("clutch")

	if use_gearbox and not clutch_pressed:
		if InputMap.has_action("gear_up") and Input.is_action_just_pressed("gear_up"):
			gear = clamp(gear + 1, -1, max_gears)
		if InputMap.has_action("gear_down") and Input.is_action_just_pressed("gear_down"):
			gear = clamp(gear - 1, -1, max_gears)

	# --- Émission d’actions pour compatibilité HUD / Commander ---
	if InputMap.has_action("steer_left") and Input.is_action_just_pressed("steer_left"):
		_show_command("left");  player_performed_action.emit("left")
	if InputMap.has_action("steer_right") and Input.is_action_just_pressed("steer_right"):
		_show_command("right"); player_performed_action.emit("right")
	if InputMap.has_action("accelerate") and Input.is_action_just_pressed("accelerate"):
		_show_command("forward"); player_performed_action.emit("forward")
	if InputMap.has_action("brake") and Input.is_action_just_pressed("brake"):
		_show_command("stop"); player_performed_action.emit("stop")


# ==========================================================
# =============== MOTEUR ===================================
# ==========================================================

func _update_engine(delta: float) -> void:
	if not use_engine:
		engine_on = true
		engine_rpm = engine_idle_rpm
		return

	if not engine_on:
		engine_rpm = 0.0
		return

	engine_rpm = max(engine_idle_rpm, engine_rpm + throttle * engine_throttle_rpm_gain * delta)

	if use_engine_stall and not clutch_pressed and gear != 0:
		var speed_abs := velocity.length()
		if speed_abs < 0.2 and absf(throttle) < 0.05:
			engine_on = false
			if DEBUG_LOGS:
				print("Moteur calé.")

# ==========================================================
# =============== TRANSMISSION / CHENILLES =================
# ==========================================================

func _compute_track_targets() -> void:
	var ratio := 1.0
	if use_gearbox:
		ratio = gear_ratios.get(gear, 0.0)

	var can_drive := engine_on and (not clutch_pressed) and (gear != 0 or not use_gearbox)
	var base := 0.0

	if use_engine:
		base = (throttle if can_drive else 0.0) * max_track_speed * abs(ratio)
		if ratio < 0.0:
			base = -base
	else:
		base = throttle * max_track_speed

	left_target_speed  = clamp(base * (1.0 - steer), -max_track_speed,  max_track_speed)
	right_target_speed = clamp(base * (1.0 + steer), -max_track_speed,  max_track_speed)

func _update_tracks(delta: float) -> void:
	left_track_speed  = move_toward(left_track_speed,  left_target_speed,  track_accel * delta)
	right_track_speed = move_toward(right_track_speed, right_target_speed, track_accel * delta)

# ==========================================================
# =============== MOUVEMENT GLOBAL =========================
# ==========================================================

func _apply_movement(delta: float) -> void:
	# --- Calculs de base ---
	var forward_speed: float = 0.5 * (left_track_speed + right_track_speed)
	var raw_turn_rate: float = (right_track_speed - left_track_speed)

	# Facteur de rotation dépendant de la vitesse :
	var turn_factor: float = 1.0 / (1.0 + abs(forward_speed) * 0.05)
	angular_velocity = raw_turn_rate * rotation_gain * turn_factor

	# --- Direction du tank (vecteur avant local) ---
	var forward_dir: Vector2 = Vector2.UP.rotated(rotation)

	# --- Dynamique du moteur / inertie ---
	var desired_velocity: Vector2 = forward_dir * forward_speed
	var resist_force: float = drag * delta

	# --- Moteur à régime libre : pas de frein automatique ---
	if absf(throttle) < 0.05:
		velocity = velocity.move_toward(Vector2.ZERO, resist_force)
	else:
		velocity = velocity.move_toward(desired_velocity, track_accel * delta)

	# --- Frein manuel ---
	if brake > 0.0:
		var brake_effect: float = brake_power * brake * delta
		velocity = velocity.move_toward(Vector2.ZERO, brake_effect)

	# --- Glissement latéral léger ---
	var skid_factor: float = clamp(abs(steer) * abs(forward_speed) * 0.003, 0.0, 0.25)
	velocity = velocity.lerp(forward_dir * forward_speed, 1.0 - skid_factor)

	# --- Rotation du tank ---
	rotation += angular_velocity * delta

	# --- Translation ---
	move_and_slide()

	# --- Effet visuel d’inertie / inclinaison du châssis ---
	if sprite:
		var tilt: float = clamp(-velocity.y * 0.0015, -0.05, 0.05)
		sprite.rotation = lerp_angle(sprite.rotation, tilt, 0.2)

	# --- État de mouvement (HUD / signaux) ---
	is_moving = velocity.length() > 1.0
	if prev_is_moving and not is_moving:
		player_performed_action.emit("stop")
	prev_is_moving = is_moving


# ==========================================================
# =========== effet moteur / tension visuelle ==============
# ==========================================================

func _apply_inertia_tension(delta: float) -> void:
	# --- Intensité de tension moteur ---
	var tension: float = abs(throttle) * clamp(engine_rpm / 4000.0, 0.3, 1.0)
	var speed_factor: float = clamp(velocity.length() / 25.0, 0.0, 1.0)

	# --- Vibrations moteur ---
	if sprite:
		var shake_amp: float = 1.0 * tension   # augmenté pour être visible
		var shake_offset: Vector2 = Vector2(
			randf_range(-shake_amp, shake_amp),
			randf_range(-shake_amp * 0.5, shake_amp * 0.5)
		)
		# Le delta rend la vibration plus fluide et dépendante du framerate
		sprite.position = sprite.position.lerp(shake_offset, 5.0 * delta)
	else:
		sprite.position = Vector2.ZERO

	# --- Bascule avant/arrière ---
	if sprite:
		var pitch_tilt: float = clamp(-throttle * 0.08 * (1.0 + speed_factor), -0.12, 0.12)
		sprite.rotation = lerp_angle(sprite.rotation, pitch_tilt, 4.0 * delta)

	# --- Son moteur (optionnel) ---
	if has_node("EngineSound"):
		var engine_audio: AudioStreamPlayer2D = $EngineSound
		if not engine_audio.playing:
			engine_audio.play()
		engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, 0.8 + tension * 0.5, 3.0 * delta)
		engine_audio.volume_db = lerp(engine_audio.volume_db, -8.0 + tension * 4.0, 3.0 * delta)



func _update_heat_distortion(_delta: float) -> void:
	if not has_node("HeatDistortion"):
		return
	var node: Sprite2D = $HeatDistortion
	if node.material is ShaderMaterial:
		var mat: ShaderMaterial = node.material
		var tension: float = abs(throttle) * clamp(engine_rpm / 4000.0, 0.3, 1.0)
		# Option: booster un peu pour que ça se voie
		var k: float = 1.0
		mat.set_shader_parameter("strength", clamp(tension * k, 0.0, 1.0))





var prev_throttle: float = 0.0  # à mettre en haut du script, dans les variables du tank

func _update_exhaust(_delta: float) -> void:
	if not exhaust_smoke:
		return

	# Ne rien faire si le moteur est coupé
	exhaust_smoke.emitting = engine_on
	if not engine_on:
		return

	if exhaust_smoke.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = exhaust_smoke.process_material

		# --- Intensité moteur ---
		var tension: float = abs(throttle) * clamp(engine_rpm / 4000.0, 0.2, 1.0)

		# --- Ajuste la densité en continu ---
		var target_amount := int(60 + 240 * tension)
		exhaust_smoke.amount = lerp(exhaust_smoke.amount, target_amount, 0.3)

		# --- Taille et opacité ---
		mat.scale_min = 0.7
		mat.scale_max = 1.3 + tension * 0.8

		var idle_col = Color(0.18, 0.18, 0.18, 0.5)  # gris discret
		var boost_col = Color(0.05, 0.05, 0.05, 0.95) # presque noir
		mat.color = idle_col.lerp(boost_col, tension)
		
		if engine_on and engine_rpm < 1000.0:
			mat.color = Color(0.1, 0.1, 0.25, 0.6)  # légère teinte bleue

		# --- Bouffée noire lors d’un gros coup de gaz ---
		if throttle - prev_throttle > 0.6 and throttle > 0.7:
			exhaust_smoke.amount += 80 + randi_range(20, 60)   # panache plus dense
			mat.color = Color(0.02, 0.02, 0.02, 1.0)           # noir instantané
			exhaust_smoke.lifetime = 20.0
			exhaust_smoke.explosiveness = 0.90

	prev_throttle = throttle  # sauvegarde pour le prochain cycle



func _apply_camera_shake(delta: float) -> void:
	if not cam_rig or not cam:
		return

	# “Charge” actuelle : throttle + régime + vitesse
	var tension: float = abs(throttle) * clamp(engine_rpm / 4000.0, 0.3, 1.0)
	var speed_factor: float = clamp(velocity.length() / 25.0, 0.0, 1.0)

	# Intensité de secousse finale = curseur joueur * dynamique moteur
	var core: float = 1.0 + tension * 2.0 + speed_factor * 0.8
	var total_intensity: float = camera_shake_intensity * core

	# Secousse (en pixels) sur le rig
	var shake_amp: float = total_intensity * 8.0
	var target: Vector2 = Vector2(
		randf_range(-shake_amp, shake_amp),
		randf_range(-shake_amp * 0.6, shake_amp * 0.6)
	)
	cam_rig.position = cam_rig.position.lerp(target, 20.0 * delta)

	# Zoom = base * (zoom dynamique selon la vitesse)
	var dyn_zoom: float = clamp(1.0 - (speed_factor * camera_zoom_dynamic_gain), 0.85, 1.0)
	var zoom_target: Vector2 = Vector2.ONE * (camera_zoom_base * dyn_zoom)
	cam.zoom = cam.zoom.lerp(zoom_target, 4.0 * delta)

	# Si quasi immobile, recentre doucement le rig (confort visuel)
	if velocity.length() < 0.1:
		cam_rig.position = cam_rig.position.move_toward(Vector2.ZERO, 10.0 * delta)





# ==========================================================
# =============== HUD & ORDERS =============================
# ==========================================================

func _show_command(key: String) -> void:
	if commands.has(key) and hud and hud.has_method("show_command"):
		var cmd = commands[key]
		hud.show_command(cmd["russian"], cmd["pronunciation"])

func _on_command_received(command: String) -> void:
	if DEBUG_LOGS:
		print("Commande reçue:", command)
	if commands.has(command) and hud and hud.has_method("show_commander_command"):
		var cmd = commands[command]
		hud.show_commander_command(cmd["russian"], cmd["pronunciation"])

func _update_hud_display() -> void:
	if hud:
		if hud.has_method("update_speed"):
			hud.update_speed(velocity.length(), get_speed_kmh())
		if hud.has_method("update_movement_state"):
			hud.update_movement_state(is_moving)
		if hud.has_method("update_transmission"):
			hud.update_transmission(gear, engine_on, engine_rpm, clutch_pressed)
		if hud.has_method("update_tracks"):
			hud.update_tracks(left_track_speed, right_track_speed, steer, throttle)

# ==========================================================
# =============== API PUBLIQUE =============================
# ==========================================================

func get_current_speed() -> float:
	return velocity.length()

func get_speed_kmh() -> int:
	return int(round(velocity.length() * 3.6))

func restart_engine():
	if not engine_on:
		engine_on = true
		engine_rpm = engine_idle_rpm
		
func play_animation(anim_name: String) -> void:
	var anim = $AnimationPlayer
	if anim and anim.has_animation(anim_name):
		anim.play(anim_name)
