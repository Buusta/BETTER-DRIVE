extends Node3D

@export var player: Node3D # can be anything but it needs a position so chunks can generate around it

@export var resolution := 32 # the base resolution of the chunk
@export var chunk_size := 32 # the size of a chunk (m x m)
@export var render_distance := 1 # how many chunks will be loaded in

@export var octaves := 4 # how detailed the noise is
@export var height_scale := 25.0 # how much the terrain will be scaled along the y axis
@export var frequency := 0.5 # how big the noise is
@export var frequency_scale := 250.0 # scales the frequency (divides)
@export var chunks_per_frame := 1 # how many chunk meshes can be generated and added as child per frame. helps with performance

@export var terrain_shader: VisualShader # terrain shader

var terrain_seed = randi() # the random seed for the terrain

var prev_player_chunk: Vector2i # the chunk the player was in last frame

var chunks := {} # key = Vector2i position (chunk_pos), vals = MeshInstance3D, Distance
var new_chunks := {} # key = Vector2i position (chunk_pos), vals = Distance
var generating_chunks := {} # key = Vector2i position (chunk_pos), vals = true
var pending_chunks = [] # vals = mesh_arrays, collision, Vector2i position (chunk_pos), distance

var task_ids = [] # all WorkerThreadPool tasks that need to be completed.

func _ready() -> void:
	_add_new_chunks(Vector2(player.position.x, player.position.z), render_distance)

func _process(_delta: float) -> void:
	var px = player.global_position.x
	var pz = player.global_position.z

	# add new chunks to new_chunk list if the player has moved.
	if prev_player_chunk != Vector2i(floor(px / resolution), floor(pz / resolution)): # if player not in player chunk
		prev_player_chunk = Vector2i(floor(px / resolution), floor(pz / resolution))
		_add_new_chunks(Vector2(px, pz), render_distance)

	# give workerThreadPool task if there are new chunks
	if len(new_chunks) > 0:
		for c in new_chunks.keys():
			var task_id = WorkerThreadPool.add_task(Callable(self, "_thread_spawn_chunk").bind(c, new_chunks[c]), false, "Generating")
			task_ids.append(task_id)
			generating_chunks[c] = true
		new_chunks.clear()

	# if tasks are complete, remove them from the task list so they end
	if task_ids.size() > 0:
		for i in range(task_ids.size() - 1, -1, -1):
			var id = task_ids[i]
			if WorkerThreadPool.is_task_completed(id):
				task_ids.remove_at(i)

	# if there are chunks that are ready to be added, do it per "chunks_per_frame" amount of times
	if pending_chunks.size() > 0:
		for i in range(min(chunks_per_frame, pending_chunks.size())): # takes the min between the len and the max amount of "chunks_per_frame"
			var chunk = pending_chunks.pop_front() # vals = mesh_arrays, collision, Vector2i position (chunk_pos), distance
			var mesh_array = chunk[0]
			var collision = chunk[1]
			var chunk_pos = chunk[2]
			var distance = chunk[3]

			var mesh = ArrayMesh.new()
			var mesh_inst = MeshInstance3D.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
			mesh_inst.mesh = mesh

			var mat = ShaderMaterial.new()
			mat.shader = terrain_shader
			mesh_inst.material_override = mat

			var static_body = StaticBody3D.new()
			static_body.add_child(collision)
			mesh_inst.add_child(static_body)

			var offset = Vector3(chunk_pos.x * chunk_size, 0.0, chunk_pos.y * chunk_size)
			mesh_inst.transform.origin = offset
			add_child(mesh_inst)

			chunks[chunk_pos] = {
				"mesh": mesh_inst,
				"distance": distance
				}

func _thread_spawn_chunk(chunk_pos, distance):
	var chunk_x_offset = chunk_pos.x * chunk_size
	var chunk_z_offset = chunk_pos.y * chunk_size

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise.seed = terrain_seed
	noise.frequency = frequency / frequency_scale
	noise.fractal_octaves = octaves

	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var faces := PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()

	for row in range(resolution + 3):
		for col in range(resolution + 3):
		
			var height = noise.get_noise_2d(
				col * float(chunk_size) / float(resolution) + chunk_x_offset, row * float(chunk_size) / float(resolution) + chunk_z_offset
				) * height_scale
		
			var vert = Vector3(
			col * float(chunk_size) / float(resolution),
			height,
			row * float(chunk_size) / float(resolution)
			)
			
			var u = float(col)
			var v = float(row)

			uvs.append(Vector2(u, v))
			verts.append(vert)

	for row in range(resolution):
		for col in range(resolution):
			var base = (row+1) * (resolution + 3) + (col+1)
			indices.append(base)
			indices.append(base + 1)
			indices.append(base + resolution + 3)

			indices.append(base + 1)
			indices.append(base + resolution + 4)
			indices.append(base + resolution + 3)
			
			faces.append(verts[base])
			faces.append(verts[base + 1])
			faces.append(verts[base + resolution + 3])
			
			faces.append(verts[base + 1])
			faces.append(verts[base + resolution + 4])
			faces.append(verts[base + resolution + 3])

	for row in range(resolution+3):
		for col in range(resolution+3):
			if row==0 or col==0 or row==resolution+2 or col==resolution+2:
				normals.append(Vector3(0.0, 0.0, 0.0))
			else:
				var idx = col + row * (resolution+3)
				var left = verts[idx - 1]
				var right = verts[idx + 1]
				var up = verts[idx + (resolution + 3)]
				var down = verts[idx - (resolution + 3)]
				
				var dx = right - left   # slope in X direction
				var dz = up - down
				var normal = dx.cross(dz).normalized()

				normals.append(-normal)

	var arrays = []

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	var concave = ConcavePolygonShape3D.new()
	concave.set_faces(faces)

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = concave

	call_deferred("_add_mesh_main_thread", arrays, collision_shape, chunk_pos, distance)

func _add_mesh_main_thread(m: Array, c: CollisionShape3D, pos: Vector2i, dist: int):
	pending_chunks.append([m, c, pos, dist])

func _add_new_chunks(pos: Vector2, rend_dist: int):
	var center_chunk = Vector2i(
	floor(pos.x / chunk_size),
	floor(pos.y / chunk_size)
	)
	
	var needed_chunks = {}
	
	for x in range(center_chunk.x - rend_dist, center_chunk.x + rend_dist + 1):
		for z in range(center_chunk.y - rend_dist, center_chunk.y + rend_dist + 1):
			var chunk_pos = Vector2i(x, z)
			var relative_pos = chunk_pos - center_chunk
			var chunk_dist = max(abs(relative_pos.x), abs(relative_pos.y))
			needed_chunks[chunk_pos] = chunk_dist

	for chunk_key in needed_chunks.keys():
		if not chunks.has(chunk_key):
			new_chunks[chunk_key] = needed_chunks[chunk_key]

	for chunk_key in chunks.keys():
		if not needed_chunks.has(chunk_key):
			# Free the mesh instance
			chunks[chunk_key]["mesh"].queue_free()
			# Remove the dictionary entry
			chunks.erase(chunk_key)

func _exit_tree() -> void:
	for id in task_ids:
		WorkerThreadPool.wait_for_task_completion(id)
