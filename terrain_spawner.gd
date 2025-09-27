extends Node3D

@export var player: Camera3D

@export var chunk_size:= 32
@export var chunk_resolution:= 1
@export var chunk_render_distance:= 1

@export var resolution:= 32
@export var height_scale:= 25.0
@export var frequency:= 0.5
@export var terrain_seed:= 69420

var player_chunk: Vector2i
var chunks = []
var new_chunks = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_new_chunks()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# Add new chunks to new_chunk list if the player has moved.
	var px = player.position.x
	var pz = player.position.z
	if player_chunk != Vector2i(floor(px / chunk_size), floor(pz / chunk_size)): # if player not in player chunk
		player_chunk = Vector2i(floor(px / chunk_size), floor(pz / chunk_size)) 
		add_new_chunks()


func add_new_chunks():
	for x in range(player_chunk.x - chunk_render_distance, player_chunk.x + chunk_render_distance + 1): 
		for z in range(player_chunk.y - chunk_render_distance, player_chunk.y + chunk_render_distance + 1):
			var chunk_xz = Vector2(x, z)
			if not (chunks.has(chunk_xz) or new_chunks.has(chunk_xz)):
				new_chunks.append(chunk_xz)
				print('added')


func _thread_spawn_chunk(chunk_pos):
	var chunk_x_offset = chunk_pos.x * chunk_size
	var chunk_z_offset = chunk_pos.y * chunk_size
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# Configure
	noise.seed = terrain_seed
	noise.frequency = frequency
	noise.fractal_octaves = 3
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var height = noise.get_noise_2d(x + chunk_x_offset, z + chunk_z_offset) * height_scale
			var vert = Vector3(x + chunk_x_offset, height, z + chunk_z_offset)
			st.add_vertex(vert)
			
			
	for z in range(chunk_size):
		for x in range(chunk_size):
			var base = z * (chunk_size + 1) + x
			st.add_index(base)
			st.add_index(base + 1)
			st.add_index(base + chunk_size + 1)
			
			st.add_index(base + 1)
			st.add_index(base + chunk_size + 2)
			st.add_index(base + chunk_size + 1)
	
	st.generate_normals()
	var mesh = st.commit()


func _assign_chunk_mesh(chunk_node: MeshInstance3D, mesh: ArrayMesh, chunk_xz: Vector2, t: Thread) -> void:
	chunk_node.mesh = mesh
	new_chunks.erase(chunk_xz)

func frac(x: float) -> float:
	return x - floor(x)
