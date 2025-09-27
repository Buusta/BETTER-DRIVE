extends Camera3D

@export var speed: float = 10.0
@export var mouse_sensitivity: float = 0.3

var rotation_x := 0.0
var rotation_y := 0.0
var mouse_captured := true
var move_speed = 10.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	move_speed = speed

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
		move_speed = speed * 5
	else:
		move_speed = speed 

	if dir != Vector3.ZERO:
		dir = dir.normalized() * move_speed * delta
		global_translate(dir)
