extends Node3D
## Surveyor 1, 1966. La superficie lunar es una reconstruccion educativa.
## La consola de la Tierra representa comandos remotos; no telemetria real.

const LANDER := preload("res://levels/surveyor_1/surveyor_1_greybox.tscn")
const COMMAND_CONSOLE := preload("res://systems/gameplay/surveyor_command_console.gd")
const RETURN_PORTAL := preload("res://systems/navigation/scene_portal.tscn")
const DISCOVERY_ID := "surveyor_1"

@onready var player: CharacterBody3D = $Player
@onready var objective_label: Label = $HUD/Objective
@onready var interaction_prompt: Label = $HUD/InteractionPrompt

var _lander: Node3D = null
var _console: StaticBody3D = null
var _portal: StaticBody3D = null


func _ready() -> void:
	_build_lunar_environment()
	_build_lunar_floor()
	_build_lander()
	_build_console()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	_update_progress()


func _build_lunar_environment() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "MoonEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.019, 0.022, 0.031)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.46, 0.50)
	environment.ambient_light_energy = 0.54
	environment_node.environment = environment
	add_child(environment_node)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "LunarSun"
	sunlight.rotation_degrees = Vector3(-47.0, 24.0, 0.0)
	sunlight.light_color = Color(0.98, 0.95, 0.87)
	sunlight.light_energy = 1.05
	sunlight.shadow_enabled = true
	add_child(sunlight)


func _build_lunar_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "LunarSurface"
	floor_body.position = Vector3(0, -0.15, 0)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(28.0, 0.30, 27.0)
	var lunar_soil := StandardMaterial3D.new()
	lunar_soil.albedo_color = Color(0.38, 0.37, 0.35)
	lunar_soil.roughness = 0.97
	mesh.material = lunar_soil
	mesh_instance.mesh = mesh
	floor_body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)

	# Rocas escenograficas para sugerir Oceanus Procellarum.
	# Su silueta no representa posiciones medidas por la NASA.
	for i in range(10):
		var stone := MeshInstance3D.new()
		stone.name = "EducationalMoonRock_%02d" % i
		var rock := SphereMesh.new()
		rock.radius = 0.35
		rock.height = 0.70
		rock.radial_segments = 7
		rock.rings = 4
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.32 + 0.012 * float(i % 3), 0.32, 0.31)
		mat.roughness = 0.97
		rock.material = mat
		stone.mesh = rock
		var angle := float(i) * TAU / 10.0
		var radius: float = 6.6 + float(i % 3) * 1.2
		stone.position = Vector3(cos(angle) * radius, 0.14, sin(angle) * radius - 0.8)
		stone.scale = Vector3(1.2 + 0.3 * float(i % 3), 0.45, 0.95)
		add_child(stone)


func _build_lander() -> void:
	_lander = LANDER.instantiate() as Node3D
	_lander.name = "Surveyor1Lander"
	_lander.position = Vector3(1.10, 0.0, -4.25)
	_lander.rotation_degrees.y = -22.0
	add_child(_lander)

	# No mezclar el terreno ficticio con la nave: el aterrizador es una
	# instancia independiente y mantiene su modelado reemplazable.
	var focus := MeshInstance3D.new()
	focus.name = "CameraTargetRock"
	var shape := SphereMesh.new()
	shape.radius = 0.38
	shape.height = 0.75
	shape.radial_segments = 8
	shape.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.29, 0.28, 0.27)
	mat.roughness = 0.97
	shape.material = mat
	focus.mesh = shape
	focus.scale = Vector3(1.3, 0.72, 1.0)
	focus.position = Vector3(-1.7, 0.20, -5.9)
	add_child(focus)


func _build_console() -> void:
	_console = COMMAND_CONSOLE.new() as StaticBody3D
	_console.name = "SurveyorCommandConsole"
	_console.position = Vector3(-1.5, 0.0, -1.75)
	add_child(_console)
	_console.call("connect_lander", _lander)
	_console.connect("challenge_completed", _on_challenge_completed)


func _on_challenge_completed() -> void:
	_update_progress()


func _update_progress() -> void:
	if _has_discovery(DISCOVERY_ID):
		objective_label.text = "HISTORIA RECUPERADA · Surveyor 1 · Regresa al taller."
		_unlock_return_portal()
	else:
		objective_label.text = "OBJETIVO · Envía órdenes al panel solar, cámara y transmisor."


func _unlock_return_portal() -> void:
	if _portal != null:
		return
	_portal = RETURN_PORTAL.instantiate() as StaticBody3D
	_portal.name = "ReturnToWorkshop"
	_portal.position = Vector3(2.7, 0.68, 1.0)
	add_child(_portal)


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()
