class_name NodeUtils
extends Node

static func get_node_safe(base: Node, path: NodePath) -> Node:
	if base and not path.is_empty() and base.has_node(path):
		return base.get_node(path)
	return null

static func call_if(obj: Object, method: String, args: Array = []):
	if obj and obj.has_method(method):
		obj.callv(method, args)
