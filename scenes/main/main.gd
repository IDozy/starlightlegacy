extends Node3D

const PROBLEM_ID := "rescue_rover_impact_problem"
const PATHFINDER_ID := "mars_pathfinder_lander"
const SOJOURNER_ID := "sojourner_apxs"
const UPGRADE_ID := "rescue_rover_airbag_upgrade"

@onready var player = $Player
@onready var dialogue_controller = $DialogueController
@onready var rescue_rover = $Workshop/RescueRoverProject
@onready var crosshair: Label = $HUD/Crosshair
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var inspection_info: Label = $HUD/InspectionInfo
@onready var project_objective: Label = $HUD/ProjectObjective


func _ready() -> void:
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	player.connect("inspection_state_changed", _on_inspection_state_changed)
	dialogue_controller.connect("dialogue_active_changed", _on_dialogue_active_changed)
	dialogue_controller.connect("dialogue_finished", _on_dialogue_finished)
	rescue_rover.connect("project_active_changed", _on_project_active_changed)
	rescue_rover.connect("project_state_changed", _update_project_objective)

	interaction_prompt.visible = false
	inspection_info.visible = false
	_update_project_objective()


func _on_interaction_prompt_changed(prompt: String) -> void:
	interaction_prompt.text = prompt
	interaction_prompt.visible = not prompt.is_empty()


func _on_inspection_state_changed(
	is_inspecting: bool,
	title: String,
	description: String
) -> void:
	crosshair.visible = not is_inspecting
	inspection_info.visible = is_inspecting

	if is_inspecting:
		inspection_info.text = "%s\n%s\n\nMouse · Rotar    E / Esc · Volver" % [title, description]
	else:
		inspection_info.text = ""


func _on_dialogue_active_changed(active: bool) -> void:
	crosshair.visible = not active
	if active:
		interaction_prompt.visible = false


func _on_project_active_changed(active: bool) -> void:
	crosshair.visible = not active
	if active:
		interaction_prompt.visible = false


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id != "grandfather_intro":
		return

	if player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", "res://levels/ares_vallis/ares_vallis.tscn")


func _update_project_objective() -> void:
	if _has_discovery(UPGRADE_ID):
		project_objective.text = "PROYECTO · IMPACTO RESUELTO · Vehículo mejorado."
		return

	if _has_discovery(PATHFINDER_ID) and _has_discovery(SOJOURNER_ID):
		project_objective.text = "PROYECTO · Aplica al vehículo lo aprendido en Ares Vallis."
		return

	if _has_discovery(PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el Abuelo sobre el fallo de impacto."
		return

	project_objective.text = "PROYECTO · Prueba el Vehículo Explorador de Rescate."


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("has_discovery"):
		return false

	return bool(registry.call("has_discovery", discovery_id))
