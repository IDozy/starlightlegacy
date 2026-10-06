extends Node3D

@onready var player = $Player
@onready var dialogue_controller = $DialogueController
@onready var crosshair: Label = $HUD/Crosshair
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var inspection_info: Label = $HUD/InspectionInfo


func _ready() -> void:
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	player.connect("inspection_state_changed", _on_inspection_state_changed)
	dialogue_controller.connect("dialogue_active_changed", _on_dialogue_active_changed)
	dialogue_controller.connect("dialogue_finished", _on_dialogue_finished)

	interaction_prompt.visible = false
	inspection_info.visible = false


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


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id != "grandfather_intro":
		return

	if player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", "res://levels/nasa_memory_01/nasa_memory_01.tscn")
