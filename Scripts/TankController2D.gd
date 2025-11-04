extends CharacterBody2D
class_name TankController2D

signal moved(direction: String)
signal gear_changed(gear: int)
signal action_performed(action: String)

# ------------------------------------------------------------
# PHYSIQUE ET PARAMÈTRES DE COMPORTEMENT
# ------------------------------------------------------------
@export var mass: float = 5000.0
@export var drag: float = 2.5
@export var track_accel: float = 8.0
@export var max_track_speed: float = 12.0
@export var rotation_gain: float = 0.05
@export var friction: float = 2.5
@export var visual_speed_factor: float = 128.0
@export var brake_power: float = 12.0

# ------------------------------------------------------------
# MOTEUR ET TRANSMISSION
# ------------------------------------------------------------
@export var engine_idle_rpm: float = 800.0
@export var engine_max_rpm: float = 2400.0
@export var engine_throttle_rpm_gain: float = 600.0
@export var engine_rpm_decay: float = 150.0
@export var engine_torque_max: float = 2000.0
@export var use_engine_stall: bool = true

@export var gear_ratios: Dictionary = {
	-1: -0.6,
	 0:  0.0,
	 1:  0.4,
	 2:  0.6,
	 3:  0.8,
	 4:  1.0
}

var engine_on: bool = true
var engine_rpm: float = engine_idle_rpm
var prev_engine_rpm: float = engine_idle_rpm
var clutch_pressed: bool = false
var current_gear: int = 0
var max_gears: int = 4

# ------------------------------------------------------------
# ÉTAT DE CONTRÔLE JOUEUR / DEBUG
# ------------------------------------------------------------
var input_enabled: bool = true  # permet de suspendre toutes les entrées joueur

# ------------------------------------------------------------
# INPUTS
# ------------------------------------------------------------
@export var input_accelerate: String = "accelerate"     # Espace (par ex.)
@export var input_brake: String = "brake"               # Ctrl
@export var input_steer_left: String = "steer_left"     # Q
@export var input_steer_right: String = "steer_right"   # D
@export var input_gear_up: String = "gear_up"           # + num
@export var input_gear_down: String = "gear_down"       # Entrée num
@export var input_clutch: String = "clutch"             # 0 num
@export var input_engine_start: String = "engine_start" # E

# ------------------------------------------------------------
# CHENILLES
# ------------------------------------------------------------
var left_track_speed: float = 0.0
var right_track_speed: float = 0.0
var left_target_speed: float = 0.0
var right_target_speed: float = 0.0

# ------------------------------------------------------------
# HUD DEBUG
# ------------------------------------------------------------
@export var debug_dashboard: bool = true
var _debug_label: Label
var _rpm_bar: ProgressBar
var _clutch_bar: ProgressBar
var _engine_brake_bar: ProgressBar
var _engine_status_label: Label

@export var devtools_path: NodePath = NodePath("../../HUDLayer/DevTools")
@onready var devtools: Node = get_node_or_null(devtools_path)

# ------------------------------------------------------------
# INITIALISATION
# ------------------------------------------------------------
func _ready() -> void:
	add_to_group("tank")
	if debug_dashboard:
		_create_debug_hud()

	# 🔗 Connexion optionnelle au DevTools
	if devtools and devtools.has_signal("devtools_toggled"):
		if not devtools.is_connected("devtools_toggled", Callable(self, "_on_devtools_toggled")):
			devtools.connect("devtools_toggled", Callable(self, "_on_devtools_toggled"))
		print("🧭 Tank connecté à DevTools (devtools_toggled).")
	else:
		print("ℹ️ DevTools absent ou sans signal — le Tank fonctionne en autonome.")

	print("✅ Tank initialisé avec couple moteur, calage et freinage différentiel.")





# ------------------------------------------------------------
# CONTRÔLE D’ENTRÉE EXTERNE
# ------------------------------------------------------------
func set_input_enabled(enable: bool) -> void:
	input_enabled = enable
	if not enable:
		# Purge des entrées tamponnées pour éviter les “fantômes”
		Input.flush_buffered_events()

func _on_devtools_toggled(is_open: bool) -> void:
	set_input_enabled(not is_open)
	print("🎛️ DevTools toggled → Tank input_enabled =", not is_open)

# ------------------------------------------------------------
# COURBE DE COUPLE MOTEUR
# ------------------------------------------------------------
func get_engine_torque_at_rpm(rpm: float) -> float:
	if rpm < 800.0:
		return 0.0
	elif rpm < 1600.0:
		return lerp(400.0, engine_torque_max, (rpm - 800.0) / 800.0)
	elif rpm < 2400.0:
		return lerp(engine_torque_max, 1000.0, (rpm - 1600.0) / 800.0)
	return 800.0

# ------------------------------------------------------------
# INPUTS JOUEUR
# ------------------------------------------------------------
func _process_inputs(delta: float) -> void:
	if not input_enabled:
		return

	var throttle_input: float = Input.get_action_strength(input_accelerate)
	var brake_input: float = Input.get_action_strength(input_brake)
	var turn_left: float = Input.get_action_strength(input_steer_left)
	var turn_right: float = Input.get_action_strength(input_steer_right)
	clutch_pressed = Input.is_action_pressed(input_clutch)

	# Démarrage moteur
	if Input.is_action_just_pressed(input_engine_start) and not engine_on:
		engine_on = true
		engine_rpm = engine_idle_rpm
		print("🔑 Moteur redémarré.")

	# Gestion des rapports (embrayage requis)
	if Input.is_action_just_pressed(input_gear_up) and clutch_pressed:
		current_gear = clamp(current_gear + 1, -1, max_gears)
		emit_signal("gear_changed", current_gear)
	elif Input.is_action_just_pressed(input_gear_down) and clutch_pressed:
		current_gear = clamp(current_gear - 1, -1, max_gears)
		emit_signal("gear_changed", current_gear)

	# Moteur à l'arrêt
	if not engine_on:
		engine_rpm = 0.0
		return

	# Gestion RPM moteur
	prev_engine_rpm = engine_rpm
	if throttle_input > 0.01:
		engine_rpm += engine_throttle_rpm_gain * throttle_input * delta
	else:
		engine_rpm -= engine_rpm_decay * delta

	# Ralenti et plafond
	if engine_rpm < engine_idle_rpm and engine_on:
		engine_rpm = move_toward(engine_rpm, engine_idle_rpm, engine_rpm_decay * delta)
	if engine_rpm > engine_max_rpm:
		engine_rpm = engine_max_rpm

	# Détermination du couple dispo
	var torque: float = get_engine_torque_at_rpm(engine_rpm)
	var ratio: float = gear_ratios.get(current_gear, 0.0)
	var _drive_force: float = torque * ratio

	left_target_speed = 0.0
	right_target_speed = 0.0

	# Si l’embrayage est enfoncé, pas de transmission
	var can_drive: bool = engine_on and (not clutch_pressed) and ratio != 0.0
	if can_drive:
		var drive_accel: float = (engine_rpm / engine_max_rpm) * max_track_speed * absf(ratio)
		if ratio < 0.0:
			drive_accel = -drive_accel
		left_target_speed = drive_accel
		right_target_speed = drive_accel

	# Rotation différentielle
	if current_gear != 0:
		if turn_left > 0.0:
			left_target_speed -= max_track_speed
			right_target_speed += max_track_speed
		elif turn_right > 0.0:
			left_target_speed += max_track_speed
			right_target_speed -= max_track_speed

	# Freinage différentiel clavier
	if brake_input > 0.0:
		if turn_left > 0.0:
			right_track_speed = move_toward(right_track_speed, 0.0, brake_power * delta)
		elif turn_right > 0.0:
			left_track_speed = move_toward(left_track_speed, 0.0, brake_power * delta)
		else:
			left_track_speed = move_toward(left_track_speed, 0.0, brake_power * delta)
			right_track_speed = move_toward(right_track_speed, 0.0, brake_power * delta)

	# Lissage inertiel
	left_track_speed = move_toward(left_track_speed, left_target_speed, track_accel * delta)
	right_track_speed = move_toward(right_track_speed, right_target_speed, track_accel * delta)

	# Calage moteur si charge excessive
	if use_engine_stall and not clutch_pressed and current_gear != 0:
		var load_ratio: float = absf(velocity.length()) / (max_track_speed * absf(ratio) + 0.01)
		if load_ratio > 1.2 and engine_rpm < 900.0:
			engine_on = false
			engine_rpm = 0.0
			print("💀 Moteur calé (surcharge mécanique).")

	# Coup de transmission brutal
	if not clutch_pressed and absf(engine_rpm - prev_engine_rpm) > 400.0:
		velocity += Vector2.UP.rotated(rotation) * sign(engine_rpm - prev_engine_rpm) * 0.5
		print("⚡ Accoup moteur ressenti.")

# ------------------------------------------------------------
# PHYSIQUE DU DÉPLACEMENT
# ------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# 🧱 Neutralisation douce quand les inputs sont désactivés (DevTools / menu ouverts)
	if not input_enabled:
		left_target_speed = move_toward(left_target_speed, 0.0, drag * delta)
		right_target_speed = move_toward(right_target_speed, 0.0, drag * delta)
		left_track_speed = move_toward(left_track_speed, 0.0, friction * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, friction * delta)
		velocity = velocity.move_toward(Vector2.ZERO, brake_power * 0.5 * delta)
		move_and_slide()
		_update_debug_hud()
		return

	# --- comportement normal ---
	_process_inputs(delta)

	var forward_speed: float = (left_track_speed + right_track_speed) * 0.5 * visual_speed_factor
	var rotation_speed_local: float = (right_track_speed - left_track_speed) * rotation_gain

	var forward_dir: Vector2 = Vector2.UP.rotated(rotation)
	velocity = forward_dir * forward_speed
	rotation += rotation_speed_local * delta

	_apply_engine_brake(delta)

	# Friction naturelle (à l'arrêt ou sans input)
	if absf(left_target_speed) < 0.1 and absf(right_target_speed) < 0.1:
		left_track_speed = move_toward(left_track_speed, 0.0, drag * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, drag * delta)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_debug_hud()

# ------------------------------------------------------------
# FREIN MOTEUR / CALAGE
# ------------------------------------------------------------
func _apply_engine_brake(delta: float) -> void:
	# Si moteur calé → frein moteur fort
	if not engine_on:
		var brake_strength: float = clamp(velocity.length() * 4.0, 0.0, 60.0)
		velocity = velocity.move_toward(Vector2.ZERO, brake_strength * delta)
		left_track_speed = move_toward(left_track_speed, 0.0, brake_strength * 0.5 * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, brake_strength * 0.5 * delta)
		return

	# Si moteur allumé mais faible RPM → frein moteur progressif (embrayage relâché)
	if current_gear != 0 and not clutch_pressed:
		var rpm_factor: float = 1.0 - ((engine_rpm - engine_idle_rpm) / (engine_max_rpm - engine_idle_rpm))
		rpm_factor = clamp(rpm_factor, 0.0, 1.0)
		var gear_factor: float = 1.0 + absf(float(current_gear)) * 0.3
		var engine_brake_strength: float = rpm_factor * gear_factor * 8.0

		velocity = velocity.move_toward(Vector2.ZERO, engine_brake_strength * delta)
		left_track_speed = move_toward(left_track_speed, 0.0, engine_brake_strength * 0.4 * delta)
		right_track_speed = move_toward(right_track_speed, 0.0, engine_brake_strength * 0.4 * delta)

# ==========================================================
# HUD DEBUG — version organisée et lisible
# ==========================================================
func _create_debug_hud() -> void:
	var hud_container := VBoxContainer.new()
	hud_container.name = "DebugHUD"
	hud_container.position = Vector2(10, 10)
	hud_container.add_theme_constant_override("separation", 6)
	add_child(hud_container)

	# --- Label principal ---
	_debug_label = Label.new()
	_debug_label.theme_type_variation = "Monospace"
	_debug_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_debug_label.add_theme_font_size_override("font_size", 14)
	hud_container.add_child(_debug_label)

	# --- Barre RPM ---
	_rpm_bar = ProgressBar.new()
	_rpm_bar.size = Vector2(220, 12)
	_rpm_bar.min_value = 0
	_rpm_bar.max_value = engine_max_rpm
	hud_container.add_child(_rpm_bar)

	# --- Barre Embrayage ---
	_clutch_bar = ProgressBar.new()
	_clutch_bar.size = Vector2(220, 8)
	_clutch_bar.min_value = 0
	_clutch_bar.max_value = 1
	hud_container.add_child(_clutch_bar)

	# --- Barre Frein moteur ---
	_engine_brake_bar = ProgressBar.new()
	_engine_brake_bar.size = Vector2(220, 8)
	_engine_brake_bar.min_value = 0
	_engine_brake_bar.max_value = 1
	hud_container.add_child(_engine_brake_bar)

	# --- Label État moteur ---
	_engine_status_label = Label.new()
	_engine_status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_engine_status_label.add_theme_font_size_override("font_size", 16)
	hud_container.add_child(_engine_status_label)

func _update_debug_hud() -> void:
	if not debug_dashboard or _debug_label == null:
		return

	var speed_kmh: float = velocity.length() * 3.6
	var gear_label: String = "N" if current_gear == 0 else ("R" if current_gear < 0 else str(current_gear))
	var rot_deg: float = fmod(rad_to_deg(rotation), 360.0)

	_debug_label.text = "🧭 DEBUG TANK\n" + \
		"Gear: %s\n" % gear_label + \
		"RPM: %.0f\n" % engine_rpm + \
		"Clutch: %s\n" % (str(clutch_pressed)) + \
		"Speed: %.1f km/h\n" % speed_kmh + \
		"Rot: %.1f°" % rot_deg

	_rpm_bar.value = engine_rpm
	_clutch_bar.value = 1.0 if clutch_pressed else 0.0

	if engine_rpm < 700.0:
		_rpm_bar.add_theme_color_override("fg_color", Color(1, 1, 0))
	elif engine_rpm > 2200.0:
		_rpm_bar.add_theme_color_override("fg_color", Color(1, 0, 0))
	else:
		_rpm_bar.add_theme_color_override("fg_color", Color(0, 1, 0))

	# --- Calcul visuel du frein moteur ---
	var brake_strength: float = 0.0

	if not engine_on:
		brake_strength = clamp(velocity.length() / 20.0, 0.0, 1.0)
	elif current_gear != 0 and not clutch_pressed:
		var rpm_factor: float = 1.0 - ((engine_rpm - engine_idle_rpm) / (engine_max_rpm - engine_idle_rpm))
		var gear_factor: float = 1.0 + absf(float(current_gear)) * 0.3
		brake_strength = clamp(rpm_factor * gear_factor * 0.4, 0.0, 1.0)

	_engine_brake_bar.value = brake_strength

	# Couleur dynamique : vert faible → orange → rouge fort
	if brake_strength < 0.3:
		_engine_brake_bar.add_theme_color_override("fg_color", Color(0.3, 1.0, 0.3))
	elif brake_strength < 0.7:
		_engine_brake_bar.add_theme_color_override("fg_color", Color(1.0, 0.6, 0.0))
	else:
		_engine_brake_bar.add_theme_color_override("fg_color", Color(1.0, 0.0, 0.0))

	_debug_label.text += "\nEngine brake: %.2f" % brake_strength

	# --- État du moteur ---
	if not engine_on:
		_engine_status_label.text = "⚠️ ENGINE OFF / STALLED"
	else:
		_engine_status_label.text = ""

# ------------------------------------------------------------
# INTERFACE DE DEBUG / DATABRIDGE
# ------------------------------------------------------------
func get_debug_data() -> Dictionary:
	return {
		"Speed": round(velocity.length() * 100.0) / 100.0,
		"Gear": current_gear,
		"RPM": round(engine_rpm),
		"EngineOn": engine_on
	}
