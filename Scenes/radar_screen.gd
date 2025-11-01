extends MeshInstance3D

@export var world_access: WorldAccess
@export var radar_range: float = 1000.0

var radar_texture: Object
var radar_renderer: Object


var world_node: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_node = get_parent().get_parent()
	var radar_viewport = preload("res://Scenes/UI/radar.tscn").instantiate()
	add_child(radar_viewport)

	radar_texture = radar_viewport.get_texture()
	radar_renderer = radar_viewport.get_node('Radar')

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = radar_texture
	mat.emission_enabled = true
	mat.emission_texture = radar_texture
	mat.emission_energy = 2.0
	material_override = mat

	radar_renderer.radar_range = radar_range
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var world_position = Vector2(global_position.x + world_node.position.x, global_position.z + world_node.position.z)
	radar_renderer.glob_pos = world_position
	radar_renderer.glob_rot = global_rotation.y
	var ufos = world_access.get_world_property('ufos')
	for ufo in ufos:
		radar_renderer.add_ufo(ufo)
