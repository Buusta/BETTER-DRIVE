extends Node
class_name  WorldAccess

@onready var world: Node3D = get_tree().get_first_node_in_group("World")

func get_world_property(prop_name: String):
	if world.get(prop_name):
		return world.get(prop_name)
	push_error("World has no property '%s'" % prop_name)
	return null
