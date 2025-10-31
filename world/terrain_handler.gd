extends Node

var master_seed = randi()

var terrain_scene = preload("res://world/terrain_scene.tscn")
var road_scene = preload("res://world/road_scene.tscn")
var References: ReferenceData = ReferenceData.new()

@export var player: Node3D
@export var spawn_node: Node3D

@export_category('Noise')
@export var Noises: NoiseData

@export_category('Terrain')
@export var Terrains: Array[TerrainData]

@export_category('Road')
@export var Roads: Array[RoadData]

func _ready() -> void:
	Noises.noise_seed = randi()
	References.player = player
	References.spawn_node = spawn_node

	for Terrain in Terrains:
		var terrain_instance = terrain_scene.instantiate()
		terrain_instance.set_data(Terrain, Noises, References)
		add_child(terrain_instance)

	for Road in Roads:
		var road_instance = road_scene.instantiate()
		road_instance.set_data(Road, Noises, References)
		add_child(road_instance)
