extends Camera3D

@export var speed: float = 10.0
@export var mouse_sensitivity: float = 0.3

@export var ball_scene: PackedScene  # Optional: if you want a pre-made ball scene
@export var ball_radius: float = 0.5
@export var ball_spawn_distance: float = 2.0
@export var ball_launch_force: float = 15.0

var rotation_x := 0.0
var rotation_y := 0.0
var mouse_captured := true
var move_speed = 10.0
@export var speedup_speed = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	move_speed = speed
	
	#var viewport := get_viewport()
	#viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_captured:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -90, 90)
		rotation_degrees = Vector3(rotation_x, rotation_y, 0)
	
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			mouse_captured = not mouse_captured
			if mouse_captured:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
	if event is InputEventKey and event.pressed:
		if Input.is_action_pressed("spawn_ball"):
			spawn_ball()


func _process(delta):
	if not mouse_captured:
		return  # don't move camera when mouse is free

	var dir = Vector3.ZERO
	var forward = -transform.basis.z
	var right = transform.basis.x

	if Input.is_action_pressed("move_forward"):
		dir += forward
	if Input.is_action_pressed("move_back"):
		dir -= forward
	if Input.is_action_pressed("move_left"):
		dir -= right
	if Input.is_action_pressed("move_right"):
		dir += right
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir -= Vector3.UP
	if Input.is_action_pressed("speedup"):
		move_speed = speed * speedup_speed
	else:
		move_speed = speed 

	if dir != Vector3.ZERO:
		dir = dir.normalized() * move_speed * delta
		global_translate(dir)
		
func spawn_ball():
	var ball = RigidBody3D.new()
	ball.mass = 1.0

	# Collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = ball_radius
	collision.shape = shape
	ball.add_child(collision)

	# Mesh for visibility
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = SphereMesh.new()
	mesh_inst.mesh.radius = ball_radius
	ball.add_child(mesh_inst)

	# Compute the position BEFORE adding
	var spawn_pos = global_transform.origin + -global_transform.basis.z * ball_spawn_distance
	ball.transform.origin = spawn_pos  # Use transform.origin instead of global_transform

	# Add to scene
	get_tree().current_scene.add_child(ball)

	# Apply impulse
	ball.apply_impulse(Vector3.ZERO, -global_transform.basis.z * ball_launch_force)
