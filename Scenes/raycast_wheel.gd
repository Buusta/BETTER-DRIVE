extends RayCast3D
class_name RaycastWheel

@export var spring_stiffness := 100.0
@export var spring_damping := 2.0
@export var rest_dist := 0.48
@export var wheel_radius := 0.4
@export var is_motor := false

@onready var wheel: Node3D = get_child(0)
