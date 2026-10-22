extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var required_discovery_id: String = ""
@export var locked_prompt: String = "Completa primero el paso anterior"
@export var completed_discovery_id: String = ""
@export var completed_prompt: String = "Recuerdo completado"


func get_interaction_prompt() -> String:
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_slip_problem"):
		if _has_discovery("rescue_rover_slip_guard_upgrade"):
			return "Abuelo · La historia de Spirit está completada"
		if _has_discovery("spirit"):
			return "Abuelo · Aplica lo aprendido de Spirit"
		return "E · Hablar con Abuelo sobre Spirit"
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_science_verification_problem"):
		if _has_discovery("viking_1"):
			return "Abuelo · Aplica lo aprendido de Viking 1"
		return "E · Hablar con Abuelo sobre Viking 1"
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_traction_problem"):
		if _has_discovery("apollo_15_lrv"):
			return "Abuelo · Aplica lo aprendido de Apollo 15"
		return "E · Hablar con Abuelo sobre Apollo 15"
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_module_separation_problem"):
		if _has_discovery("apollo_11_descent_stage"):
			return "Abuelo · Aplica lo aprendido de Apollo 11"
		return "E · Hablar con Abuelo sobre Apollo 11"
	# Surveyor solo se ofrece tras aplicar la mejora solar de Vanguard.
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_orientation_problem"):
		if _has_discovery("surveyor_1"):
			return "Abuelo · Aplica lo aprendido sobre orientación"
		return "E · Hablar con Abuelo sobre Surveyor 1"
	# El mismo abuelo puede contar otro recuerdo despues de Pathfinder.
	# No crear NPC ni controlador de dialogos duplicados.
	if dialogue_id == "grandfather_intro" and _has_discovery("rescue_rover_energy_problem"):
		if _has_discovery("vanguard_1"):
			return "Abuelo · Aplica lo aprendido sobre energia"
		return "E · Hablar con Abuelo sobre Vanguard 1"

	if _is_completed():
		return completed_prompt

	if not _requirement_met():
		return locked_prompt

	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	if player == null:
		return
	var spirit_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_slip_problem")
		and not _has_discovery("spirit")
	)
	var viking_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_science_verification_problem")
		and not _has_discovery("viking_1")
	)
	var apollo15_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_traction_problem")
		and not _has_discovery("apollo_15_lrv")
	)
	var apollo_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_module_separation_problem")
		and not _has_discovery("apollo_11_descent_stage")
	)
	var surveyor_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_orientation_problem")
		and not _has_discovery("surveyor_1")
	)
	var vanguard_pending := (
		dialogue_id == "grandfather_intro"
		and _has_discovery("rescue_rover_energy_problem")
		and not _has_discovery("vanguard_1")
	)
	if not spirit_pending and not viking_pending and not apollo15_pending and not apollo_pending and not surveyor_pending and not vanguard_pending and (not _requirement_met() or _is_completed()):
		return
	var main_node := player.get_parent()
	if main_node == null:
		return
	var controller := main_node.get_node_or_null("DialogueController") as DialogueController
	if controller == null:
		return
	var selected_dialogue := dialogue_id
	if spirit_pending:
		selected_dialogue = "grandfather_spirit"
	elif viking_pending:
		selected_dialogue = "grandfather_viking_1"
	elif apollo15_pending:
		selected_dialogue = "grandfather_apollo_15"
	elif apollo_pending:
		selected_dialogue = "grandfather_apollo_11"
	elif surveyor_pending:
		selected_dialogue = "grandfather_surveyor_1"
	elif vanguard_pending:
		selected_dialogue = "grandfather_vanguard_1"
	controller.start_dialogue_by_id(selected_dialogue, display_name, player)


func _requirement_met() -> bool:
	if required_discovery_id.strip_edges().is_empty():
		return true

	return _has_discovery(required_discovery_id)


func _is_completed() -> bool:
	if completed_discovery_id.strip_edges().is_empty():
		return false

	return _has_discovery(completed_discovery_id)


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("has_discovery"):
		return false

	return bool(registry.call("has_discovery", discovery_id))
