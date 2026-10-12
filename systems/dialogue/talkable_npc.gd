extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"


func get_interaction_prompt() -> String:
	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	if player == null:
		return

	var main_node := player.get_parent()
	if main_node == null:
		return

	var controller := main_node.get_node_or_null("DialogueController") as DialogueController
	if controller == null:
		return

	controller.start_dialogue_by_id(dialogue_id, display_name, player)
