extends CanvasLayer

var frametimes = []
var max_frametimes = 100
var max_frametime = 100
var current_index = 0

var driven_distance = 0.0
var prev_position: Vector3

@export var car: RigidBody3D
@onready var timer: Timer = $Timer
var time: String
var seconds_passed: int

func _ready() -> void:
	prev_position = car.position
	timer.wait_time = 1.0
	timer.autostart = true
	timer.one_shot = false
	timer.start()

func _process(delta: float) -> void:
	var car_forward_velocity = (car.linear_velocity * car.basis.z).length()
	$Speed.text = str(int(round(car_forward_velocity * 3.6))) + ' km/h'
	
	if Vector2(car.position.x, car.position.z).distance_to(Vector2(prev_position.x, prev_position.z)) > 1.0:
		driven_distance += 1.0
		prev_position = car.position

	$"Distance Driven".text = 'Distance driven: ' + str(snapped(driven_distance / 1000, .01)) + ' km'
	$Altitude.text = 'Altitude: ' + str(int(car.position.y)) + ' m'
	
	
	$Time.text = time

	# Add delta to frametimes
	if frametimes.size() < max_frametimes:
		frametimes.append(delta)

	else:
		# Overwrite in circular fashion
		frametimes[current_index] = delta
		current_index = (current_index + 1) % max_frametimes

	# Update label with minimum frametime
	if frametimes.size() > 0:
		max_frametime = frametimes.max() * 1000
		if max_frametime > 10:
			$Frametime.text = str(max_frametime)
		else:
			$Frametime.text = ''
		
	#w$Label.text = str(snapped(car.linear_velocity.length() * 3.6, 0.1))  + "km/h"

func _on_timer_timeout() -> void:
	seconds_passed += 1
	var seconds = seconds_passed % 60
	var minutes = (seconds_passed / 60) % 60
	var hours = seconds_passed / 3600
	time = "%02dh %02dm %02ds" % [hours, minutes, seconds]
