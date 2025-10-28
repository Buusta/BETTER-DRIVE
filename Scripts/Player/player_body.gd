extends RigidBody3D

@onready var springarm: SpringArm3D = $SpringArm3D
@onready var groundray: RayCast3D = $GroundRay

enum PlayerState {GROUND, AIR}

var mouse_captured := true
var mouse_sensitivity := 0.002

var input_vector = Vector2.ZERO
var input_vector_normalized = Vector2.ZERO

var horizontal_vel: Vector3

var max_walk_speed = 4.2
var ground_acceleration = 35.0
var ground_friction = 5.0

var air_acceleration = 5.0
var air_friction = 0.3

var jump = false
var mwheel_jump = false
var jump_velocity = 550.0
var jump_timer = 0.0
var jump_cooldown = 0.25

var state = PlayerState.GROUND

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if mouse_captured:
			springarm.rotation.y -= event.relative.x * mouse_sensitivity
			springarm.rotation.x -= event.relative.y * mouse_sensitivity
			springarm.rotation.x = clamp(springarm.rotation.x, -1.5, 1.5)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mwheel_jump = true
		else:
			mwheel_jump = false

	if event.is_action_pressed("move_forward"):
		input_vector.y += 1
	elif event.is_action_released("move_forward"):
		input_vector.y += -1

	if event.is_action_pressed("move_back"):
		input_vector.y -= 1
	elif event.is_action_released("move_back"):
		input_vector.y -= -1

	if event.is_action_pressed("move_left"):
		input_vector.x -= 1
	elif event.is_action_released("move_left"):
		input_vector.x -= -1

	if event.is_action_pressed("move_right"):
		input_vector.x += 1
	elif event.is_action_released("move_right"):
		input_vector.x += -1

	if abs(input_vector.length()) > 1.0:
		input_vector_normalized = input_vector.normalized()
	else:
		input_vector_normalized = input_vector

	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			mouse_captured = not mouse_captured
			if mouse_captured:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("jump"):
		jump = true
	elif not mwheel_jump:
		jump = false

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func _physics_process(delta: float) -> void:
	if groundray.is_colliding():
		state = PlayerState.GROUND
	else:
		state = PlayerState.AIR

	horizontal_vel = linear_velocity
	horizontal_vel.y = 0

	var forward = -springarm.global_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = springarm.global_basis.x
	right.y = 0
	right = right.normalized()

	var wish_dir = (forward * input_vector.y + right * input_vector.x).normalized()

	if jump_timer < jump_cooldown:
		jump_timer += delta

	if state == PlayerState.GROUND:
		if input_vector_normalized.length() == 0.0:
				linear_damp = ground_friction
		else:
			linear_damp = 0.0

		linear_velocity += ground_accelerate(wish_dir, delta)

		if jump and jump_timer >= jump_cooldown:
			linear_velocity += Vector3.UP * jump_velocity / 100.0
			jump_timer = 0.0

	jump = false

	if state == PlayerState.AIR:
		if input_vector_normalized.length() == 0.0:
			linear_damp = air_friction
		else:
			linear_damp = 0.0
		
		linear_velocity += air_accelerate(wish_dir, delta)

func air_accelerate(wish_dir: Vector3, delta: float) -> Vector3:
	if horizontal_vel.length() < max_walk_speed:
		var air_accel = wish_dir * delta * air_acceleration
		return air_accel
	else:
		return Vector3.ZERO

func ground_accelerate(wish_dir: Vector3, delta: float) -> Vector3:
	if horizontal_vel.length() < max_walk_speed:
		var ground_accel = wish_dir * delta * ground_acceleration
		return ground_accel
	else:
		return Vector3.ZERO
