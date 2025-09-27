@tool
extends MeshInstance3D


@export var resolution: int = 32
@export var height_scale: float = float(25)
@export var frequency: float = float(.05)

var threads: Array[Thread] = []
var thread_count:= OS.get_processor_count()# - 4

@export var regenerate: bool:
	set(value):
		if value:
			generate_mesh()
			regenerate = false
	get():
		return false

var ThreadCount = OS.get_processor_count() - 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in thread_count:
		var new_thread: Thread = Thread.new()
		threads.append(new_thread)
	
func _on_regenrate_changed():
	generate_mesh()
	
func generate_mesh():
	

	var start_time = Time.get_ticks_msec()  # start timing
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# Configure
	noise.seed = randi()
	noise.frequency = frequency
	noise.fractal_octaves = 3
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var height = noise.get_noise_2d(x, z) * height_scale
			var vert = Vector3(x, height, z)
			st.add_vertex(vert)
			
	for z in range(resolution):
		for x in range(resolution):
			var base = z * (resolution + 1) + x
			st.add_index(base)
			st.add_index(base + 1)
			st.add_index(base + resolution + 1)

			st.add_index(base + 1)
			st.add_index(base + resolution + 2)
			st.add_index(base + resolution + 1)
	
	st.generate_normals()
	
	mesh = st.commit()
	
	

func frac(x: float) -> float:
	return x - floor(x)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
