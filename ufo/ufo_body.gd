extends RigidBody3D

@export var ufo_movement_component: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func target_reached():
	ufo_movement_component.move_target.pos = Vector2(randi_range(-1000, 1000), randi_range(-1000, 1000))
