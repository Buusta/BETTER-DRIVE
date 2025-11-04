extends Node
class_name CameraZoomComponent

@onready var default_fov: float = zoom_target.fov

@export var zoom_target: Camera3D
@export var zoom_fov := 25.0
@export var zoom_speed := 4.0

@onready var z_delta = default_fov - zoom_fov

var alpha: float = 0.0


var zoomed := 0.0

func _process(delta: float) -> void:
	if zoomed == 1.0:
		if alpha < 1.0:
			alpha += zoom_speed * delta
	else:
		if alpha > 0.0:
			alpha -= zoom_speed * delta

	alpha = clamp(alpha, 0.0, 1.0)
	zoom_target.fov = lerp(default_fov, zoom_fov, alpha)

func zoom():
	if not zoomed:
		#zoom_target.fov = zoom_fov
		zoomed = 1.0
	else:
		#zoom_target.fov = default_fov
		zoomed = 0.0
