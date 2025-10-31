extends CanvasLayer

@export var tank: TankController2D   # Assigne ton tank via l’inspecteur
@onready var lbl_info: Label = $Panel/Label

var debug_visible := true

func _ready():
	$Panel.visible = debug_visible

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		debug_visible = !debug_visible
		$Panel.visible = debug_visible

	if not debug_visible or not tank:
		return

	var text := ""
	text += "Vitesse: %d km/h\n" % tank.get_speed_kmh()
	text += "Chenille G: %.1f m/s\n" % tank.left_track_speed
	text += "Chenille D: %.1f m/s\n" % tank.right_track_speed
	text += "Rapport: %d\n" % tank.gear
	text += "Embrayage: %s\n" % ("ON" if tank.clutch_pressed else "OFF")
	text += "Moteur: %s (%.0f rpm)\n" % ["ON" if tank.engine_on else "OFF", tank.engine_rpm]
	lbl_info.text = text
