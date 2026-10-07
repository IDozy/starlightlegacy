extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var dialogue_lines: PackedStringArray = []


func get_interaction_prompt() -> String:
	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	if player == null:
		return

	var main_node := player.get_parent()
	if main_node == null:
		return

	_debug(main_node, "2 · Abuelo.interact() ejecutado")

	var controller := main_node.get_node_or_null("DialogueController") as DialogueController
	if controller == null:
		_debug(main_node, "ERROR · DialogueController no encontrado")
		return

	_debug(main_node, "3 · DialogueController encontrado")
	controller.start_dialogue_by_id(dialogue_id, display_name, player)


func _debug(main_node: Node, message: String) -> void:
	if main_node != null and main_node.has_method("set_interaction_debug"):
		main_node.call("set_interaction_debug", message)
