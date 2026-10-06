extends Node3D

const INSPECTABLE_OBJECT := preload("res://systems/interaction/inspectable_object.tscn")
const GRANDFATHER := preload("res://systems/dialogue/grandfather_placeholder.tscn")

const FLOOR_COLOR := Color(0.095, 0.075, 0.065)
const WALL_COLOR := Color(0.56, 0.46, 0.36)
const WOOD_COLOR := Color(0.34, 0.19, 0.10)
const WOOD_LIGHT_COLOR := Color(0.50, 0.29, 0.15)
const METAL_COLOR := Color(0.20, 0.25, 0.29)
const RUG_COLOR := Color(0.16, 0.29, 0.32)
const CREAM_COLOR := Color(0.88, 0.78, 0.61)
const ORANGE_COLOR := Color(0.93, 0.43, 0.15)
const CYAN_COLOR := Color(0.35, 0.86, 0.88)
const NIGHT_BLUE := Color(0.035, 0.055, 0.085)


func _ready() -> void:
	_build_lighting()
	_build_room()
	_build_workshop_props()
	_build_sunset_view()


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = NIGHT_BLUE
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.62, 0.55)
	environment.ambient_light_energy = 0.42
	world_environment.environment = environment
	add_child(world_environment)

	var sunset_light := DirectionalLight3D.new()
	sunset_light.name = "SunsetLight"
	sunset_light.rotation_degrees = Vector3(-42.0, 155.0, 0.0)
	sunset_light.light_color = Color(1.0, 0.70, 0.46)
	sunset_light.light_energy = 0.78
	sunset_light.shadow_enabled = true
	add_child(sunset_light)

	var bench_light := OmniLight3D.new()
	bench_light.name = "BenchWarmLight"
	bench_light.position = Vector3(-0.4, 2.75, -2.9)
	bench_light.omni_range = 6.5
	bench_light.light_energy = 1.9
	bench_light.light_color = Color(1.0, 0.58, 0.28)
	bench_light.shadow_enabled = true
	add_child(bench_light)

	var window_fill := OmniLight3D.new()
	window_fill.name = "WindowFill"
	window_fill.position = Vector3(0.0, 2.5, 4.3)
	window_fill.omni_range = 8.0
	window_fill.light_energy = 1.15
	window_fill.light_color = Color(0.53, 0.67, 1.0)
	add_child(window_fill)


func _build_room() -> void:
	_create_box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(12.0, 0.2, 10.0), FLOOR_COLOR)
	_create_box("BackWall", Vector3(0.0, 2.0, -5.0), Vector3(12.0, 4.0, 0.2), WALL_COLOR)
	_create_box("LeftWall", Vector3(-6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)
	_create_box("RightWall", Vector3(6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)

	# Dark warm roof panel prevents the ceiling from reading as an empty black void.
	_create_box("Ceiling", Vector3(0.0, 3.92, 0.0), Vector3(12.0, 0.12, 10.0), Color(0.075, 0.052, 0.045), false)

	# A wide front opening frames the sunset and gives the workshop a calm, airy feel.
	_create_box("FrontWallLeft", Vector3(-4.35, 2.0, 5.0), Vector3(3.3, 4.0, 0.2), WALL_COLOR)
	_create_box("FrontWallRight", Vector3(4.35, 2.0, 5.0), Vector3(3.3, 4.0, 0.2), WALL_COLOR)
	_create_box("FrontWallTop", Vector3(0.0, 3.55, 5.0), Vector3(5.4, 0.9, 0.2), WALL_COLOR)

	# Chunky timber beams keep the space stylized instead of realistic.
	for x in [-5.1, -2.55, 0.0, 2.55, 5.1]:
		_create_box(
			"CeilingBeam_%s" % str(x),
			Vector3(x, 3.72, 0.0),
			Vector3(0.18, 0.20, 9.7),
			WOOD_COLOR,
			false
		)

	_create_box("BackTrim", Vector3(0.0, 0.18, -4.86), Vector3(11.6, 0.18, 0.12), WOOD_LIGHT_COLOR, false)
	_create_box("LeftTrim", Vector3(-5.86, 0.18, 0.0), Vector3(0.12, 0.18, 9.6), WOOD_LIGHT_COLOR, false)
	_create_box("RightTrim", Vector3(5.86, 0.18, 0.0), Vector3(0.12, 0.18, 9.6), WOOD_LIGHT_COLOR, false)

	# Soft rug anchors the playable area visually.
	_create_box("Rug", Vector3(0.3, 0.015, 0.2), Vector3(5.0, 0.03, 3.4), RUG_COLOR, false)


func _build_workshop_props() -> void:
	# Main workbench: thick, warm and readable from across the room.
	_create_box("WorkbenchTop", Vector3(0.0, 1.0, -3.65), Vector3(4.5, 0.22, 1.25), WOOD_LIGHT_COLOR)
	_create_box("WorkbenchApron", Vector3(0.0, 0.82, -3.72), Vector3(4.15, 0.28, 0.16), WOOD_COLOR, false)
	_create_box("WorkbenchLegLeft", Vector3(-1.85, 0.48, -3.65), Vector3(0.28, 0.95, 0.86), METAL_COLOR)
	_create_box("WorkbenchLegRight", Vector3(1.85, 0.48, -3.65), Vector3(0.28, 0.95, 0.86), METAL_COLOR)

	# Side shelving with fewer, larger forms: more storybook, less visual noise.
	_create_box("ShelfBack", Vector3(-4.95, 1.55, -0.8), Vector3(0.16, 3.0, 3.35), METAL_COLOR)
	for y in [0.58, 1.45, 2.32]:
		_create_box(
			"Shelf_%s" % str(y),
			Vector3(-4.45, y, -0.8),
			Vector3(0.95, 0.14, 3.10),
			WOOD_LIGHT_COLOR
		)

	# Storage crates and keepsakes.
	_create_box("CrateOne", Vector3(-4.35, 0.28, 2.75), Vector3(1.05, 0.55, 0.95), WOOD_COLOR)
	_create_box("CrateTwo", Vector3(-3.25, 0.20, 3.15), Vector3(0.78, 0.40, 0.72), CREAM_COLOR)
	_create_box("ToolCase", Vector3(3.85, 0.28, -3.65), Vector3(1.15, 0.55, 0.75), METAL_COLOR)
	_create_box("ToolCaseStripe", Vector3(3.85, 0.38, -3.25), Vector3(0.82, 0.12, 0.03), ORANGE_COLOR, false)

	# Retro wall cards hint at rockets and old mission diagrams.
	_create_box("PosterWarm", Vector3(-2.2, 2.35, -4.86), Vector3(1.45, 1.35, 0.04), Color(0.77, 0.49, 0.28), false)
	_create_box("PosterBlue", Vector3(-0.45, 2.45, -4.86), Vector3(1.45, 1.15, 0.04), Color(0.20, 0.39, 0.49), false)
	_create_box("PosterCream", Vector3(1.35, 2.30, -4.86), Vector3(1.35, 1.45, 0.04), CREAM_COLOR, false)

	# Warm trim behind the bench adds depth and separates furniture from the wall.
	_create_box("BenchBackGlow", Vector3(0.0, 1.15, -4.76), Vector3(5.2, 1.05, 0.035), Color(0.26, 0.14, 0.085), false)
	_create_box("BenchAccentLine", Vector3(0.0, 1.62, -4.72), Vector3(4.35, 0.055, 0.04), ORANGE_COLOR, false, 0.55)

	# Stylized desk lamp with a warm emissive bulb.
	_create_box("LampStem", Vector3(-1.40, 1.72, -3.45), Vector3(0.10, 1.15, 0.10), METAL_COLOR, false)
	_create_box("LampArm", Vector3(-1.10, 2.16, -3.45), Vector3(0.65, 0.10, 0.10), METAL_COLOR, false)
	_create_sphere("LampGlow", Vector3(-0.76, 2.12, -3.45), 0.16, Color(1.0, 0.58, 0.27), 2.8)

	# A tiny rocket model makes the NASA theme visible before any memory sequence.
	_create_box("RocketStand", Vector3(1.48, 1.18, -3.50), Vector3(0.34, 0.08, 0.34), METAL_COLOR, false)
	_create_cylinder("RocketBody", Vector3(1.48, 1.65, -3.50), 0.13, 0.78, CREAM_COLOR)
	_create_cylinder("RocketTip", Vector3(1.48, 2.08, -3.50), 0.08, 0.20, ORANGE_COLOR)

	var prototype_device := INSPECTABLE_OBJECT.instantiate()
	prototype_device.name = "PrototypeDevice"
	prototype_device.position = Vector3(0.0, 1.38, -3.60)
	prototype_device.rotation_degrees = Vector3(-3.0, 0.0, 0.0)
	add_child(prototype_device)

	var grandfather := GRANDFATHER.instantiate()
	grandfather.position = Vector3(2.75, 0.0, -2.55)
	grandfather.rotation_degrees = Vector3(0.0, -30.0, 0.0)
	add_child(grandfather)


func _build_sunset_view() -> void:
	# Cheap Web-friendly "painted" horizon made from large simple shapes.
	_create_box("HorizonWarm", Vector3(0.0, 0.55, 8.7), Vector3(18.0, 1.2, 0.18), Color(0.88, 0.42, 0.22), false)
	_create_box("HorizonLavender", Vector3(0.0, 1.75, 8.9), Vector3(18.0, 1.35, 0.18), Color(0.48, 0.43, 0.62), false)
	_create_box("HorizonSky", Vector3(0.0, 3.0, 9.1), Vector3(18.0, 1.6, 0.18), Color(0.28, 0.46, 0.68), false)
	_create_sphere("SunDisc", Vector3(2.0, 1.55, 8.35), 0.52, Color(1.0, 0.76, 0.42), 3.4)

	# Layered mountain silhouettes.
	_create_box("MountainFarLeft", Vector3(-4.2, 0.70, 8.15), Vector3(4.2, 1.45, 0.32), Color(0.22, 0.29, 0.39), false)
	_create_box("MountainFarRight", Vector3(4.6, 0.62, 8.05), Vector3(5.0, 1.25, 0.34), Color(0.18, 0.25, 0.34), false)


func _create_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	color: Color,
	with_collision: bool = true,
	emission_strength: float = 0.0
) -> Node3D:
	var root: Node3D

	if with_collision:
		root = StaticBody3D.new()
	else:
		root = Node3D.new()

	root.name = box_name
	root.position = box_position

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = _make_material(color, emission_strength)
	mesh_instance.mesh = mesh
	root.add_child(mesh_instance)

	if with_collision:
		var collision_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box_size
		collision_shape.shape = shape
		root.add_child(collision_shape)

	add_child(root)
	return root


func _create_sphere(
	sphere_name: String,
	sphere_position: Vector3,
	radius: float,
	color: Color,
	emission_strength: float = 0.0
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = sphere_name
	mesh_instance.position = sphere_position

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _make_material(color, emission_strength)
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	return mesh_instance


func _create_cylinder(
	cylinder_name: String,
	cylinder_position: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = cylinder_name
	mesh_instance.position = cylinder_position

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _make_material(color)
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	return mesh_instance


func _make_material(color: Color, emission_strength: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78

	if emission_strength > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength

	return material
