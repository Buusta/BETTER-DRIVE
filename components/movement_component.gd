extends Node
class_name MovementComponent

enum PlayerState {GROUND, AIR, DRIVING}

@export_category('Components')
@export var movable: RigidBody3D
@export var input_component: Node
@export var camera_arm: SpringArm3D
@export var ground_shape_cast: ShapeCast3D

@export_category('Movement')
@export_subgroup('Ground')
@export var ground_acceleration: float = 35.0
@export var max_walk_speed: float = 4.0

@export_subgroup('Air')
@export var air_acceleration: float = 4.0

@export_subgroup('Jump')
@export var jump_velocity: float = 3.2
@export var jump_velocity_factor: float = 0.4

@export_category('Controls')
@export var mouse_sensitivity: float = 0.002

var input_vector: Vector2 = Vector2.ZERO
var horizontal_vel: Vector3 = Vector3.ZERO

var state : PlayerState = PlayerState.GROUND

func _physics_process(delta: float) -> void:
	update_state()

	input_vector = input_component.input_vector
	
	horizontal_vel = movable.linear_velocity
	horizontal_vel.y = 0

	var wish_dir = get_wish_dir()

	match state:
		PlayerState.GROUND:
			movable.linear_velocity += ground_accelerate(wish_dir, delta)
		PlayerState.AIR:
			movable.linear_velocity += air_accelerate(wish_dir, delta)

func update_state() -> void:
	if not state == PlayerState.DRIVING:
		if ground_shape_cast.is_colliding() and movable.linear_velocity.y < jump_velocity_factor * jump_velocity:
			state = PlayerState.GROUND
		else:
			state = PlayerState.AIR

func state_override(state_: PlayerState):
	state = state_

func _rotate_camera(event_relative: Vector2i):
			camera_arm.rotation.y -= event_relative.x * mouse_sensitivity
			camera_arm.rotation.x -= event_relative.y * mouse_sensitivity
			camera_arm.rotation.x = clamp(camera_arm.rotation.x, -PI/2 + 0.01, PI/2- 0.01)

func jump() -> void:
	if state == PlayerState.GROUND and movable.linear_velocity.y < jump_velocity * jump_velocity_factor:
		movable.linear_velocity += Vector3(0.0, jump_velocity, 0.0)

func get_wish_dir() -> Vector3:
	var forward = -camera_arm.global_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera_arm.global_basis.x
	right.y = 0
	right = right.normalized()

	var wish_dir = (forward * input_vector.y + right * input_vector.x).normalized()
	return wish_dir

func ground_accelerate(wish_dir: Vector3, delta: float) -> Vector3:
	if horizontal_vel.length() < max_walk_speed:
		var ground_accel = wish_dir * delta * ground_acceleration
		return ground_accel
	else:
		return Vector3.ZERO

func air_accelerate(wish_dir: Vector3, delta: float) -> Vector3:
	if horizontal_vel.length() < max_walk_speed:
		var air_accel = wish_dir * delta * air_acceleration
		return air_accel
	else:
		return Vector3.ZERO
