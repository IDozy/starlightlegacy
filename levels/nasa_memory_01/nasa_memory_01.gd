extends Node3D

const SCENE_PORTAL := preload("res://systems/navigation/scene_portal.tscn")
const ORIENTATION_CHALLENGE := preload("res://systems/gameplay/orientation_challenge.tscn")
const SOJOURNER_CHALLENGE := preload("res://systems/gameplay/sojourner_scan_challenge.tscn")

const ORIENTATION_DISCOVERY_ID := "gyroscopic_orientation"
const SOJOURNER_DISCOVERY_ID := "sojourner_apxs"

const FLOOR_COLOR := Color(0.14, 0.16, 0.18)
const WALL_COLOR := Color(0.62, 0.64, 0.62)
const CONSOLE_COLOR := Color(0.19, 0.24, 0.25)
const PANEL_COLOR := Color(0.07, 0.10, 0.11)
const ACCENT_COLOR := Color(0.88, 0.55, 0.16)

@onready var player = $Player
@onready var crosshair: Label = $HUD/Crosshair
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var objective_label: Label = $HUD/Objective
@onready var narration_label: Label = $HUD/Narration

var _orientation_challenge: Node = null
var _sojourner_challenge: Node = null
var _return_portal: Node = null


func _ready() -> void:
	_build_environment()
	_build_lab()

	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	narration_label.visible = false

	var orientation_done := _has_discovery(ORIENTATION_DISCOVERY_ID)
	var sojourner_done := _has_discovery(SOJOURNER_DISCOVERY_ID)

	_orientation_challenge.call("set_completed_state", orientation_done)
	_sojourner_challenge.call("set_completed_state", sojourner_done)

	_update_memory_progress(false)


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()


func _on_challenge_active_changed(active: bool) -> void:
	crosshair.visible = not active

	if active:
		interaction_prompt.visible = false


func _on_orientation_challenge_completed() -> void:
	narration_label.text = "Abuelo: Muy bien. Ahora deja la simulación y mira aquella pequeña máquina. Esa sí quedó en Marte."
	narration_label.visible = true
	_update_memory_progress(false)


func _on_sojourner_challenge_completed() -> void:
	narration_label.text = "Abuelo: Sojourner era pequeño, pero demostró que un rover podía recorrer otro planeta y acercar instrumentos directamente a sus rocas."
	narration_label.visible = true
	_update_memory_progress(true)


func _update_memory_progress(show_completion_narration: bool) -> void:
	var orientation_done := _has_discovery(ORIENTATION_DISCOVERY_ID)
	var sojourner_done := _has_discovery(SOJOURNER_DISCOVERY_ID)

	if not orientation_done:
		objective_label.text = "OBJETIVO 1/2 · Calibra el sistema central de orientación."
		return

	if not sojourner_done:
		objective_label.text = "OBJETIVO 2/2 · Opera Sojourner y analiza la roca con su APXS."
		return

	_unlock_return_portal()

	if show_completion_narration:
		narration_label.text = "Abuelo: La misión terminó hace décadas, pero Sojourner sigue en Ares Vallis. Lo que aprendimos con él abrió camino a los rovers que vinieron después."
		narration_label.visible = true


func _unlock_return_portal() -> void:
	if _return_portal == null:
		_return_portal = SCENE_PORTAL.instantiate()
		_return_portal.position = Vector3(0.0, 0.65, 4.6)
		add_child(_return_portal)

	objective_label.text = "RECUERDO COMPLETADO · 2 conocimientos registrados · Regresa al taller."


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("has_discovery"):
		return false

	return bool(registry.call("has_discovery", discovery_id))


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

	_orientation_challenge = ORIENTATION_CHALLENGE.instantiate()
	_orientation_challenge.position = Vector3(0.0, 0.72, -3.62)
	_orientation_challenge.connect("challenge_active_changed", _on_challenge_active_changed)
	_orientation_challenge.connect("challenge_completed", _on_orientation_challenge_completed)
	add_child(_orientation_challenge)

	_sojourner_challenge = SOJOURNER_CHALLENGE.instantiate()
	_sojourner_challenge.position = Vector3(4.35, 0.14, -1.25)
	_sojourner_challenge.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	_sojourner_challenge.connect("challenge_active_changed", _on_challenge_active_changed)
	_sojourner_challenge.connect("challenge_completed", _on_sojourner_challenge_completed)
	add_child(_sojourner_challenge)


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
