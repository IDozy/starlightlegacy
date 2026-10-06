extends StaticBody3D

@export var prompt_text: String = "E · Continuar"
@export_file("*.tscn") var target_scene: String


func get_interaction_prompt() -> String:
	return prompt_text


func interact(player: Node) -> void:
	if target_scene.is_empty():
		return

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", target_scene)
