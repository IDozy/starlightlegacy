extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var required_discovery_id: String = ""
@export var locked_prompt: String = "Completa primero el paso anterior"
@export var completed_discovery_id: String = ""
@export var completed_prompt: String = "Recuerdo completado"


func get_interaction_prompt() -> String:
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
	if not surveyor_pending and not vanguard_pending and (not _requirement_met() or _is_completed()):
		return
	var main_node := player.get_parent()
	if main_node == null:
		return
	var controller := main_node.get_node_or_null("DialogueController") as DialogueController
	if controller == null:
		return
	var selected_dialogue := dialogue_id
	if surveyor_pending:
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
