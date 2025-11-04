extends Node
class_name InputComponent

signal interact
signal jump
signal mouse_input
signal click_l
signal click_r
signal _1
signal _2
signal _3
signal _4
signal _5
signal drop

@onready var parent = get_parent()

var input_vector: Vector2
var is_jump: bool
var mouse_captured: bool = true

func _unhandled_input(event: InputEvent) -> void:
	is_jump = false
	
	input_vector = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")

	if event is InputEventMouseMotion:
		if mouse_captured:
			mouse_input.emit(event.relative)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			is_jump = true
		else:
			is_jump = false

	if event.is_action_pressed("jump"):
		is_jump = true

	if is_jump:
		jump.emit()

	if event.is_action_pressed("interact"):
		interact.emit(parent)

	if event.is_action_pressed('click_l'):
		click_l.emit()

	if event.is_action_pressed('click_r'):
		click_r.emit()

	if event.is_action_pressed('1'):
		_1.emit(1)

	if event.is_action_pressed('2'):
		_2.emit(2)

	if event.is_action_pressed('3'):
		_3.emit(3)

	if event.is_action_pressed('4'):
		_4.emit(4)

	if event.is_action_pressed('5'):
		_5.emit(5)

	if event.is_action_pressed('drop_item'):
		drop.emit()
	#if event.is_action_pressed("camera_zoom"):
		#zoom(true)
	#if event.is_action_released("camera_zoom"):
		#zoom(false)

	#if abs(input_vector.length()) > 1.0:
		#input_vector_normalized = input_vector.normalized()
	#else:
		#input_vector_normalized = input_vector
#
	#if event is InputEventKey and event.pressed:
		#if event.keycode == Key.KEY_ESCAPE:
			#mouse_captured = not mouse_captured
			#if mouse_captured:
				#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			#else:
				#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#
	#if event.is_action_pressed("jump"):
		#jump = true
	#elif not mwheel_jump:
		#jump = false



#func _process(delta: float) -> void:
	#print(input_vector)

func capture_mouse(toggle: bool):
	mouse_captured = toggle
