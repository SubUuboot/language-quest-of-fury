extends CharacterBody2D

@export var max_speed := 200.0
@export var acceleration := 500.0
@export var friction := 300.0
@export var rotation_speed := 180.0
@export var brake_power := 900.0
@export var min_turn_speed := 40.0
@export var DEBUG_LOGS := false

var prev_is_moving: bool = false
var angular_velocity := 0.0
var is_moving : bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hud = get_node("../HUDLayer/HUD")
@onready var instructor = get_node("../Instructor")


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

func _ready() -> void:
	if DEBUG_LOGS:
		print("Tank initialisé ! HUD:", hud != null, " Instructor:", instructor != null)
	if instructor:
		instructor.command_given.connect(_on_command_received)

func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_movement(delta)
	update_hud_display()

func handle_input(delta: float) -> void:
	var turn_input := 0
	if Input.is_action_pressed("ui_left"): turn_input -= 1
	if Input.is_action_pressed("ui_right"): turn_input += 1
	angular_velocity = turn_input * rotation_speed

	var thrust_input := 0
	if Input.is_action_pressed("ui_up"): thrust_input += 1
	if Input.is_action_pressed("ui_down"): thrust_input -= 1

	if Input.is_action_pressed("ui_accept"):
		velocity = velocity.move_toward(Vector2.ZERO, brake_power * delta)

	var direction: Vector2 = Vector2.UP.rotated(deg_to_rad(rotation_degrees))
	var speed: float = velocity.length()
	var rot_scale: float = clamp(speed / min_turn_speed, 0.35, 1.0)
	angular_velocity *= rot_scale

	if thrust_input != 0:
		velocity = velocity.move_toward(direction * thrust_input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	is_moving = velocity.length() > 1.0

	if Input.is_action_just_pressed("ui_left"):
		_show_command("left")
		player_performed_action.emit("left")
	if Input.is_action_just_pressed("ui_right"):
		_show_command("right")
		player_performed_action.emit("right")
	if Input.is_action_just_pressed("ui_up"):
		_show_command("forward")
		player_performed_action.emit("forward")
	if Input.is_action_just_pressed("ui_down"):
		_show_command("backward")
		player_performed_action.emit("backward")
	if prev_is_moving and not is_moving:
		player_performed_action.emit("stop")

	prev_is_moving = is_moving

func apply_movement(delta: float) -> void:
	rotation_degrees += angular_velocity * delta
	move_and_slide()

func _show_command(key: String) -> void:
	if commands.has(key) and hud:
		var cmd = commands[key]
		hud.show_command(cmd["russian"], cmd["pronunciation"])

func _on_command_received(command: String) -> void:
	if DEBUG_LOGS:
		print("Commande reçue:", command)
	if commands.has(command) and hud:
		var cmd = commands[command]
		hud.show_instructor_command(cmd["russian"], cmd["pronunciation"])

func get_current_speed() -> float:
	return velocity.length()

func get_speed_kmh() -> int:
	return int(round(velocity.length() * 3.6))

func update_hud_display() -> void:
	if hud:
		hud.update_speed(velocity.length(), get_speed_kmh())
		hud.update_movement_state(is_moving)
