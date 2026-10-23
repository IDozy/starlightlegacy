extends Node3D
## Fin del Capítulo I, no del juego completo. Proyecto escolar separado de NASA.

const DEMO := preload("res://systems/gameplay/science_fair_demo_console.gd")
const ROVER := preload("res://systems/gameplay/rescue_rover_project.tscn")
const PORTAL := preload("res://systems/navigation/scene_portal.tscn")

@onready var player: CharacterBody3D = $Player
@onready var objective_label: Label = $HUD/Objective
@onready var interaction_prompt: Label = $HUD/InteractionPrompt

var _kiosk: StaticBody3D = null
var _portal_insight: StaticBody3D = null


func _ready() -> void:
	_build_environment()
	_build_exhibition()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	interaction_prompt.visible = false
	_update_objective()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "ScienceFairEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.19, 0.29, 0.40)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.79, 0.84)
	env.ambient_light_energy = 0.95
	world.environment = env
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "FairSun"
	sunlight.rotation_degrees = Vector3(-48, 19, 0)
	sunlight.light_energy = 0.88
	add_child(sunlight)
	var floor := StaticBody3D.new()
	floor.name = "FairFloor"
	floor.position = Vector3(0, -0.15, 0)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(22, 0.3, 20)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.45, 0.46, 0.44)
	box.material = floor_mat
	mesh.mesh = box
	floor.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	floor.add_child(collider)
	add_child(floor)
	# Expositores escolares y banner, geometría puramente temporal.
	_static_box("ExhibitionBackdrop", Vector3(0, 1.58, -6.6), Vector3(8.0, 3.16, 0.25), Color(0.15, 0.26, 0.35))
	_static_box("RoverExhibitionTable", Vector3(0.2, 0.29, -4.5), Vector3(2.9, 0.58, 2.1), Color(0.58, 0.39, 0.24))
	_static_box("SchoolScienceBanner", Vector3(0, 2.5, -6.35), Vector3(5.8, 0.44, 0.14), Color(0.92, 0.61, 0.19))


func _build_exhibition() -> void:
	var rover := ROVER.instantiate() as StaticBody3D
	rover.name = "SchoolRescueRover"
	rover.position = Vector3(0.2, 0.61, -4.5)
	add_child(rover)
	_kiosk = DEMO.new() as StaticBody3D
	_kiosk.name = "FinalPresentationKiosk"
	_kiosk.position = Vector3(-1.95, 0, -1.8)
	add_child(_kiosk)
	_kiosk.connect("exhibition_completed", _on_exhibition_completed)
	var back := PORTAL.instantiate() as StaticBody3D
	back.name = "ReturnToWorkshop"
	back.position = Vector3(-4.3, 0.71, 0.50)
	back.set("prompt_text", "E · Regresar al taller")
	back.set("target_scene", "res://scenes/main/main.tscn")
	add_child(back)
	# Esta actividad solo se ilumina al completar la feria; no cuenta para ganarla.
	_sync_optional_insight_portal()


func _on_exhibition_completed() -> void:
	_sync_optional_insight_portal()
	_update_objective()


func _sync_optional_insight_portal() -> void:
	if not _has_discovery("rescue_rover_science_fair_completed") or _portal_insight != null:
		return
	_portal_insight = PORTAL.instantiate() as StaticBody3D
	_portal_insight.name = "OptionalInSightPortal"
	_portal_insight.position = Vector3(3.65, 0.71, -1.85)
	_portal_insight.set("prompt_text", "E · Saber más: InSight y los sismos de Marte")
	_portal_insight.set("target_scene", "res://levels/insight/insight_memory.tscn")
	add_child(_portal_insight)


func _update_objective() -> void:
	if _has_discovery("rescue_rover_science_fair_completed"):
		objective_label.text = "CAPÍTULO I COMPLETADO · Continúa hacia una nueva pista o explora InSight."
	else:
		objective_label.text = "CAPÍTULO I · Demuestra seguridad, energía, entrega y exploración."


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _static_box(name: String, position: Vector3, dims: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dims
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	visual.mesh = mesh
	body.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = dims
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()
