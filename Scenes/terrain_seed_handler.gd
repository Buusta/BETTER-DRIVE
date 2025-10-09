extends Node

var master_seed = randi()  # random for this session

@export var player: Node3D # can be anything but it needs a position so chunks can generate around it

@export var octaves := 4 # how detailed the noise is
@export var height_scale := 25.0 # how much the terrain will be scaled along the y axis
@export var frequency := 0.5 # how big the noise is
@export var frequency_scale := 250.0 # scales the frequency (divides)
@export var mountain_octaves := 4
@export var mountain_height_scale := 100
@export var mountain_frequency := 0.5
@export var mountain_frequency_scale := 250
@export var terrain_shader: VisualShader # terrain shader

@export var spawn_node: Node3D


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#for child in get_children():
		##child.noise_seed = master_seed
		#child.octaves = octaves
		#child.height_scale = height_scale
		#child.frequency = frequency
		#child.frequency_scale = frequency_scale
		#child.mountain_octaves = mountain_octaves
		#child.mountain_height_scale = mountain_height_scale
		#child.mountain_frequency = mountain_frequency
		#child.mountain_frequency_scale = mountain_frequency_scale
		#child.spawn_node = spawn_node
		#child.player = player
		#if "do_once" in child:
			#child.do_once = true
