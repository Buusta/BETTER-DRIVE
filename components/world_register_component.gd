extends Node
class_name WorldRegisterComponent

@onready var world: Node3D = get_tree().get_first_node_in_group("World")

@export var entries: Array[RegistryEntry]

func _ready():
	for entry in entries:
		register(entry.property, entry.target)

func register(property: String, target: NodePath) -> void:
	if world.get(property) == null:
			push_error("World has no property '%s'" % property)
			return

	var arr = world.get(property)
	if typeof(arr) == TYPE_ARRAY:
		var node = get_node_or_null(target)
		if node and not arr.has(node):
			arr.append(node)
