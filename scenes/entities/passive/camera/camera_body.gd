extends RigidBody3D

@onready var screen_texture: ViewportTexture = camera_viewport.get_texture()

@export var camera_shape: Node3D
@export var camera_viewport: SubViewport
@export var camera_cam: Camera3D
@export var camera_mesh: MeshInstance3D
@export var camera_timer: Timer
@export var inventory_item_component: Node
@export var viewport_resolution := Vector2i(320, 180)
@export var photo_resolution := Vector2i(1280, 720)


@onready var standard_camera_time: float = camera_timer.wait_time

var photoroll: Array[Dictionary]
var max_photos := 5

func _ready() -> void:
	setup_camera_screen()
	camera_viewport.size = viewport_resolution

func interacted(player: Node3D):
	player.get_node('TakePictureComponent').camera = self
	player.get_node('InventoryComponent')._try_add_item(self, inventory_item_component.inventory_item_struct)

func setup_camera_screen():
	#var screen_texture: ViewportTexture = camera_viewport.get_texture()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = screen_texture
	mat.emission_enabled = true
	mat.emission_texture = screen_texture
	mat.emission_energy_multiplier = 0.85
	mat.roughness = 0.3

	camera_mesh.set_surface_override_material(2, mat)

func _process(_delta: float) -> void:
	camera_cam.global_transform = global_transform

func _take_photo(score: float):
	if not camera_timer.time_left == 0.0:
		return

	camera_timer.start(standard_camera_time)

	camera_viewport.size = photo_resolution
	await RenderingServer.frame_post_draw

	var img = camera_viewport.get_texture().get_image()

	img.convert(Image.FORMAT_RGBA8)

	# Generate a name
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "photo_%s.jpg" % timestamp

	# Ensure save dir exists
	var dir_path = "user://photos/"
	DirAccess.make_dir_recursive_absolute(dir_path)

	# Save
	var save_path = dir_path + filename
	var err = img.save_jpg(save_path)
	if err != OK:
		push_error("Failed to save photo: %s" % error_string(err))
		camera_viewport.size = viewport_resolution
		return

	if photoroll.size() >= max_photos:
		photoroll.pop_front() # remove the oldest one
	photoroll.append({
		"texture": ImageTexture.create_from_image(img),
		"score": score,
		"timestamp": Time.get_datetime_string_from_system(),
		})

	print(photoroll)

	print("📸 Saved photo:", save_path)
	camera_viewport.size = viewport_resolution
