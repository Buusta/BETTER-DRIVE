extends Node3D

@export var player: Camera3D

@export var chunk_size:= 32
@export var chunk_resolution:= 1
@export var chunk_render_distance:= 1

@export var resolution:= 32
@export var height_scale:= 25.0
@export var frequency:= 0.5
@export var terrain_seed:= 69420

var prev_player_chunk: Vector2i
var chunks := {}       # keys = Vector2(x,z), value = true
var new_chunks := {}

var task_ids = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_new_chunks(Vector2(player.position.x, player.position.z), chunk_size, chunk_render_distance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Add new chunks to new_chunk list if the player has moved.
	var px = player.global_position.x
	var pz = player.global_position.z
	if prev_player_chunk != Vector2i(floor(px / chunk_size), floor(pz / chunk_size)): # if player not in player chunk
		prev_player_chunk = Vector2i(floor(px / chunk_size), floor(pz / chunk_size)) 
		add_new_chunks(Vector2(px, pz), chunk_size, chunk_render_distance)
	
	if len(new_chunks) > 0:
		for c in new_chunks:
			var task_id := WorkerThreadPool.add_task(Callable(self, "_thread_spawn_chunk").bind(c), false, "Generating")
			task_ids.append(task_id)
			new_chunks.erase(c)
			chunks[c] = true
			
	if len(task_ids) > 0:
		for id in task_ids:
			if WorkerThreadPool.is_task_completed(id):
				task_ids.erase(id)
				#var res = WorkerThreadPool.

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
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.create_trimesh_collision()
	self.add_child.call_deferred(mesh_inst)

# Add new chunks with the paramaters
func add_new_chunks(pos: Vector2, size: int, render_distance: int):
	var player_chunk_pos = Vector2i(floor(pos.x / size), floor(pos.y / size))
	for x in range(player_chunk_pos.x - render_distance, player_chunk_pos.x + render_distance + 1):
		for z in range(player_chunk_pos.y - render_distance, player_chunk_pos.y + render_distance + 1):
			var chunk_xz = Vector2i(x, z)  # Use Vector2i for exact integer keys
			if not chunks.has(chunk_xz) and not new_chunks.has(chunk_xz):
				new_chunks[chunk_xz] = true

func frac(x: float) -> float:
	return x - floor(x)

func _exit_tree() -> void:
	for id in task_ids:
		WorkerThreadPool.wait_for_task_completion(id)
