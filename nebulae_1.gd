extends Parallax2D

@export var zoom_factor := 0.4   # entre más pequeño, más lento el zoom
@export var move_factor := 0.4   # entre más pequeño, más lento se mueve

var camera: Camera2D = null
var base_position := Vector2.ZERO

func _ready():
	camera = get_viewport().get_camera_2d()
	base_position = global_position
	add_to_group("zoom_parallax_obj")

func _process(delta):
	if camera:
		# Movimiento parallax manual (sin layers)
		global_position = base_position + (camera.global_position * move_factor)

func apply_zoom(cam_zoom: Vector2):
	# Parallax de zoom (zoom más lento)
	scale = cam_zoom * zoom_factor
