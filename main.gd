extends Node2D

@onready var sun = $Sun
@onready var camera = $Camera2D
@onready var planet_label = $CanvasLayer/PlanetLabel

var planets = [
	{"name": "Mercury", "a": 5.79e10,  "e": 0.205, "mass": 3.30e23, "node": null, "velocity": Vector2.ZERO},
	{"name": "Venus",   "a": 1.082e11, "e": 0.007, "mass": 4.87e24, "node": null, "velocity": Vector2.ZERO},
	{"name": "Earth",   "a": 1.496e11, "e": 0.017, "mass": 5.97e24, "node": null, "velocity": Vector2.ZERO},
	{"name": "Mars",    "a": 2.279e11, "e": 0.093, "mass": 6.42e23, "node": null, "velocity": Vector2.ZERO},
	{"name": "Jupiter", "a": 7.785e11, "e": 0.048, "mass": 1.90e27, "node": null, "velocity": Vector2.ZERO},
	{"name": "Saturn",  "a": 1.433e12, "e": 0.056, "mass": 5.68e26, "node": null, "velocity": Vector2.ZERO},
	{"name": "Uranus",  "a": 2.872e12, "e": 0.046, "mass": 8.68e25, "node": null, "velocity": Vector2.ZERO},
	{"name": "Neptune", "a": 4.495e12, "e": 0.010, "mass": 1.02e26, "node": null, "velocity": Vector2.ZERO},
]

var trails = {}
var last_positions = {}
var distance_accum = {}

const G = 6.674e-11
const M_SUN = 1.989e30
const METERS_PER_PIXEL = 2e8
const TIME_SCALE = 300000
const TRAIL_SPACING_PX = 50.0

var target_planet : Node2D = null
var zooming_in := false
const ZOOM_SPEED := 0.05
const TARGET_ZOOM := 5.1

# ✅ Movimiento del Sol
var dragging_sun := false


func _ready():
	$Stars/Stars/SpaceBackground.z_index = -100
	$Nebulae.z_index = -100
	$Dust1/Dust1/Sprite2D.z_index = -100

	camera.zoom = Vector2.ONE

	for planet_data in planets:
		planet_data["node"] = get_node_or_null(planet_data["name"])
		if planet_data["node"] == null:
			continue

		var angle = randf() * TAU
		var r_m = planet_data["a"] * (1 - planet_data["e"])
		var r_px = r_m / METERS_PER_PIXEL
		var offset = Vector2(cos(angle), sin(angle)) * r_px
		planet_data["node"].global_position = sun.global_position + offset

		var dir = (sun.global_position - planet_data["node"].global_position).normalized()
		var v_m_per_s = sqrt(G * M_SUN * (2 / r_m - 1 / planet_data["a"]))
		var v_px_per_s = v_m_per_s / METERS_PER_PIXEL
		planet_data["velocity"] = Vector2(-dir.y, dir.x) * v_px_per_s

		trails[planet_data["name"]] = []
		last_positions[planet_data["name"]] = planet_data["node"].global_position
		distance_accum[planet_data["name"]] = 0.0


func _physics_process(delta):
	for planet_data in planets:
		if planet_data["node"] != null:
			update_planet_orbit(planet_data, delta * TIME_SCALE)
			update_trail_distance(planet_data)

	if target_planet != null:
		camera.global_position = camera.global_position.lerp(
			target_planet.global_position, 0.1
		)

		if zooming_in:
			camera.zoom = camera.zoom.lerp(Vector2(TARGET_ZOOM, TARGET_ZOOM), ZOOM_SPEED)

			var data = get_planet_data(target_planet)
			if data != null:
				var speed_px = data["velocity"].length()
				var speed_m = speed_px * METERS_PER_PIXEL
				var speed_km_s = speed_m / 1000.0

				var distance_m = target_planet.global_position.distance_to(
					sun.global_position
				) * METERS_PER_PIXEL
				var distance_km = distance_m / 1000.0

				var mass_scientific = String.num_scientific(data["mass"]) + " kg"

				planet_label.text = "Name: " + data["name"] + "\n" + "Mass: " + mass_scientific + "\n" + "Speed: " + str(snapped(speed_km_s, 0.01)) + " km/s\n" + "Distance to Sun: " + str(snapped(distance_km, 1)) + " km"

				planet_label.visible = true
		else:
			planet_label.visible = false


func update_planet_orbit(planet_data, delta):
	var planet = planet_data["node"]
	var velocity = planet_data["velocity"]

	var sun_center = sun.global_position
	if sun is Sprite2D and sun.texture:
		sun_center += sun.texture.get_size() * sun.scale * 0.5

	var dir_px = sun_center - planet.global_position
	var r_px = dir_px.length()
	if r_px < 1.0:
		return

	var r_m = r_px * METERS_PER_PIXEL
	var accel_m_per_s2 = G * M_SUN / (r_m * r_m)
	var accel_px_per_s2 = accel_m_per_s2 / METERS_PER_PIXEL
	var accel_vector_px = dir_px.normalized() * accel_px_per_s2

	velocity += accel_vector_px * delta
	planet.global_position += velocity * delta
	planet_data["velocity"] = velocity


# ✅ ESTELA
func update_trail_distance(planet_data):
	var name = planet_data["name"]
	var planet = planet_data["node"]

	if not last_positions.has(name):
		last_positions[name] = planet.global_position
		distance_accum[name] = 0.0
		trails[name] = []
		return

	var last_pos = last_positions[name]
	var current_pos = planet.global_position
	var moved = last_pos.distance_to(current_pos)

	distance_accum[name] += moved

	if distance_accum[name] >= TRAIL_SPACING_PX:
		var dot = Node2D.new()
		dot.set_script(preload("res://scripts/Dot.gd"))
		dot.global_position = current_pos
		dot.z_index = planet.z_index - 1
		add_child(dot)

		trails[name].append(dot)

		if trails[name].size() > 32:
			var old_dot = trails[name].pop_front()
			if is_instance_valid(old_dot):
				old_dot.queue_free()

		distance_accum[name] = 0.0

	last_positions[name] = current_pos


# ✅ INPUT: PLANETAS + SOL
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var click_pos = camera.get_global_mouse_position()

				# ✅ Detectar click en el Sol
				if sun.global_position.distance_to(click_pos) < 40:
					dragging_sun = true
					target_planet = null
					zooming_in = false
					planet_label.visible = false
					return

				# ✅ Detectar click en planetas
				for planet_data in planets:
					var planet = planet_data["node"]
					if planet != null and planet.position.distance_to(click_pos) < 20:
						target_planet = planet
						zooming_in = true
						return

				target_planet = null
				zooming_in = false
				planet_label.visible = false

			else:
				dragging_sun = false

	# ✅ Arrastrar el Sol
	if event is InputEventMouseMotion and dragging_sun:
		sun.global_position += event.relative


func get_planet_data(node: Node2D):
	for planet_data in planets:
		if planet_data["node"] == node:
			return planet_data
	return null
