extends Node

@export var octaves := 14 # how detailed the noise is
@export var height_scale := 250.0 # how much the terrain will be scaled along the y axis
@export var frequency := 0.1 # how big the noise is
@export var frequency_scale := 1250.0 # scales the frequency (divides)
@export var mountain_octaves := 4
@export var mountain_height_scale := 5000
@export var mountain_frequency := 0.02
@export var mountain_frequency_scale := 2000
@export var noise_seed = 21654
@export var road_shader: VisualShader

var segments = 100
var segment_length = 100
var segment_max_degree = 5

var do_once = false

var resolution = 10
@export var width = 10.0
var spawn_node: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _gen_road():
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	noise.seed = noise_seed
	print(noise_seed)
	noise.frequency = frequency / frequency_scale
	noise.fractal_octaves = octaves
	
	var mountain_noise = FastNoiseLite.new()
	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_noise.seed = noise_seed
	mountain_noise.frequency = mountain_frequency / mountain_frequency_scale
	
	var points = [Vector3.ZERO]
	var forward = Vector2(1.0, 0.0)

	for i in range(segments):
		var angle_offset = deg_to_rad(randfn(0.0, segment_max_degree)) # in radians
		var new_dir_2d = Vector2(forward.x, forward.y).rotated(angle_offset).normalized()
		forward = new_dir_2d
		var start = points[len(points)-1]
		var end2d = Vector2(start.x, start.y) + new_dir_2d * segment_length
		var height = noise.get_noise_2d(end2d.x, end2d.y) * height_scale
		var mountain_height = (abs(mountain_noise.get_noise_2d(end2d.x, end2d.y))**2) * mountain_height_scale
		var total_height = height + mountain_height
		var end = Vector3(end2d.x, total_height, end2d.y)
		points.append(end)

	for idx in range(len(points)-4):
		_generate_road_segment(points[idx], points[idx+1], points[idx+2], points[idx+3], points[idx+4])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not do_once:
		if not noise_seed == 21654:
			_gen_road()
			do_once = true

func _generate_road_segment(a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3):
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var faces = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	# generate curve points
	var curve_points: Array[Vector3]
	curve_points.append(b)
	for seg in range(resolution - 1):
		var t = (seg+1.0) / float(resolution)
		curve_points.append(catmull_rom(a, b, c, d, t))
	curve_points.append(c)
	curve_points.append(catmull_rom(b, c, d, e, (1.0 / resolution)))

	# generate road points
	for idx in range(len(curve_points)-1):
		var forwdir = (curve_points[idx+1] - curve_points[idx]).normalized()
		var rightdir = forwdir.cross(Vector3.UP).normalized()
		var normal = rightdir.cross(forwdir).normalized()
		verts.append(curve_points[idx] + rightdir * width)
		verts.append(curve_points[idx] + -rightdir * width)
		
		normals.append(normal)
		normals.append(normal)

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
		var segment_length = distances[idx+1]
		# left vertex
		uvs.append(Vector2(0.0, v_accum / v_total))
		# right vertex
		uvs.append(Vector2(1.0, v_accum / v_total))

		v_accum += segment_length

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
	mat.shader = road_shader
	mesh_inst.material_override = mat

	$"../../World/Terrain".add_child(mesh_inst)

func catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0*p0 - 5.0*p1 + 4.0*p2 - p3) * t2 +
		(-p0 + 3.0*p1 - 3.0*p2 + p3) * t3
	)
