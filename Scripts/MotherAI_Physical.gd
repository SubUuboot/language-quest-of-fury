extends Node2D

# Nom de la scène contrôlée par cette instance physique
@export var scene_id: String = "Hangar"

func _ready():
	# attendre que tous les singletons soient enregistrés
	await get_tree().process_frame

	var ai: Node = null  # ou autoload MotherAI si tu as une classe nommée
	if Engine.has_singleton("MotherAI"):
		ai = Engine.get_singleton("MotherAI")
	elif has_node("/root/MotherAI"):
		ai = get_node("/root/MotherAI")

	if ai:
		ai.register_scene(scene_id, self)
		ai.connect("request_action", Callable(self, "_on_request_action"))
	else:
		push_warning("MotherAI autoload not found even after delay.")

func _exit_tree():
	if Engine.has_singleton("MotherAI"):
		MotherAI.unregister_scene(scene_id)

func _on_request_action(request_scene: String, action_name: String, _target: Node):
	# Exécuter seulement si l’action concerne cette scène
	if request_scene != scene_id:
		return

	match action_name:
		"lift_tank":
			$AnimationPlayer.play("LiftTank")
			$ServoSound.play()
		"clear_debris":
			$AnimationPlayer.play("SweepArea")
		"rescue_tank":
			$AnimationPlayer.play("RetrieveTank")

	await $AnimationPlayer.animation_finished
	MotherAI.complete_task(scene_id, action_name)
