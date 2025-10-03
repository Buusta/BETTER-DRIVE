extends Node3D

@export var player: Node3D
@export var world: Node3D
@export var terrain_handler: Node

var children: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player.global_position.length() > 1000.0:
		world.global_position -= player.global_position
