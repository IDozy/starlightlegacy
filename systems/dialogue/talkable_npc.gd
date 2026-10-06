extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var dialogue_lines: PackedStringArray = []


func get_interaction_prompt() -> String:
	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	var controller := get_tree().get_first_node_in_group("dialogue_controller")
	if controller == null or not controller.has_method("start_dialogue"):
		return

	var lines: Array[String] = []
	for line in dialogue_lines:
		lines.append(line)

	controller.call("start_dialogue", dialogue_id, display_name, lines, player)
