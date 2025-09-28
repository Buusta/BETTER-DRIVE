extends Node3D

@export var player: Camera3D

@export var chunk_size := 32
@export var chunk_resolution := 1.0
@export var chunk_render_distance := 1

@export var octaves := 4
@export var height_scale := 25.0
@export var frequency := 0.5
@export var frequency_scale_div := 250.0
@export var terrain_seed := 69420
@export var chunks_per_frame := 1

@export var terrain_shader: VisualShader

var prev_player_chunk: Vector2i
var chunks := {}
var new_chunks := {}

var task_ids = []
var pending_chunks = []


func _ready() -> void:
	terrain_seed = randi()
	_add_new_chunks(Vector2(player.position.x, player.position.z), chunk_size, chunk_render_distance)

func _process(_delta: float) -> void:
	
	# Add new chunks to new_chunk list if the player has moved.
	var px = player.global_position.x
	var pz = player.global_position.z
	if prev_player_chunk != Vector2i(floor(px / chunk_size / chunk_resolution), floor(pz / chunk_size / chunk_resolution)): # if player not in player chunk
		prev_player_chunk = Vector2i(floor(px / chunk_size), floor(pz / chunk_size))
		_add_new_chunks(Vector2(px, pz), chunk_size, chunk_render_distance)

	if len(new_chunks) > 0:
		for c in new_chunks.keys():
			var task_id = WorkerThreadPool.add_task(Callable(self, "_thread_spawn_chunk").bind(c), false, "Generating")
			task_ids.append(task_id)
			chunks[c] = true
		new_chunks.clear()

	if task_ids.size() > 0:
		for i in range(task_ids.size() - 1, -1, -1):
			var id = task_ids[i]
			if WorkerThreadPool.is_task_completed(id):
				task_ids.remove_at(i)

	if pending_chunks.size() > 0:
		for i in range(min(chunks_per_frame, pending_chunks.size())):
			var chunk = pending_chunks.pop_front()
			var static_body = StaticBody3D.new()
			static_body.add_child(chunk[1])
			chunk[0].add_child(static_body)
			add_child(chunk[0])

func _thread_spawn_chunk(chunk_pos):
	var chunk_x_offset = chunk_pos.x * chunk_size / chunk_resolution
	var chunk_z_offset = chunk_pos.y * chunk_size / chunk_resolution
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise.seed = terrain_seed
	noise.frequency = frequency / frequency_scale_div
	noise.fractal_octaves = octaves

	#var st = SurfaceTool.new()
	#st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var faces := PackedVector3Array()

	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var height = noise.get_noise_2d(x/chunk_resolution + chunk_x_offset, z/chunk_resolution + chunk_z_offset) * height_scale
			var vert = Vector3(x/chunk_resolution + chunk_x_offset, height, z/chunk_resolution + chunk_z_offset)

			var u = (x + chunk_x_offset)
			var v = (z + chunk_z_offset)
			#st.set_uv(Vector2(u, v))
			#st.add_vertex(vert)	
			verts.append(vert)

	for z in range(chunk_size):
		for x in range(chunk_size):
			var base = z * (chunk_size + 1) + x
			indices.append(base)
			indices.append(base + 1)
			indices.append(base + chunk_size + 1)
#
			indices.append(base + 1)
			indices.append(base + chunk_size + 2)
			indices.append(base + chunk_size + 1)

			faces.append(verts[base])
			faces.append(verts[base + 1])
			faces.append(verts[base + chunk_size + 1])

			faces.append(verts[base + 1])
			faces.append(verts[base + chunk_size + 2])
			faces.append(verts[base + chunk_size + 1])

	var tim = Time.get_ticks_usec()

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
#
	##st.generate_normals()
	##var mesh = st.commit()
	#
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
#
	var concave = ConcavePolygonShape3D.new()
	concave.set_faces(faces)

	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = concave
	#static_body.add_child(collision_shape)
	#mesh_inst.add_child(static_body)
#
#
	if terrain_shader:
		var mat = ShaderMaterial.new()
		mat.shader = terrain_shader
		mesh_inst.material_override = mat
#
	call_deferred("_add_mesh_main_thread", mesh_inst, collision_shape)


func _add_mesh_main_thread(m: MeshInstance3D, c: CollisionShape3D):
	if not m.is_inside_tree():
		pending_chunks.append([m, c])

func _add_new_chunks(pos: Vector2, size: int, render_distance: int):
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
