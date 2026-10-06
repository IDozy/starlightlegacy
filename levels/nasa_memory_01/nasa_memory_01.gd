extends Node3D

const SCENE_PORTAL := preload("res://systems/navigation/scene_portal.tscn")

const FLOOR_COLOR := Color(0.10, 0.13, 0.16)
const WALL_COLOR := Color(0.60, 0.67, 0.70)
const CONSOLE_COLOR := Color(0.16, 0.23, 0.28)
const PANEL_COLOR := Color(0.035, 0.075, 0.10)
const BLUE_ACCENT := Color(0.20, 0.60, 0.92)
const CYAN_ACCENT := Color(0.34, 0.88, 0.94)
const ORANGE_ACCENT := Color(0.95, 0.45, 0.16)
const CREAM_COLOR := Color(0.86, 0.84, 0.76)

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
	world_environment.name = "MemoryEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.030, 0.055)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.60, 0.76)
	environment.ambient_light_energy = 0.72
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "MemoryKeyLight"
	key_light.rotation_degrees = Vector3(-48.0, 28.0, 0.0)
	key_light.light_color = Color(0.72, 0.84, 1.0)
	key_light.light_energy = 1.08
	key_light.shadow_enabled = true
	add_child(key_light)

	var cool_fill := OmniLight3D.new()
	cool_fill.name = "CoolLabFill"
	cool_fill.position = Vector3(0.0, 3.2, -1.5)
	cool_fill.omni_range = 11.0
	cool_fill.light_energy = 4.0
	cool_fill.light_color = Color(0.38, 0.68, 1.0)
	cool_fill.shadow_enabled = true
	add_child(cool_fill)

	var warm_memory := OmniLight3D.new()
	warm_memory.name = "WarmMemoryAccent"
	warm_memory.position = Vector3(0.0, 1.9, -4.8)
	warm_memory.omni_range = 7.0
	warm_memory.light_energy = 2.4
	warm_memory.light_color = Color(1.0, 0.52, 0.25)
	add_child(warm_memory)


func _build_lab() -> void:
	_create_box("Floor", Vector3(0, -0.1, 0), Vector3(14, 0.2, 12), FLOOR_COLOR)
	_create_box("BackWall", Vector3(0, 2.2, -6), Vector3(14, 4.4, 0.2), WALL_COLOR)
	_create_box("LeftWall", Vector3(-7, 2.2, 0), Vector3(0.2, 4.4, 12), WALL_COLOR)
	_create_box("RightWall", Vector3(7, 2.2, 0), Vector3(0.2, 4.4, 12), WALL_COLOR)

	# Floor guide lines visually pull the player toward the control consoles.
	_create_box("CenterGuide", Vector3(0, 0.015, -0.7), Vector3(0.10, 0.03, 9.0), BLUE_ACCENT, false, 1.1)
	_create_box("LeftGuide", Vector3(-2.9, 0.015, -0.7), Vector3(0.055, 0.03, 9.0), Color(0.24, 0.39, 0.52), false)
	_create_box("RightGuide", Vector3(2.9, 0.015, -0.7), Vector3(0.055, 0.03, 9.0), Color(0.24, 0.39, 0.52), false)

	# Large, simplified retro-navigation stations.
	_create_box("ConsoleLeft", Vector3(-2.75, 0.72, -3.6), Vector3(3.4, 1.44, 1.18), CONSOLE_COLOR)
	_create_box("ConsoleRight", Vector3(2.75, 0.72, -3.6), Vector3(3.4, 1.44, 1.18), CONSOLE_COLOR)
	_create_box("PanelLeft", Vector3(-2.75, 1.58, -4.08), Vector3(2.75, 1.32, 0.16), PANEL_COLOR)
	_create_box("PanelRight", Vector3(2.75, 1.58, -4.08), Vector3(2.75, 1.32, 0.16), PANEL_COLOR)

	_create_box("ScreenLeft", Vector3(-2.75, 1.72, -3.98), Vector3(1.18, 0.48, 0.06), Color(0.08, 0.28, 0.34), false, 1.7)
	_create_box("ScreenRight", Vector3(2.75, 1.72, -3.98), Vector3(1.18, 0.48, 0.06), Color(0.08, 0.28, 0.34), false, 1.7)

	for x in [-3.80, -3.25, -2.25, -1.70, 1.70, 2.25, 3.25, 3.80]:
		_create_box(
			"Indicator_%s" % str(x),
			Vector3(x, 1.34, -3.98),
			Vector3(0.14, 0.14, 0.06),
			ORANGE_ACCENT,
			false,
			2.0
		)

	# Bright ceiling bars create the clean, dreamlike NASA-memory silhouette.
	for x in [-4.8, -1.6, 1.6, 4.8]:
		_create_box(
			"CeilingLight_%s" % str(x),
			Vector3(x, 3.65, -0.4),
			Vector3(1.7, 0.06, 0.18),
			CYAN_ACCENT,
			false,
			1.65
		)

	# Back wall becomes a graphic mission-display wall instead of a flat grey rectangle.
	_create_box("MissionDisplay", Vector3(0.0, 2.45, -5.86), Vector3(3.9, 2.0, 0.05), Color(0.10, 0.28, 0.46), false, 0.65)
	_create_box("MissionStripe", Vector3(0.0, 1.65, -5.80), Vector3(3.15, 0.10, 0.06), ORANGE_ACCENT, false, 1.15)
	_create_box("MissionCore", Vector3(0.0, 2.52, -5.78), Vector3(0.55, 1.15, 0.07), CREAM_COLOR, false)
	_create_box("MissionWingLeft", Vector3(-0.64, 2.22, -5.77), Vector3(0.55, 0.12, 0.07), CREAM_COLOR, false)
	_create_box("MissionWingRight", Vector3(0.64, 2.22, -5.77), Vector3(0.55, 0.12, 0.07), CREAM_COLOR, false)

	# Chunky side frames give the room a grander, cinematic scale with very cheap geometry.
	for z in [-4.7, -2.2, 0.3, 2.8]:
		_create_box(
			"LeftFrame_%s" % str(z),
			Vector3(-6.35, 2.15, z),
			Vector3(0.32, 4.0, 0.24),
			Color(0.31, 0.40, 0.46),
			false
		)
		_create_box(
			"RightFrame_%s" % str(z),
			Vector3(6.35, 2.15, z),
			Vector3(0.32, 4.0, 0.24),
			Color(0.31, 0.40, 0.46),
			false
		)

	var portal := SCENE_PORTAL.instantiate()
	portal.position = Vector3(0.0, 0.65, 4.6)
	add_child(portal)


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
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box_size
		collision.shape = shape
		root.add_child(collision)

	add_child(root)
	return root


func _make_material(color: Color, emission_strength: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72

	if emission_strength > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength

	return material
