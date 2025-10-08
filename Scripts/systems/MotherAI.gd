extends Node

## ------------------------------------------------------------------
## SIGNALS
## ------------------------------------------------------------------
signal request_action(scene_name: String, action_name: String, target: Node)
signal task_started(scene_name: String, action_name: String)
signal task_completed(scene_name: String, action_name: String)
signal log_updated(entry: String)

## ------------------------------------------------------------------
## VARIABLES
## ------------------------------------------------------------------
var active_scenes: Dictionary = {}         # { "Hangar": NodeRef, "TrainingField": NodeRef }
var task_queue: Array = []                 # [{scene, action, target}]
var memory: Array = []                     # journal des actions passées
var is_busy: bool = false            # indique si une tâche est en cours
var debug_mode: bool = true                # affiche les logs dans la console

## ------------------------------------------------------------------
## INITIALISATION
## ------------------------------------------------------------------
func _ready():
	print("[MotherAI] Initialisée")
	# Timer interne pour traitement asynchrone
	var process_timer := Timer.new()
	process_timer.name = "TaskProcessor"
	process_timer.one_shot = true
	add_child(process_timer)

## ------------------------------------------------------------------
## SCENE REGISTRATION
## ------------------------------------------------------------------
func register_scene(scene_name: String, node: Node):
	active_scenes[scene_name] = node
	_log("Scene registered: %s" % scene_name)

func unregister_scene(scene_name: String):
	if active_scenes.has(scene_name):
		active_scenes.erase(scene_name)
		_log("Scene unregistered: %s" % scene_name)

## ------------------------------------------------------------------
## TASK MANAGEMENT
## ------------------------------------------------------------------
func request_task(scene_name: String, action_name: String, target: Node = null):
	task_queue.append({
		"scene": scene_name,
		"action": action_name,
		"target": target
	})
	_log("Task queued: %s / %s" % [scene_name, action_name])
	_process_queue()

func _process_queue():
	if is_busy or task_queue.is_empty():
		return
	is_busy = true

	var current_task = task_queue.pop_front()
	var scene_name = current_task["scene"]
	var action_name = current_task["action"]
	var target = current_task["target"]

	emit_signal("task_started", scene_name, action_name)
	_log("Task started: %s / %s" % [scene_name, action_name])

	# demande d’exécution à la version physique
	if active_scenes.has(scene_name):
		var scene_node = active_scenes[scene_name]
		if scene_node.is_connected("animation_finished", Callable(self, "_on_task_complete")):
			scene_node.disconnect("animation_finished", Callable(self, "_on_task_complete"))
		# Appel de la fonction d’action (connectée via signal)
		emit_signal("request_action", scene_name, action_name, target)
	else:
		_log("⚠️ Scene not found for task: %s" % scene_name)
		_on_task_complete(scene_name, action_name)

func complete_task(scene_name: String, action_name: String):
	_on_task_complete(scene_name, action_name)

func _on_task_complete(scene_name: String, action_name: String):
	is_busy = false
	emit_signal("task_completed", scene_name, action_name)
	_log("Task completed: %s / %s" % [scene_name, action_name])
	memory.append({"scene": scene_name, "action": action_name, "timestamp": Time.get_datetime_string_from_system()})
	_process_queue()  # passe à la suivante

## ------------------------------------------------------------------
## LOGGING
## ------------------------------------------------------------------
func _log(entry: String):
	if debug_mode:
		print("[MotherAI]", entry)
	emit_signal("log_updated", entry)
