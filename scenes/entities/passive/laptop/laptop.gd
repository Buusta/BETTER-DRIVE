extends MeshInstance3D

@onready var viewport_tex = $LaptopDisplay.get_texture()
@onready var screen_viewport: SubViewport = $LaptopDisplay

func turn_on_screen(interactor: Node):
    print('beep boop ', interactor)

func _ready():
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = viewport_tex
    mat.emission_enabled = true
    mat.emission_texture = viewport_tex
    mat.emission_energy_multiplier = 1.0
    
    set_surface_override_material(1, mat)


var pending_click_pos: Vector2

func _unhandled_input(event):
    if event is InputEventMouseButton and event.is_released():
        pending_click_pos = event.position

func _physics_process(_delta):
    if pending_click_pos != Vector2.ZERO:
        _check_screen_hit(pending_click_pos)
        pending_click_pos = Vector2.ZERO


func _check_screen_hit(mouse_pos: Vector2):
    var cam = get_viewport().get_camera_3d()
    if not cam:
        return

    var from = cam.project_ray_origin(mouse_pos)
    var to = from + cam.project_ray_normal(mouse_pos) * 1000.0

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1 << 2  # Only hit objects on layer 3

    var result = space_state.intersect_ray(query)

    if result and result.collider.is_in_group("UIScreen"):
        var hit_pos = result.position
        _process_screen_hit(hit_pos, result.collider.get_node('UIScreenComponent').CollisionShape)

func _process_screen_hit(hit_pos: Vector3, hitbox: CollisionShape3D):
    var local_pos = hitbox.global_transform.affine_inverse() * hit_pos
    var size = hitbox.shape.extents * 2.0  # BoxShape3D

    var uv = Vector2(
        (local_pos.x / size.x) + 0.5,
        (-local_pos.z / size.z) + 0.5
    )

    var viewport = $LaptopDisplay
    var pixel = uv * Vector2(viewport.size)

    pixel.x = viewport.size.x - pixel.x

    # Forward as a viewport input
    var mouse_event = InputEventMouseButton.new()
    mouse_event.button_index = MouseButton.MOUSE_BUTTON_LEFT
    mouse_event.pressed = true
    mouse_event.position = pixel
    mouse_event.global_position = pixel  # optional
    viewport.push_input(mouse_event)
