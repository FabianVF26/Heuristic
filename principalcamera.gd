extends Camera2D

const ZOOM_SPEED := 0.1
const ZOOM_MIN := 0.08
const ZOOM_MAX := 1.0

var dragging := false

func _ready():
	enabled = true

	limit_left = -31328.637
	limit_right = 31328.637
	limit_top = -26784.488
	limit_bottom = 26784.488

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 2:
			dragging = event.pressed

		if event.button_index == 4:
			zoom_camera(-ZOOM_SPEED)
		elif event.button_index == 5:
			zoom_camera(ZOOM_SPEED)

	if event is InputEventMouseMotion and dragging:
		move_camera(event.relative)

func move_camera(relative : Vector2) -> void:
	# Movimiento rastreable (usa global_position)
	global_position -= relative * zoom

	clamp_position()

func zoom_camera(amount : float) -> void:
	var before = get_global_mouse_position()

	var new_zoom = zoom * (1.0 + amount)
	new_zoom.x = clamp(new_zoom.x, ZOOM_MIN, ZOOM_MAX)
	new_zoom.y = clamp(new_zoom.y, ZOOM_MIN, ZOOM_MAX)
	zoom = new_zoom

	var after = get_global_mouse_position()
	global_position += before - after

	clamp_position()
	
	

	
func clamp_position():
	global_position.x = clamp(global_position.x, limit_left, limit_right)
	global_position.y = clamp(global_position.y, limit_top, limit_bottom)
