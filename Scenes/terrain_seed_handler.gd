extends Node3D

var master_seed = randi()  # random for this session

@export var terrain1: Node3D
@export var terrain2: Node3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrain1.noise_seed = master_seed
	terrain2.noise_seed = master_seed
