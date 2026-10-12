extends Node3D

const INSPECTABLE_OBJECT := preload("res://systems/interaction/inspectable_object.tscn")
const GRANDFATHER := preload("res://systems/dialogue/grandfather_placeholder.tscn")
const RESCUE_ROVER_PROJECT := preload("res://systems/gameplay/rescue_rover_project.tscn")
const QUATERNIUS_SOLAR_PANEL := preload("res://assets/third_party/quaternius/ultimate_space_kit/Environment/GLTF/SolarPanel_Ground.gltf")

const FLOOR_COLOR := Color(0.19, 0.20, 0.22)
const WALL_COLOR := Color(0.73, 0.70, 0.63)
const WOOD_COLOR := Color(0.34, 0.22, 0.14)
const METAL_COLOR := Color(0.28, 0.31, 0.34)


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
	# Human-scale workshop bench: 2.4 m wide, 0.75 m deep, 0.90 m high.
	_create_static_box("WorkbenchTop", Vector3(0.0, 0.90, -3.7), Vector3(2.40, 0.08, 0.75), WOOD_COLOR)
	_create_static_box("WorkbenchLegFL", Vector3(-1.05, 0.44, -3.40), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegFR", Vector3(1.05, 0.44, -3.40), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegRL", Vector3(-1.05, 0.44, -4.00), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegRR", Vector3(1.05, 0.44, -4.00), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLowerShelf", Vector3(0.0, 0.24, -3.70), Vector3(2.05, 0.06, 0.56), METAL_COLOR)
	_create_static_box("WorkbenchBackboard", Vector3(0.0, 1.28, -4.04), Vector3(2.20, 0.68, 0.05), METAL_COLOR)

	# Side shelving.
	_create_static_box("ShelfFrame", Vector3(-4.9, 1.5, -1.0), Vector3(0.8, 3.0, 3.2), METAL_COLOR)
	_create_static_box("ShelfOne", Vector3(-4.45, 0.6, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)
	_create_static_box("ShelfTwo", Vector3(-4.45, 1.5, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)
	_create_static_box("ShelfThree", Vector3(-4.45, 2.4, -1.0), Vector3(0.9, 0.12, 3.0), WOOD_COLOR)

	var prototype_device := INSPECTABLE_OBJECT.instantiate()
	prototype_device.name = "PrototypeDevice"
	prototype_device.position = Vector3(-0.65, 1.03, -3.62)
	add_child(prototype_device)

	var rescue_rover := RESCUE_ROVER_PROJECT.instantiate()
	rescue_rover.name = "RescueRoverProject"
	rescue_rover.position = Vector3(0.0, 0.0, -0.9)
	rescue_rover.rotation_degrees = Vector3(0.0, 18.0, 0.0)
	add_child(rescue_rover)

	_add_quaternius_decor()

	var grandfather := GRANDFATHER.instantiate()
	grandfather.position = Vector3(2.7, 0.0, -2.6)
	grandfather.rotation_degrees = Vector3(0.0, -28.0, 0.0)
	add_child(grandfather)


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



func _add_quaternius_decor() -> void:
	var solar_body := StaticBody3D.new()
	solar_body.name = "WorkshopSolarPanel"
	solar_body.position = Vector3(4.35, 0.02, -2.65)
	solar_body.rotation_degrees = Vector3(0.0, -38.0, 0.0)

	var solar_panel := QUATERNIUS_SOLAR_PANEL.instantiate() as Node3D
	solar_panel.scale = Vector3.ONE * 0.72
	solar_body.add_child(solar_panel)

	var solar_collision := CollisionShape3D.new()
	var solar_shape := BoxShape3D.new()
	solar_shape.size = Vector3(1.05, 0.85, 1.20)
	solar_collision.position = Vector3(0.0, 0.40, 0.05)
	solar_collision.shape = solar_shape
	solar_body.add_child(solar_collision)

	add_child(solar_body)
