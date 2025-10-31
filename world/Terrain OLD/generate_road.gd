extends Node

var Road: RoadData
var Noises: NoiseData
var References: ReferenceData

var init_dir = Vector2(2 * randf() - 1, 2 * randf() - 1)
var nodes = { 0:{'pos':Vector3(0.0, 0.0, 0.0),
				'dir':init_dir} }

var noise = FastNoiseLite.new()
var mountain_noise = FastNoiseLite.new()

var active_meshes: Array = []

func set_data(road_data: RoadData, noise_data: NoiseData, reference_data: ReferenceData):
	Road = road_data
	Noises = noise_data
	References = reference_data


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise.seed = Noises.noise_seed
	noise.frequency = Noises.frequency / Noises.frequency_scale
	noise.fractal_octaves = Noises.octaves

	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_noise.seed = Noises.noise_seed
	mountain_noise.frequency = Noises.mountain_frequency / Noises.mountain_frequency_scale
	mountain_noise.fractal_octaves = Noises.mountain_octaves

func _process(_delta: float) -> void:
	var closest_idx = 0
	var closest_dist = INF
	var pending_nodes = []
	var generate_segments = false

	for key in nodes.keys():
		if (nodes[key]['pos'] - References.player.position).length() < closest_dist:
			closest_idx = key
			closest_dist = (nodes[key]['pos'] - References.player.position).length()
	pending_nodes.append(closest_idx)

	@warning_ignore("integer_division")
	var half_segments = Road.segments / 2
	for i in range(1 , half_segments + 1):
		var key = i + closest_idx
		pending_nodes.append(key)

	for i in range(-1 , -half_segments - 1, -1):
		var key = i + closest_idx
		pending_nodes.append(key)

	#for key in nodes.keys():
		#if not key in pending_nodes:
#
			#if nodes[key].has('meshes'):
				#for mesh in nodes[key]['meshes']:
					#if mesh != null:
						#mesh.queue_free()


	for key in pending_nodes:
		if not key in nodes:
			if key < closest_idx:
				var prev_node_dir = nodes[key + 1]['dir']
				var prev_node_pos = nodes[key + 1]['pos']
				var end = Vector2(prev_node_pos.x, prev_node_pos.z) - prev_node_dir * Road.segment_length
				var node_dir = get_segment_dir(key+1)
				var end3d = _terrain_sample(end, node_dir)
				nodes[key] = {'pos':end3d, 'dir':node_dir}
				generate_segments = true
			else:
				var prev_node_dir = nodes[key - 1]['dir']
				var prev_node_pos = nodes[key - 1]['pos']
				var end = Vector2(prev_node_pos.x, prev_node_pos.z) + prev_node_dir * Road.segment_length
				var node_dir = get_segment_dir(key-1)
				var end3d = _terrain_sample(end, node_dir)
				nodes[key] = {'pos':end3d, 'dir':node_dir}
				generate_segments = true

	if generate_segments:

		for key in range(closest_idx - half_segments + 1, closest_idx + half_segments - 1):
			if not nodes[key].has('subnodes'):
				var subnodes = []
				for i in range(Road.sub_segments - 1):
					var t = (i + 1) * 1.0 / Road.sub_segments
					var pos = catmull_rom(nodes[key-1]['pos'], nodes[key]['pos'], nodes[key+1]['pos'], nodes[key+2]['pos'], t)
					subnodes.append(pos)
				nodes[key]['subnodes'] = subnodes

		for key in range(closest_idx - half_segments + 1, closest_idx + half_segments - 1):
			if nodes[key].has('subnodes'):
				for subnode in range(len(nodes[key]['subnodes'])):
					var pos = nodes[key]['subnodes'][subnode]
					if subnode == Road.sub_segments-2:
						var dir = nodes[key+1]['pos'] - pos
						dir = Vector2(dir.x, dir.z)
					else:
						var dir = nodes[key]['subnodes'][subnode + 1] - pos
						dir = Vector2(dir.x, dir.z)
						nodes[key]['subnodes'][subnode] = _terrain_sample(Vector2(pos.x, pos.z), dir)
						

		for key in range(closest_idx - half_segments + 2, closest_idx + half_segments - 2):
			if not nodes[key].has('mesh'):
				var segment_nodes = []
				
				segment_nodes.append(nodes[key-1]['subnodes'][Road.sub_segments-2])
				segment_nodes.append(nodes[key]['pos'])

				for node in range(Road.sub_segments -1):
					segment_nodes.append(nodes[key]['subnodes'][node])

				segment_nodes.append(nodes[key+1]['pos'])
				segment_nodes.append(nodes[key+1]['subnodes'][0])
				segment_nodes.append(nodes[key+1]['subnodes'][1])

				nodes[key]['meshes'] = []
				for node in range(len(segment_nodes)-4):
					var mesh_inst = _generate_road_segment(segment_nodes[node], segment_nodes[node+1], segment_nodes[node+2], segment_nodes[node+3], segment_nodes[node+4])
					$"../../World/Terrain".add_child(mesh_inst)
					active_meshes.append(mesh_inst)

				if active_meshes.size() > Road.segments * Road.sub_segments:
					while active_meshes.size() > Road.segments * Road.sub_segments:
						var old_mesh = active_meshes.pop_front()
						if old_mesh != null:
							old_mesh.queue_free()

func _generate_road_segment(a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3):
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var faces = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	# generate curve points
	var curve_points: Array[Vector3]
	curve_points.append(b)
	for seg in range(Road.resolution - 1):
		var t = (seg+1.0) / float(Road.resolution)
		curve_points.append(catmull_rom(a, b, c, d, t))
	curve_points.append(c)
	curve_points.append(catmull_rom(b, c, d, e, (1.0 / Road.resolution)))

	# generate road points
	for idx in range(len(curve_points)-1):
		var forwdir = (curve_points[idx+1] - curve_points[idx]).normalized()
		var rightdir = forwdir.cross(Vector3.UP).normalized()
		var normal = rightdir.cross(forwdir).normalized()
		verts.append(curve_points[idx] + rightdir * Road.width)
		verts.append(curve_points[idx] + -rightdir * Road.width)

		normals.append(normal)
		normals.append(normal)

	@warning_ignore("integer_division")
	for row in range((len(verts)-1)/2):
		indices.append(row * 2)
		indices.append(row * 2 + 1)
		indices.append((row+1) * 2)

		indices.append((row+1) * 2)
		indices.append(row * 2 + 1)
		indices.append((row+1) * 2 + 1)

		faces.append(verts[row * 2])
		faces.append(verts[row * 2 + 1])
		faces.append(verts[(row+1) * 2])

		faces.append(verts[(row+1) * 2])
		faces.append(verts[row * 2 + 1])
		faces.append(verts[(row+1) * 2 + 1])

	var v_total = 0.0  # track distance along the road
	# First, compute distances between points so V can be proportional
	var distances = []
	distances.append(0.0)
	for i in range(len(curve_points)-1):
		var dist = curve_points[i+1].distance_to(curve_points[i])
		distances.append(dist)
		v_total += dist

	var v_accum = 0.0
	for idx in range(len(curve_points)-1):
		var segment_len = distances[idx+1]
		# left vertex
		uvs.append(Vector2(0.0, v_accum / v_total))
		# right vertex
		uvs.append(Vector2(1.0, v_accum / v_total))

		v_accum += segment_len

	var mesh = ArrayMesh.new()
	var mesh_inst = MeshInstance3D.new()

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_inst.mesh = mesh
	
	var collision_shape = CollisionShape3D.new()
	var concave = ConcavePolygonShape3D.new()
	concave.set_faces(faces)
	collision_shape.shape = concave
	
	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	mesh_inst.add_child(static_body)

	var mat = ShaderMaterial.new()
	mat.shader = Road.road_shader
	mesh_inst.material_override = mat

	return mesh_inst

func catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0*p0 - 5.0*p1 + 4.0*p2 - p3) * t2 +
		(-p0 + 3.0*p1 - 3.0*p2 + p3) * t3
	)

func line_intersection(pos1: Vector2, dir1: Vector2, pos2: Vector2, dir2: Vector2) -> Vector2:
	var cross = dir1.x * dir2.y - dir1.y * dir2.x
	if abs(cross) < 0.00001:
		return Vector2.INF # parallel or nearly parallel
	
	var diff = pos2 - pos1
	var t = (diff.x * dir2.y - diff.y * dir2.x) / cross
	return pos1 + dir1 * t

func get_segment_dir(node: int) -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.seed = node + Noises.noise_seed
	var angle_offset = deg_to_rad(rng.randfn(0.0, Road.segment_max_degree))
	var forward = nodes[node]['dir']
	return forward.rotated(angle_offset).normalized()

func _terrain_sample(pos: Vector2, dir: Vector2) -> Vector3:
	var highest_sample = -INF
	var rotated_dir = Vector2(-dir.y, dir.x)
	var start = pos + rotated_dir * Road.width / 2.0
	for i in range(Road.road_samples):
		var step = Road.width / (Road.road_samples - 1)
		var l = i * step
		var sample_pos = start + -rotated_dir * l
		var height = noise.get_noise_2d(sample_pos.x, sample_pos.y) * Noises.height_scale
		var mountain_height = (abs(mountain_noise.get_noise_2d(sample_pos.x, sample_pos.y))**2) * Noises.mountain_height_scale
		var total_height = height + mountain_height + Road.road_height_epsilon

		if total_height > highest_sample:
			highest_sample = total_height
	return Vector3(pos.x, highest_sample, pos.y)
