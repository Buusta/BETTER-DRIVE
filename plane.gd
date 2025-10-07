extends RigidBody3D

@export var engine_power := 200.0
@export var lift_coefficient := 0.5
@export var drag_coefficient := 0.02
@export var pitch_power := 3.0
@export var roll_power := 3.0
@export var yaw_power := 1.5

var pitch := 0
var roll := 1
var throttle := 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_forward"):
		pitch = 1
	elif event.is_action_released("move_forward"):
		pitch = 0

	if event.is_action_pressed("move_back"):
		pitch = -1
	elif event.is_action_released("move_back"):
		pitch = 0
	
	if event.is_action_pressed("throttle"):
		throttle = 1
	elif event.is_action_released("throttle"):
		throttle = 0

	if event.is_action_pressed("move_right"):
		roll = 1
	elif event.is_action_released("move_right"):
		roll = 0

	if event.is_action_pressed("move_left"):
		roll = -1
	elif event.is_action_released("move_left"):
		roll = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var aerodynamic_force = _calculate_lift(delta)

	apply_torque(transform.basis.x * pitch * pitch_power)
	apply_torque(transform.basis.z * roll * roll_power)

	apply_force(transform.basis.z * throttle * engine_power + aerodynamic_force)

func _calculate_lift(delta: float):
	var forward_velocity = linear_velocity.dot(transform.basis.z)
	var speed = linear_velocity.length()
	
	var lift_dir = transform.basis.y
	var lift_force = lift_dir * forward_velocity**2 * lift_coefficient
	var drag_force = -linear_velocity.normalized() * speed**2 * drag_coefficient
	
	DebugDraw3D.draw_arrow(
	global_position,
	global_position + lift_force * 0.1, # scale to be visible
	Color(0.2, 0.8, 1.0)
)
	
	var total_force = lift_force + drag_force
	return total_force
