extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var accel := 600.0
@export var tire_turn_speed := 2.0
@export var tire_max_turn_degrees := 25.0
@export var max_steer_speed := 25.0

var mouse_sensitivity := 0.002
var started := false
var motor_input := 0

@onready var springarm: SpringArm3D = $SpringArm3D
var mouse_captured := true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if mouse_captured:
			springarm.rotation.y -= event.relative.x * mouse_sensitivity
			springarm.rotation.x -= event.relative.y * mouse_sensitivity

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
		
	if event.is_action_pressed('reset'):
		reset()
		
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			mouse_captured = not mouse_captured
			if mouse_captured:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _basic_steering_rotation(delta: float):
	var turn_input := Input.get_axis('move_right', 'move_left') * tire_turn_speed
	var steer_angle = max((1.0-((linear_velocity.length() * 3.6) / max_steer_speed)), .1)
	
	if turn_input:
		$WheelRay_FL.rotation.y = clampf($WheelRay_FL.rotation.y + turn_input * delta * steer_angle,
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		$WheelRay_FR.rotation.y = clampf($WheelRay_FR.rotation.y + turn_input * delta * steer_angle,
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	
	else:
		$WheelRay_FL.rotation.y = move_toward($WheelRay_FL.rotation.y, 0, tire_turn_speed * delta)
		$WheelRay_FR.rotation.y = move_toward($WheelRay_FR.rotation.y, 0, tire_turn_speed * delta)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	springarm.spring_length = 10.0
	
	self.freeze = true
	for wheel in wheels:
		wheel.target_position.y = -(wheel.wheel_radius + wheel.rest_dist)
	pass # Replace with function body.

func start():
	started = true
	self.freeze = false

func reset():
	rotation = Vector3(0.0, rotation.y, 0.0)
	position += Vector3(0.0, 5.0 ,0.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_basic_steering_rotation(delta)
	if started:
		for wheel in wheels:
			wheel.force_raycast_update()
			var spring_force = calc_wheel_suspension(wheel)
			apply_force(spring_force[0], spring_force[1])
			
			var accel_force = wheel_acceleration(wheel)
			apply_force(accel_force[0], accel_force[1])
			
			var steer_force = _wheel_traction(wheel)
			apply_force(steer_force[0], steer_force[1])

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func _wheel_traction(ray: RaycastWheel):
	if not ray.is_colliding(): return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]
	
	var steer_side_dir := ray.global_basis.x
	var tire_vel := _get_point_velocity(ray.wheel.global_position)
	var steering_x_vel := steer_side_dir.dot(tire_vel)
	var x_traction := 0.6
	
	var desired_accel := (steering_x_vel * x_traction) / get_physics_process_delta_time()
	var x_force := -steer_side_dir * desired_accel * (mass/4.0)
	
	var force_pos := ray.wheel.global_position - global_position
	
	return [x_force, force_pos]

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
