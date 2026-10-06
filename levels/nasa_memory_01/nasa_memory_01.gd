extends Node3D

const SCENE_PORTAL := preload("res://systems/navigation/scene_portal.tscn")

const FLOOR_COLOR := Color(0.14, 0.16, 0.18)
const WALL_COLOR := Color(0.62, 0.64, 0.62)
const CONSOLE_COLOR := Color(0.19, 0.24, 0.25)
const PANEL_COLOR := Color(0.07, 0.10, 0.11)
const ACCENT_COLOR := Color(0.88, 0.55, 0.16)

@onready var player = $Player
@onready var interaction_prompt: Label = $HUD/InteractionPrompt


func _ready() -> void:
	_build_environment()
	_build_lab()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.035, 0.045)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.63, 0.68)
	environment.ambient_light_energy = 0.75
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52.0, 25.0, 0.0)
	key_light.light_energy = 0.9
	key_light.shadow_enabled = true
	add_child(key_light)

	var lab_light := OmniLight3D.new()
	lab_light.position = Vector3(0.0, 3.0, -1.0)
	lab_light.omni_range = 10.0
	lab_light.light_energy = 5.0
	lab_light.light_color = Color(0.84, 0.9, 1.0)
	lab_light.shadow_enabled = true
	add_child(lab_light)


func _build_lab() -> void:
	_create_static_box("Floor", Vector3(0, -0.1, 0), Vector3(14, 0.2, 12), FLOOR_COLOR)
	_create_static_box("BackWall", Vector3(0, 2.2, -6), Vector3(14, 4.4, 0.2), WALL_COLOR)
	_create_static_box("LeftWall", Vector3(-7, 2.2, 0), Vector3(0.2, 4.4, 12), WALL_COLOR)
	_create_static_box("RightWall", Vector3(7, 2.2, 0), Vector3(0.2, 4.4, 12), WALL_COLOR)

	# Consolas de navegación provisionales, inspiradas en laboratorios de mediados del siglo XX.
	_create_static_box("ConsoleLeft", Vector3(-2.6, 0.7, -3.6), Vector3(3.2, 1.4, 1.1), CONSOLE_COLOR)
	_create_static_box("ConsoleRight", Vector3(2.6, 0.7, -3.6), Vector3(3.2, 1.4, 1.1), CONSOLE_COLOR)
	_create_static_box("PanelLeft", Vector3(-2.6, 1.55, -4.05), Vector3(2.6, 1.3, 0.18), PANEL_COLOR)
	_create_static_box("PanelRight", Vector3(2.6, 1.55, -4.05), Vector3(2.6, 1.3, 0.18), PANEL_COLOR)

	for x in [-3.35, -2.6, -1.85, 1.85, 2.6, 3.35]:
		_create_static_box(
			"Indicator_%s" % str(x),
			Vector3(x, 1.6, -3.94),
			Vector3(0.16, 0.16, 0.08),
			ACCENT_COLOR
		)

	var portal := SCENE_PORTAL.instantiate()
	portal.position = Vector3(0.0, 0.65, 4.6)
	add_child(portal)


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
	var mesh := BoxMesh.new()
	mesh.size = box_size

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	add_child(body)
	return body
