extends Node3D

const PATHFINDER_STORY := preload("res://systems/gameplay/pathfinder_story_point.tscn")
const SOJOURNER_CHALLENGE := preload("res://systems/gameplay/sojourner_scan_challenge.tscn")
const SCENE_PORTAL := preload("res://systems/navigation/scene_portal.tscn")

const PATHFINDER_DISCOVERY_ID := "mars_pathfinder_lander"
const SOJOURNER_DISCOVERY_ID := "sojourner_apxs"

const SAND := Color(0.48, 0.24, 0.14)
const SAND_LIGHT := Color(0.62, 0.33, 0.19)
const ROCK := Color(0.34, 0.20, 0.15)
const ROCK_DARK := Color(0.23, 0.14, 0.12)
const TRACK := Color(0.20, 0.12, 0.10)
const AIRBAG := Color(0.73, 0.68, 0.57)

@onready var player = $Player
@onready var crosshair: Label = $HUD/Crosshair
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var objective_label: Label = $HUD/Objective
@onready var narration_label: Label = $HUD/Narration

var _pathfinder: Node = null
var _sojourner: Node = null
var _return_portal: Node = null


func _ready() -> void:
	_build_environment()
	_build_ares_vallis()

	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	narration_label.visible = false

	var pathfinder_done := _has_discovery(PATHFINDER_DISCOVERY_ID)
	var sojourner_done := _has_discovery(SOJOURNER_DISCOVERY_ID)

	_pathfinder.call("set_completed_state", pathfinder_done)
	_sojourner.call("set_completed_state", sojourner_done)
	_update_progress(false)


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()


func _on_story_active_changed(active: bool) -> void:
	crosshair.visible = not active

	if active:
		interaction_prompt.visible = false


func _on_challenge_active_changed(active: bool) -> void:
	crosshair.visible = not active

	if active:
		interaction_prompt.visible = false


func _on_pathfinder_story_completed() -> void:
	narration_label.text = "Abuelo: Ahí empezó la historia. Pathfinder abrió sus pétalos y dejó salir a Sojourner. Sigue sus huellas."
	narration_label.visible = true
	_update_progress(false)


func _on_sojourner_completed() -> void:
	narration_label.text = "Abuelo: No hemos traído la máquina de vuelta. Hemos recuperado lo que hizo, lo que aprendió y por qué todavía importa."
	narration_label.visible = true
	_update_progress(true)


func _update_progress(show_completion: bool) -> void:
	var pathfinder_done := _has_discovery(PATHFINDER_DISCOVERY_ID)
	var sojourner_done := _has_discovery(SOJOURNER_DISCOVERY_ID)

	if not pathfinder_done:
		objective_label.text = "OBJETIVO 1/2 · Examina Mars Pathfinder."
		return

	if not sojourner_done:
		objective_label.text = "OBJETIVO 2/2 · Sigue las huellas hasta Sojourner y analiza Yogi."
		return

	_unlock_return_portal()

	if show_completion:
		objective_label.text = "HISTORIA RECUPERADA · Pathfinder + Sojourner · Regresa al taller."


func _unlock_return_portal() -> void:
	if _return_portal != null:
		return

	_return_portal = SCENE_PORTAL.instantiate()
	_return_portal.position = Vector3(-2.2, 0.65, 3.4)
	add_child(_return_portal)


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("has_discovery"):
		return false

	return bool(registry.call("has_discovery", discovery_id))


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "MarsEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.33, 0.15, 0.10)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.43, 0.30)
	environment.ambient_light_energy = 0.58
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "MarsSun"
	sun.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.72, 0.54)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)


func _build_ares_vallis() -> void:
	_create_static_box("AresGround", Vector3(0, -0.12, -2), Vector3(34, 0.24, 30), SAND)

	# Low-cost terrain shapes create a broad Martian flood-plain silhouette.
	_create_static_box("RidgeLeft", Vector3(-11.0, 0.25, -4.0), Vector3(8.0, 0.55, 18.0), SAND_LIGHT)
	_create_static_box("RidgeRight", Vector3(12.0, 0.18, -6.0), Vector3(7.0, 0.42, 17.0), ROCK)

	# Twin Peaks: a recognizable horizon landmark from Pathfinder imagery.
	_create_visual_sphere("TwinPeakLeft", Vector3(-4.8, 2.2, -15.0), 2.8, Vector3(1.25, 0.80, 0.75), ROCK_DARK)
	_create_visual_sphere("TwinPeakRight", Vector3(-0.6, 2.0, -16.0), 2.5, Vector3(1.15, 0.72, 0.78), ROCK_DARK)

	# Scattered rocks keep the path readable while suggesting Ares Vallis.
	var rock_positions: Array[Vector3] = [
		Vector3(-6.0, 0.22, 1.0),
		Vector3(6.8, 0.20, 2.4),
		Vector3(-7.2, 0.18, -5.0),
		Vector3(7.4, 0.20, -7.0),
		Vector3(-2.0, 0.16, -8.2),
		Vector3(3.8, 0.17, -10.0)
	]

	for index in range(rock_positions.size()):
		var scale_factor: float = 0.55 + (float(index % 3) * 0.18)
		_create_visual_sphere(
			"Rock_%d" % index,
			rock_positions[index],
			0.55,
			Vector3(1.25, 0.72, 0.95) * scale_factor,
			ROCK
		)

	_pathfinder = PATHFINDER_STORY.instantiate()
	_pathfinder.position = Vector3(-1.8, 0.05, 1.4)
	_pathfinder.rotation_degrees = Vector3(0.0, 12.0, 0.0)
	_pathfinder.connect("story_active_changed", _on_story_active_changed)
	_pathfinder.connect("story_completed", _on_pathfinder_story_completed)
	add_child(_pathfinder)

	# Deflated airbag remnants remained visible around Pathfinder after landing.
	_create_visual_sphere(
		"DeflatedAirbagLeft",
		Vector3(-3.2, 0.08, 1.55),
		0.62,
		Vector3(1.45, 0.22, 1.05),
		AIRBAG
	)
	_create_visual_sphere(
		"DeflatedAirbagRight",
		Vector3(-0.4, 0.07, 1.80),
		0.58,
		Vector3(1.25, 0.20, 1.10),
		AIRBAG
	)
	_create_visual_sphere(
		"DeflatedAirbagRear",
		Vector3(-1.65, 0.06, 2.75),
		0.52,
		Vector3(1.55, 0.18, 0.92),
		AIRBAG
	)

	# Stylized rover tracks lead the player from Pathfinder toward Sojourner.
	for step in range(8):
		var t: float = float(step) / 7.0
		var z_pos: float = lerpf(0.2, -5.6, t)
		var x_center: float = lerpf(-0.8, 3.1, t)
		_create_visual_box(
			"TrackL_%d" % step,
			Vector3(x_center - 0.28, 0.015, z_pos),
			Vector3(0.10, 0.025, 0.46),
			TRACK
		)
		_create_visual_box(
			"TrackR_%d" % step,
			Vector3(x_center + 0.28, 0.015, z_pos),
			Vector3(0.10, 0.025, 0.46),
			TRACK
		)

	_sojourner = SOJOURNER_CHALLENGE.instantiate()
	_sojourner.position = Vector3(3.4, 0.02, -6.0)
	_sojourner.rotation_degrees = Vector3(0.0, -8.0, 0.0)
	_sojourner.connect("challenge_active_changed", _on_challenge_active_changed)
	_sojourner.connect("challenge_completed", _on_sojourner_completed)
	add_child(_sojourner)

	var platform := _sojourner.get_node_or_null("Platform") as MeshInstance3D
	if platform != null:
		platform.visible = false


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
	mesh.material = _make_material(color)
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	add_child(body)
	return body


func _create_visual_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = box_name
	mesh_instance.position = box_position

	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = _make_material(color)
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	return mesh_instance


func _create_visual_sphere(
	sphere_name: String,
	sphere_position: Vector3,
	radius: float,
	sphere_scale: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = sphere_name
	mesh_instance.position = sphere_position
	mesh_instance.scale = sphere_scale

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	mesh.material = _make_material(color)
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	return mesh_instance


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	return material
