extends Node3D

const FLOOR_COLOR := Color(0.19, 0.20, 0.22)
const WALL_COLOR := Color(0.73, 0.70, 0.63)
const WOOD_COLOR := Color(0.34, 0.22, 0.14)
const METAL_COLOR := Color(0.28, 0.31, 0.34)
const ACCENT_COLOR := Color(0.86, 0.39, 0.12)


func _ready() -> void:
	_build_lighting()
	_build_room()
	_build_workshop_props()


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.055, 0.065, 0.085)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.60, 0.70)
	environment.ambient_light_energy = 0.7
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)

	var workshop_light := OmniLight3D.new()
	workshop_light.name = "WorkshopLight"
	workshop_light.position = Vector3(0.0, 3.2, 0.0)
	workshop_light.omni_range = 9.0
	workshop_light.light_energy = 4.0
	workshop_light.shadow_enabled = true
	add_child(workshop_light)


func _build_room() -> void:
	_create_static_box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(12.0, 0.2, 10.0), FLOOR_COLOR)
	_create_static_box("BackWall", Vector3(0.0, 2.0, -5.0), Vector3(12.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("LeftWall", Vector3(-6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)
	_create_static_box("RightWall", Vector3(6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)

	# Front wall leaves a central opening that will later become the workshop entrance.
	_create_static_box("FrontWallLeft", Vector3(-4.0, 2.0, 5.0), Vector3(4.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("FrontWallRight", Vector3(4.0, 2.0, 5.0), Vector3(4.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("FrontWallTop", Vector3(0.0, 3.5, 5.0), Vector3(4.0, 1.0, 0.2), WALL_COLOR)


func _build_workshop_props() -> void:
	# Main workbench.
	_create_static_box("WorkbenchTop", Vector3(0.0, 1.0, -3.7), Vector3(4.0, 0.18, 1.1), WOOD_COLOR)
	_create_static_box("WorkbenchLegLeft", Vector3(-1.65, 0.5, -3.7), Vector3(0.22, 1.0, 0.8), METAL_COLOR)
	_create_static_box("WorkbenchLegRight", Vector3(1.65, 0.5, -3.7), Vector3(0.22, 1.0, 0.8), METAL_COLOR)

	# Side shelving.
	_create_static_box("ShelfFrame", Vector3(-4.9, 1.5, -1.0), Vector3(0.8, 3.0, 3.2), METAL_COLOR)
	_create_static_box("ShelfOne", Vector3(-4.45, 0.6, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)
	_create_static_box("ShelfTwo", Vector3(-4.45, 1.5, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)
	_create_static_box("ShelfThree", Vector3(-4.45, 2.4, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)

	# Placeholder "space hardware" on the central bench.
	_create_static_box("PrototypeDevice", Vector3(0.0, 1.35, -3.65), Vector3(0.9, 0.5, 0.65), ACCENT_COLOR)


func _create_static_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	color: Color
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = box_position

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	box_mesh.material = material

	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_size
	collision_shape.shape = box_shape
	body.add_child(collision_shape)

	add_child(body)
	return body
