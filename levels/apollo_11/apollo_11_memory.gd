extends Node3D
## Mar de la Tranquilidad (1969), reconstruccion educativa estilizada.
## Al completar el reto, queda el descenso y despega el ascenso simulado.

const EAGLE := preload("res://levels/apollo_11/apollo_11_lunar_module_greybox.tscn")
const SEPARATION_CONSOLE := preload("res://systems/gameplay/apollo_11_stage_console.gd")
const RETURN_PORTAL := preload("res://systems/navigation/scene_portal.tscn")
const DISCOVERY_ID := "apollo_11_descent_stage"

@onready var player: CharacterBody3D = $Player
@onready var objective_label: Label = $HUD/Objective
@onready var interaction_prompt: Label = $HUD/InteractionPrompt

var _eagle: Node3D = null
var _console: StaticBody3D = null
var _portal: StaticBody3D = null


func _ready() -> void:
	_create_environment()
	_create_surface()
	_create_eagle()
	_create_console()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	_update_progress()


func _create_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "TranquilityEnvironment"
	var background := Environment.new()
	background.background_mode = Environment.BG_COLOR
	background.background_color = Color(0.015, 0.020, 0.030)
	background.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	background.ambient_light_color = Color(0.39, 0.41, 0.45)
	background.ambient_light_energy = 0.56
	world.environment = background
	add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "LunarSun"
	sunlight.rotation_degrees = Vector3(-43, 27, 0)
	sunlight.light_color = Color(1.0, 0.96, 0.86)
	sunlight.light_energy = 1.10
	sunlight.shadow_enabled = true
	add_child(sunlight)


func _create_surface() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "SeaOfTranquilitySurface"
	floor_body.position = Vector3(0, -0.15, 0)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(28.0, 0.30, 28.0)
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color(0.38, 0.37, 0.34)
	soil.roughness = 0.97
	mesh.material = soil
	mesh_instance.mesh = mesh
	floor_body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)

	for i in range(9):
		var small_rock := MeshInstance3D.new()
		small_rock.name = "LunarRock_%02d" % i
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.25
		rock_mesh.height = 0.50
		rock_mesh.radial_segments = 7
		rock_mesh.rings = 4
		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = Color(0.35, 0.34, 0.32)
		rock_mat.roughness = 0.96
		rock_mesh.material = rock_mat
		small_rock.mesh = rock_mesh
		var angle := TAU * float(i) / 9.0
		var radius := 6.5 + 0.50 * float(i % 3)
		small_rock.position = Vector3(cos(angle) * radius, 0.08, sin(angle) * radius - 0.9)
		small_rock.scale = Vector3(1.50, 0.38, 0.90)
		add_child(small_rock)


func _create_eagle() -> void:
	_eagle = EAGLE.instantiate() as Node3D
	_eagle.name = "EagleLunarModule"
	_eagle.position = Vector3(1.05, 0.0, -4.25)
	_eagle.rotation_degrees.y = 18.0
	add_child(_eagle)


func _create_console() -> void:
	_console = SEPARATION_CONSOLE.new() as StaticBody3D
	_console.name = "Apollo11StageConsole"
	_console.position = Vector3(-1.65, 0.0, -1.70)
	add_child(_console)
	_console.call("connect_lander", _eagle)
	_console.connect("challenge_completed", _on_challenge_completed)


func _on_challenge_completed() -> void:
	_update_progress()


func _update_progress() -> void:
	if _has_discovery(DISCOVERY_ID):
		objective_label.text = "HISTORIA RECUPERADA · Etapa de descenso Apollo 11 · Regresa al taller."
		_unlock_return_portal()
	else:
		objective_label.text = "OBJETIVO · Identifica las dos etapas y simula la separación segura."


func _unlock_return_portal() -> void:
	if _portal != null:
		return
	_portal = RETURN_PORTAL.instantiate() as StaticBody3D
	_portal.name = "ReturnToWorkshop"
	_portal.position = Vector3(2.8, 0.68, 1.00)
	add_child(_portal)


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()
