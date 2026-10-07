extends StaticBody3D

@export var display_name: String = "Personaje"
@export var dialogue_id: String = "dialogue"
@export var dialogue_lines: PackedStringArray = []


func get_interaction_prompt() -> String:
	return "E · Hablar con %s" % display_name


func interact(player: Node) -> void:
	var controller := _resolve_dialogue_controller()
	if controller == null:
		return

	var lines: Array[String] = []
	for line in dialogue_lines:
		lines.append(line)

	controller.call("start_dialogue", dialogue_id, display_name, lines, player)


func _resolve_dialogue_controller() -> Node:
	var current_scene := get_tree().current_scene

	if current_scene != null:
		var direct_controller := current_scene.get_node_or_null("DialogueController")
		if direct_controller != null and direct_controller.has_method("start_dialogue"):
			return direct_controller

	var grouped_controller := get_tree().get_first_node_in_group("dialogue_controller")
	if grouped_controller != null and grouped_controller.has_method("start_dialogue"):
		return grouped_controller

	return null
