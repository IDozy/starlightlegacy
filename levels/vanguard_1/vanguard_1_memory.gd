extends Node3D
## Recuerdo historico jugable: Vanguard 1, 1958.
## Entorno educativo estilizado; satelite expuesto a escala x4 para lectura.

const VANGUARD_MODEL := preload("res://levels/vanguard_1/vanguard_1_greybox.tscn")
const ENERGY_STATION := preload("res://systems/gameplay/vanguard_energy_station.gd")
const RETURN_PORTAL := preload("res://systems/navigation/scene_portal.tscn")
const DISCOVERY_ID := "vanguard_1"

@onready var player: CharacterBody3D = $Player
@onready var objective_label: Label = $HUD/Objective
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var crosshair: Label = $HUD/Crosshair

var _station: StaticBody3D = null
var _return_portal: StaticBody3D = null


func _ready() -> void:
	_build_environment()
	_build_platform()
	_build_vanguard_exhibit()
	_build_energy_station()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	_update_progress()


func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "OrbitEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.028, 0.058)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.46, 0.57, 0.75)
	environment.ambient_light_energy = 0.85
	environment_node.environment = environment
	add_child(environment_node)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-52, 32, 0)
	sunlight.light_color = Color(1.0, 0.89, 0.69)
	sunlight.light_energy = 1.25
	sunlight.shadow_enabled = true
	add_child(sunlight)

	# Esfera de fondo escenografica, no una reproduccion orbital a escala.
	var earth := MeshInstance3D.new()
	earth.name = "StylizedEarthBackdrop"
	var earth_mesh := SphereMesh.new()
	earth_mesh.radius = 7.5
	earth_mesh.height = 15.0
	earth_mesh.radial_segments = 28
	earth_mesh.rings = 14
	var earth_mat := StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.12, 0.30, 0.50)
	earth_mat.roughness = 0.88
	earth_mesh.material = earth_mat
	earth.mesh = earth_mesh
	earth.position = Vector3(1.0, 4.0, -26.0)
	add_child(earth)


func _build_platform() -> void:
	var platform := StaticBody3D.new()
	platform.name = "EducationalObservationPlatform"
	platform.position = Vector3(0.0, -0.18, 0.0)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(12.0, 0.36, 10.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.19, 0.26, 0.33)
	mat.metallic = 0.18
	mesh.material = mat
	mesh_instance.mesh = mesh
	platform.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	platform.add_child(collider)
	add_child(platform)


func _build_vanguard_exhibit() -> void:
	var satellite := VANGUARD_MODEL.instantiate() as Node3D
	satellite.name = "Vanguard1Display"
	satellite.position = Vector3(0.0, 2.3, -5.1)
	# El artefacto historico tiene ~16.4 cm de diametro.
	# Aqui se amplia x4 para inspeccion; NO afirmar que ese es su tamano.
	satellite.scale = Vector3.ONE * 4.0
	add_child(satellite)

	var pedestal := MeshInstance3D.new()
	pedestal.name = "EnlargedDisplaySupport"
	var base := CylinderMesh.new()
	base.top_radius = 0.44
	base.bottom_radius = 0.58
	base.height = 0.23
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.30, 0.38, 0.44)
	base.material = material
	pedestal.mesh = base
	pedestal.position = Vector3(0.0, 0.12, -5.1)
	add_child(pedestal)


func _build_energy_station() -> void:
	_station = ENERGY_STATION.new() as StaticBody3D
	_station.name = "VanguardEnergyStation"
	_station.position = Vector3(0.0, 0.0, -2.25)
	add_child(_station)
	_station.connect("challenge_completed", _on_challenge_completed)


func _on_challenge_completed() -> void:
	_update_progress()


func _update_progress() -> void:
	if _has_discovery(DISCOVERY_ID):
		objective_label.text = "HISTORIA RECUPERADA · Vanguard 1 · Regresa al taller."
		_unlock_return_portal()
	else:
		objective_label.text = "OBJETIVO · Usa la consola. Compara batería y energía solar."


func _unlock_return_portal() -> void:
	if _return_portal != null:
		return
	_return_portal = RETURN_PORTAL.instantiate() as StaticBody3D
	_return_portal.name = "ReturnToWorkshop"
	_return_portal.position = Vector3(2.3, 0.70, 0.2)
	add_child(_return_portal)


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _on_interaction_prompt(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()
