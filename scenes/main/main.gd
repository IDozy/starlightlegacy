extends Node3D

const PROBLEM_ID := "rescue_rover_impact_problem"
const PATHFINDER_ID := "mars_pathfinder_lander"
const SOJOURNER_ID := "sojourner_apxs"
const UPGRADE_ID := "rescue_rover_airbag_upgrade"
const ENERGY_PROBLEM_ID := "rescue_rover_energy_problem"
const VANGUARD_ID := "vanguard_1"
const SOLAR_UPGRADE_ID := "rescue_rover_solar_upgrade"
const ORIENTATION_PROBLEM_ID := "rescue_rover_orientation_problem"
const SURVEYOR_ID := "surveyor_1"
const ORIENTATION_UPGRADE_ID := "rescue_rover_orientation_upgrade"
const MODULE_PROBLEM_ID := "rescue_rover_module_separation_problem"
const APOLLO_ID := "apollo_11_descent_stage"
const MODULE_UPGRADE_ID := "rescue_rover_modular_release_upgrade"
const TRACTION_PROBLEM_ID := "rescue_rover_traction_problem"
const APOLLO15_ID := "apollo_15_lrv"
const TRACTION_UPGRADE_ID := "rescue_rover_traction_upgrade"
const SCIENCE_PROBLEM_ID := "rescue_rover_science_verification_problem"
const VIKING_ID := "viking_1"
const SCIENCE_UPGRADE_ID := "rescue_rover_science_verification_upgrade"
const SLIP_PROBLEM_ID := "rescue_rover_slip_problem"
const SPIRIT_ID := "spirit"
const SLIP_UPGRADE_ID := "rescue_rover_slip_guard_upgrade"
const LOW_LIGHT_PROBLEM_ID := "rescue_rover_low_light_problem"
const OPPORTUNITY_ID := "opportunity"
const POWER_BUDGET_UPGRADE_ID := "rescue_rover_power_budget_upgrade"
const DELIVERY_PROBLEM_ID := "rescue_rover_delivery_problem"
const SKY_CRANE_ID := "perseverance_sky_crane"
const DELIVERY_UPGRADE_ID := "rescue_rover_touchdown_release_upgrade"
const AERIAL_PROBLEM_ID := "rescue_rover_aerial_scout_problem"
const INGENUITY_ID := "ingenuity"
const AERIAL_UPGRADE_ID := "rescue_rover_aerial_scout_upgrade"
const SCIENCE_FAIR := preload("res://systems/navigation/scene_portal.tscn")

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
	rescue_rover.connect("project_state_changed", _on_project_progress_updated)

	interaction_prompt.visible = false
	inspection_info.visible = false
	_on_project_progress_updated()


func _on_project_progress_updated() -> void:
	_update_project_objective()
	_sync_fair_entrance()


func _sync_fair_entrance() -> void:
	# La feria se desbloquea al instalar el acompañante de Ingenuity.
	# El controlador de feria además comprueba TODOS los módulos al terminar.
	if not _has_discovery(AERIAL_UPGRADE_ID):
		return
	if get_node_or_null("ScienceFairEntrance") != null:
		return
	var portal := SCIENCE_FAIR.instantiate() as StaticBody3D
	portal.name = "ScienceFairEntrance"
	portal.position = Vector3(2.2, 0.9, 5.8)
	portal.set("prompt_text", "E · Presentar el rover en la feria de ciencias")
	portal.set("target_scene", "res://levels/science_fair/science_fair.tscn")
	add_child(portal)


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
	var target_scene := ""
	match dialogue_id:
		"grandfather_intro":
			target_scene = "res://levels/ares_vallis/ares_vallis.tscn"
		"grandfather_vanguard_1":
			target_scene = "res://levels/vanguard_1/vanguard_1_memory.tscn"
		"grandfather_surveyor_1":
			target_scene = "res://levels/surveyor_1/surveyor_1_memory.tscn"
		"grandfather_apollo_11":
			target_scene = "res://levels/apollo_11/apollo_11_memory.tscn"
		"grandfather_apollo_15":
			target_scene = "res://levels/apollo_15/apollo_15_memory.tscn"
		"grandfather_viking_1":
			target_scene = "res://levels/viking_1/viking_1_memory.tscn"
		"grandfather_spirit":
			target_scene = "res://levels/spirit/spirit_memory.tscn"
		"grandfather_opportunity":
			target_scene = "res://levels/opportunity/opportunity_memory.tscn"
		"grandfather_sky_crane":
			target_scene = "res://levels/perseverance_sky_crane/sky_crane_memory.tscn"
		"grandfather_ingenuity":
			target_scene = "res://levels/ingenuity/ingenuity_memory.tscn"
		_:
			return
	if player.has_method("set_control_locked"):
		player.call("set_control_locked", true)
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", target_scene)


func _update_project_objective() -> void:
	if _has_discovery("rescue_rover_science_fair_completed"):
		project_objective.text = "PROYECTO · Feria terminada. Revisa tu Archivo NASA o vuelve a presentarlo."
		return
	if _has_discovery(AERIAL_UPGRADE_ID):
		project_objective.text = "PROYECTO · Vehículo completo. Usa el portal de la feria de ciencias."
		return
	if _has_discovery(INGENUITY_ID):
		project_objective.text = "PROYECTO · Añade el explorador auxiliar inspirado en Ingenuity."
		return
	if _has_discovery(AERIAL_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre Ingenuity y el vuelo en Marte."
		return
	if _has_discovery(DELIVERY_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba el reconocimiento de una ruta oculta."
		return
	if _has_discovery(SKY_CRANE_ID):
		project_objective.text = "PROYECTO · Instala el protocolo de entrega aprendido de Sky Crane."
		return
	if _has_discovery(DELIVERY_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre Perseverance y Sky Crane."
		return
	if _has_discovery(POWER_BUDGET_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba la entrega del rover desde su soporte."
		return
	if _has_discovery(OPPORTUNITY_ID):
		project_objective.text = "PROYECTO · Aplica el modo de ahorro aprendido de Opportunity."
		return
	if _has_discovery(LOW_LIGHT_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre Opportunity y 2018."
		return
	if _has_discovery(SLIP_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba la autonomía con poca luz."
		return
	if _has_discovery(SPIRIT_ID):
		project_objective.text = "PROYECTO · Aplica el control de deslizamiento aprendido de Spirit."
		return
	if _has_discovery(SLIP_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre Spirit y Troy."
		return
	if _has_discovery(SCIENCE_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba el vehículo sobre polvo suelto."
		return
	if _has_discovery(VIKING_ID):
		project_objective.text = "PROYECTO · Aplica la verificación científica aprendida de Viking 1."
		return
	if _has_discovery(SCIENCE_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre Viking 1 y los resultados."
		return
	if _has_discovery(TRACTION_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba la interpretación de un sensor científico."
		return
	if _has_discovery(APOLLO15_ID):
		project_objective.text = "PROYECTO · Aplica lo aprendido de las ruedas del LRV de Apollo 15."
		return
	if _has_discovery(TRACTION_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo sobre tracción y movilidad lunar."
		return
	if _has_discovery(MODULE_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba el vehículo sobre suelo suelto."
		return
	if _has_discovery(APOLLO_ID):
		project_objective.text = "PROYECTO · Aplica la separación modular aprendida del Eagle."
		return
	if _has_discovery(MODULE_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el Abuelo sobre la etapa de descenso de Apollo 11."
		return
	if _has_discovery(ORIENTATION_UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba el acoplamiento de la base auxiliar."
		return
	if _has_discovery(SURVEYOR_ID):
		project_objective.text = "PROYECTO · Aplica la orientación de Surveyor 1 al vehículo."
		return
	if _has_discovery(ORIENTATION_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el Abuelo sobre orientación de panel y cámara."
		return
	if _has_discovery(SOLAR_UPGRADE_ID):
		project_objective.text = "PROYECTO · Comprueba cómo se orientan el panel y la cámara."
		return
	if _has_discovery(VANGUARD_ID):
		project_objective.text = "PROYECTO · Aplica la energia solar de Vanguard 1 al vehículo."
		return
	if _has_discovery(ENERGY_PROBLEM_ID):
		project_objective.text = "PROYECTO · Habla con el abuelo: la batería se agota."
		return
	if _has_discovery(UPGRADE_ID):
		project_objective.text = "PROYECTO · Prueba ahora la autonomía del vehículo."
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
