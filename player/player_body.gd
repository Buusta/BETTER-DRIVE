extends RigidBody3D

@onready var picture_camera: Camera3D = $SpringArm3D/subcam/CameraRenderer/PictureCamera
@onready var viewport_camera: Camera3D = $SpringArm3D/ViewportCamera
@onready var camera_renderer: Object = $SpringArm3D/subcam/CameraRenderer
@onready var ui_canvas: CanvasLayer = $CanvasLayer

@export var hold_point: Node3D

var zoomed := false

var latest_image: Image
var latest_texture: Texture2D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#func _take_picture():
	
	#picture_camera.global_transform = viewport_camera.global_transform
#
	#camera_renderer.render_target_update_mode = SubViewport.UPDATE_ONCE
#
	#await RenderingServer.frame_post_draw
#
	#latest_texture = camera_renderer.get_texture()
	#latest_image = camera_renderer.get_texture().get_image()
#
	##var img_tex = ImageTexture.create_from_image(latest_image)
	##ui_canvas.get_node("picture").texture = img_tex
#
	#var white_count = 0
#
	#for x in range(latest_image.get_width()):
		#for y in range(latest_image.get_height()):
			#var color = latest_image.get_pixel(x, y)
			#if color.r == 1.0:
				#white_count += 1
#
	#var total_pixels = latest_image.get_width() * latest_image.get_height()
	#var ufo_coverage = sqrt(float(white_count) / total_pixels)
#
	#var score_dict = {
		#0.15: "S",
		#0.11: "A",
		#0.09: "B",
		#0.06: "C",
		#0.03: "D",
		#0.01: "F"
	#}
#
	#for key in score_dict.keys():
		#
		#print(key, ' ', ufo_coverage)
		#if ufo_coverage >= key:
			#print(score_dict[key])
			#break
#
	#print("UFO coverage:", ufo_coverage)

func camera_zoom():
	if not zoomed:
		viewport_camera.fov = 25.0
		zoomed = true
	else:
		viewport_camera.fov = 85.0
		zoomed = false
