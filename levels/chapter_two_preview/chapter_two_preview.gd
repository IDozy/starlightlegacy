extends Node3D
## Puente narrativo de Capítulo I a un posible Capítulo II.
## No se desbloquean aquí nuevos artefactos, fechas ni misiones inventadas.

const PORTAL := preload("res://systems/navigation/scene_portal.tscn")
const CASE := preload("res://systems/gameplay/sealed_archive_case.gd")
const FAIR_ID := "rescue_rover_science_fair_completed"

@onready var player: CharacterBody3D = $Player
@onready var objective_label: Label = $HUD/Objective
@onready var prompt_label: Label = $HUD/InteractionPrompt


func _ready() -> void:
	_create_room()
	_create_interactables()
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	prompt_label.visible = false
	objective_label.text = "CONTINUARÁ · Una caja sin identificar espera en el Archivo del abuelo."


func _create_room() -> void:
	var world := WorldEnvironment.new()
	world.name = "QuietArchiveEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.075, 0.105)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.33, 0.43, 0.55)
	env.ambient_light_energy = 0.72
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.name = "DuskLight"
	light.rotation_degrees = Vector3(-42, 20, 0)
	light.light_energy = 0.65
	add_child(light)
	var floor := StaticBody3D.new()
	floor.name = "ArchiveFloor"
	floor.position.y = -0.13
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(16.0, 0.26, 14.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.20, 0.25)
	mesh.material = mat
	mesh_instance.mesh = mesh
	floor.add_child(mesh_instance)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	shape_node.shape = shape
	floor.add_child(shape_node)
	add_child(floor)
	for index in range(3):
		var shadow := MeshInstance3D.new()
		shadow.name = "UnidentifiedSilhouette_%02d" % index
		var placeholder := BoxMesh.new()
		placeholder.size = Vector3(0.65 + 0.22 * float(index), 0.65 + 0.18 * float(index), 0.5)
		var shadow_mat := StandardMaterial3D.new()
		shadow_mat.albedo_color = Color(0.11, 0.14, 0.17)
		placeholder.material = shadow_mat
		shadow.mesh = placeholder
		shadow.position = Vector3(float(index - 1) * 1.5, 0.48, -5.0)
		add_child(shadow)


func _create_interactables() -> void:
	var box := CASE.new() as StaticBody3D
	box.name = "SealedArchiveCase"
	box.position = Vector3(0.0, 0.0, -2.5)
	add_child(box)
	var back := PORTAL.instantiate() as StaticBody3D
	back.name = "ReturnToScienceFair"
	back.position = Vector3(-3.2, 0.68, 0.8)
	back.set("prompt_text", "E · Volver a la feria del Capítulo I")
	back.set("target_scene", "res://levels/science_fair/science_fair.tscn")
	add_child(back)


func _on_interaction_prompt_changed(prompt: String) -> void:
	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()
