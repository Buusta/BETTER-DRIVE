extends Node

signal target_reached

@export var UfoBody: RigidBody3D

@export_category('Movement')
@export var linear_acceleration: float
@export var angular_velocity: float
@export var max_velocity: float
@export var target_range_tolerance: float

var move_target: MoveTarget = MoveTarget.new()
var decelerate_distance: float
var travel_speed: float

func _ready() -> void:
	move_target.pos = Vector2(1000.0, 100.0)
	set_target(move_target)
	UfoBody.angular_velocity = Vector3(0.0, angular_velocity, 0.0)

func _physics_process(delta: float) -> void:
	var ufo_pos_2d = Vector2(UfoBody.position.x, UfoBody.position.z)
	var to_target = move_target.pos - ufo_pos_2d
	var distance = to_target.length()

	# Compute target velocity
	var target_velocity_2d = Vector2.ZERO
	if distance > target_range_tolerance:
		target_velocity_2d = to_target.normalized() * travel_speed

	var current_vel_2d = Vector2(UfoBody.linear_velocity.x, UfoBody.linear_velocity.z)
	var delta_velocity = target_velocity_2d - current_vel_2d

	# Smooth acceleration toward target velocity
	if distance > decelerate_distance:
		# accelerate
		current_vel_2d += delta_velocity.normalized() * linear_acceleration * delta
	else:
		# decelerate smoothly
		current_vel_2d -= current_vel_2d.normalized() * min(current_vel_2d.length(), linear_acceleration * delta)

	if Vector2(UfoBody.linear_velocity.x, UfoBody.linear_velocity.z).length() < target_range_tolerance and distance < decelerate_distance:
		target_reached.emit()

	# Clamp max speed
	if current_vel_2d.length() > max_velocity:
		current_vel_2d = current_vel_2d.normalized() * max_velocity

	UfoBody.linear_velocity.x = current_vel_2d.x
	UfoBody.linear_velocity.z = current_vel_2d.y

func set_target(target: MoveTarget):
	move_target = target
	var travel = calculate_decelerate_distance(move_target.pos)
	decelerate_distance = travel[0]
	travel_speed = travel[1]

func calculate_decelerate_distance(target_pos: Vector2) -> Array[float]:
	var dist = (target_pos - Vector2(UfoBody.position.x, UfoBody.position.z)).length()
	
	# How far you'd need to stop from max velocity
	var d_stop_full = max_velocity**2 / (2.0 * linear_acceleration)
	
	if dist < 2.0 * d_stop_full:
		# Not enough room to reach max speed — compute reduced peak velocity
		var v_peak = sqrt(linear_acceleration * dist)
		var d_stop = v_peak**2 / (2.0 * linear_acceleration)
		return [d_stop, v_peak]
	else:
		# Plenty of distance — use full speed
		return [d_stop_full, max_velocity]

func check_target_reached():
	target_reached.emit()
