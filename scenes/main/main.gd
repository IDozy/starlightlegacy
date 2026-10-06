extends Node3D

@onready var player = $Player
@onready var crosshair: Label = $HUD/Crosshair
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var inspection_info: Label = $HUD/InspectionInfo


func _ready() -> void:
	player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	player.connect("inspection_state_changed", _on_inspection_state_changed)

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
