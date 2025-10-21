extends Node

@export var resolution := 32
@export var spacing := 4.0
@export var amplitude := 10.0

@onready var terrain_shader = preload("res://Shaders/terrain.gdshader")
@onready var mat: ShaderMaterial = ShaderMaterial.new()

var noise = FastNoiseLite.new()

const PI = 3.14159265359
const MAX_INT = 65535

func _ready():
	var base_mesh = create_base_mesh(resolution, spacing)
	
	mat.shader = terrain_shader

	var heights := PackedFloat32Array()
	var border_heights := PackedFloat32Array()
	var normals := PackedInt32Array()

	noise.seed = randi()
	noise.frequency = .02
	noise.fractal_octaves = 4
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# Calculate height for each point
	for z in range(resolution+3):
		for x in range(resolution+3):
			var height = noise.get_noise_2d(x, z) * amplitude

			if x == 0 or x== resolution+2:
				border_heights.append(height)
				continue

			elif z == 0 or z == resolution+2:
				border_heights.append(height)
				continue

			heights.append(height)

	# Calculate normals for each point and try not to kill yourself with this
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var base = z * (resolution + 1) + x
			var left_height = 0.0
			var right_height = 0.0
			var up_height = 0.0
			var down_height = 0.0
			
			if x == 0:
				var border_idx_x = resolution + 3 + 2 * z
				left_height = border_heights[border_idx_x]
				right_height = heights[base + 1]
			elif x == resolution:
				var border_idx_x = resolution + 4 + 2 * z
				right_height = border_heights[border_idx_x]
				left_height = heights[base - 1]
			else:
				left_height = heights[base - 1]
				right_height = heights[base + 1]

			if z == 0:
				var border_idx_y = 1 + x
				down_height = border_heights[border_idx_y]
				up_height = heights[ base + (resolution + 1)]
			elif z == resolution:
				var border_idx_y = 2 * (resolution + 1) + resolution + 4 + x
				up_height = border_heights[border_idx_y]
				down_height =  heights[base - (resolution + 1)]
			else:
				up_height = heights[base + (resolution + 1)]
				down_height =  heights[base - (resolution + 1)]

			var left = Vector3(-1.0, left_height, 0.0)
			var right = Vector3(1.0, right_height, 0.0)
			var down = Vector3(0.0, down_height, -1.0)
			var up = Vector3(0.0, up_height, 1.0)

			var dx = right - left
			var dz = up - down
			var normal = -dx.cross(dz).normalized()

			var yaw = atan2(normal.x, normal.z)
			var pitch = asin(clamp(normal.y, -1.0, 1.0))
			
			var pitch_i = int(round((pitch + PI/2.0) / PI * MAX_INT))
			var yaw_i = int(round((yaw + PI) / (2.0*PI) * MAX_INT))

			var normal_i = pack_normal(pitch_i, yaw_i)

			normals.append(normal_i)

		# Create the mesh

	# Create a MeshInstance3D to render it
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = base_mesh

	mesh_instance.material_override = mat

	mat.set_shader_parameter("resolution", resolution)
	mat.set_shader_parameter("spacing", spacing)
	mat.set_shader_parameter("amplitude", amplitude)
	mat.set_shader_parameter("heights", heights)
	mat.set_shader_parameter("normals", normals)

	add_child(mesh_instance)

func create_base_mesh(res: int, space: float) -> ArrayMesh:
	var verts = PackedVector3Array()
	
	for z in range(res + 1):
		for x in range(res + 1):
			verts.append(Vector3(x * space, 0.0, z * space))

	var mesh = ArrayMesh.new()

	for z in range(res):
		var indices = PackedInt32Array()
		for x in range(res + 1):
			var top = (z + 1) * (res + 1) + x
			var bottom = z * (res + 1) + x
			indices.append(top)
			indices.append(bottom)

		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_INDEX] = indices

		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)

	return mesh

func pack_normal(pitch_i: int, yaw_i: int) -> int:
	return (pitch_i & 0xFFFF) | ((yaw_i & 0xFFFF) << 16)
