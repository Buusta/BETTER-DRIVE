extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var accel := 600.0

var started := false
var motor_input := 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_forward"):
		motor_input = 1
	elif event.is_action_released("move_forward"):
		motor_input = 0

	if event.is_action_pressed("move_back"):
		motor_input = -1
	elif event.is_action_released("move_back"):
		motor_input = 0

	if event.is_action_pressed('spawn_ball'):
		start()



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for wheel in wheels:
		wheel.target_position.y = -(wheel.wheel_radius + wheel.rest_dist)
	pass # Replace with function body.

func start():
	started = true
	self.freeze = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if started:
		for wheel in wheels:
			wheel.force_raycast_update()
			var spring_force = calc_wheel_suspension(wheel)
			apply_force(spring_force[0], spring_force[1])
			
			var accel_force = wheel_acceleration(wheel)
			apply_force(accel_force[0], accel_force[1])

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func wheel_acceleration(ray: RaycastWheel):
	if ray.is_colliding() and ray.is_motor and not motor_input == 0:
		var forward_dir := ray.global_basis.z * motor_input
		var contact := ray.get_collision_point()
		var force_vector := forward_dir * accel
		var force_pos := contact - global_position
		return [force_vector, force_pos]
	else:
		return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]

func calc_wheel_suspension(ray: RaycastWheel):
	if ray.is_colliding():
		var contact := ray.get_collision_point()
		var spring_up_dir := ray.global_transform.basis.y
		var spring_len := ray.global_position.distance_to(contact) - ray.wheel_radius
		var offset := ray.rest_dist - spring_len

		ray.wheel.position.y = -spring_len

		var spring_force := ray.spring_stiffness * offset

		var world_vel := _get_point_velocity(contact)
		var relative_vel := spring_up_dir.dot(world_vel)
		var spring_damp_force := ray.spring_damping * relative_vel

		var force_vector := (spring_force - spring_damp_force) * spring_up_dir

		var force_pos_offset := contact - global_position
		if force_vector:
			return [force_vector, force_pos_offset]
	else:
		return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]
