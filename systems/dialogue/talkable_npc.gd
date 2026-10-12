extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var required_discovery_id: String = ""
@export var locked_prompt: String = "Completa primero el paso anterior"
@export var completed_discovery_id: String = ""
@export var completed_prompt: String = "Recuerdo completado"


func get_interaction_prompt() -> String:
	if _is_completed():
		return completed_prompt

	if not _requirement_met():
		return locked_prompt

	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	if player == null or not _requirement_met() or _is_completed():
		return

	var main_node := player.get_parent()
	if main_node == null:
		return

	var controller := main_node.get_node_or_null("DialogueController") as DialogueController
	if controller == null:
		return

	controller.start_dialogue_by_id(dialogue_id, display_name, player)


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
