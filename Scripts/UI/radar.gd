extends Node2D

@onready var radar_size: Vector2 = Vector2(get_parent().size)
@export var radar_range: float = 300.0
@export var sweep_speed: float = 1.5
@export var ufo_positions : Array[Vector2] = []

var blips: Array[RadarBlip] = []
var sweep_angle: float = 0.0
var glob_pos: Vector2 = Vector2.ZERO
var glob_rot: float

var radius: float = (512.0 / 2.0) * 0.9

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for ufo in ufo_positions:
		var blip = RadarBlip.new()
		blip.pos = ufo
		blip.alpha = 1.0
		blip.decay_rate = 1.5 / (sweep_speed * PI)
		blips.append(blip)

func _process(delta):
	sweep_angle += delta * sweep_speed
	sweep_angle = fmod(sweep_angle, TAU)
	queue_redraw()

func _draw():
	var center = radar_size / 2 
	var base_color = Color(0, 1, 0, 0.8)

	# background
	draw_rect(Rect2(Vector2.ZERO, radar_size), Color(0.0, 0.005, 0.0, 1.0))

	## grid circles
	#for i in range(1, 5):
		#draw_circle(center, radius * (i / 5.0), Color(0, 1, 0, 0.2))

	# cross lines
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(0, 1, 0, 0.15))
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(0, 1, 0, 0.15))

	# sweep cone (half-circle sector)
	var sweep_angle_width = deg_to_rad(30)  # width of the cone in radians
	var points = [center]
	var num_steps = 10  # how smooth the cone edge is
	for i in range(num_steps + 1):
		var angle = sweep_angle - sweep_angle_width/2 + (sweep_angle_width/num_steps) * i
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	draw_colored_polygon(points, Color(0, 1, 0, 0.2))  # semi-transparent green

	# UFO dots
	for blip in blips:
		if (blip.pos - glob_pos).length() > radar_range:
			continue
		var rel = blip.pos - glob_pos 
		rel = rel.rotated(glob_rot)
		var radar_pos = center + rel / radar_range * radius
		var angle_to_ufo = atan2(rel.y, rel.x)
		var diff = abs(wrapf(angle_to_ufo - sweep_angle, -PI, PI))

		blip.alpha = max(blip.alpha - blip.decay_rate * get_process_delta_time(), 0.0)

		if diff < deg_to_rad(1.5):
			blip.alpha = 1.0

		draw_circle(radar_pos, 4, base_color * blip.alpha)
