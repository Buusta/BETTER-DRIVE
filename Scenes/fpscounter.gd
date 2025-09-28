extends CanvasLayer

var frametimes = []
var max_frametimes = 100
var current_index = 0
@export var car: RigidBody3D

func _process(delta: float) -> void:
	# Add delta to frametimes
	if frametimes.size() < max_frametimes:
		frametimes.append(delta)
	else:
		# Overwrite in circular fashion
		frametimes[current_index] = delta
		current_index = (current_index + 1) % max_frametimes

	# Update label with minimum frametime
	if frametimes.size() > 0:
		$Label2.text = str(frametimes.max() * 1000)
		
	$Label.text = str(snapped(car.linear_velocity.length() * 3.6, 0.1))  + "km/h"
