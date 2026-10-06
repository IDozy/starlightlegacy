extends StaticBody3D

@export var display_name: String = "Objeto"
@export_multiline var description: String = "Un objeto que puede examinarse."
@export var discovery_id: String = ""
@export var discovery_category: String = "Hardware"
@export_multiline var discovery_summary: String = ""

@onready var visual: Node3D = $Visual


func get_interaction_prompt() -> String:
	return "E · Examinar %s" % display_name


func interact(player: Node) -> void:
	if player.has_method("start_inspection"):
		player.call("start_inspection", self)


func create_inspection_visual() -> Node3D:
	return visual.duplicate()


func set_world_visible(is_visible: bool) -> void:
	visual.visible = is_visible


func get_inspection_title() -> String:
	return display_name


func get_inspection_description() -> String:
	return description


func get_discovery_data() -> Dictionary:
	if discovery_id.strip_edges().is_empty():
		return {}

	var summary := discovery_summary.strip_edges()
	if summary.is_empty():
		summary = description

	return {
		"id": discovery_id,
		"title": display_name,
		"category": discovery_category,
		"summary": summary
	}
