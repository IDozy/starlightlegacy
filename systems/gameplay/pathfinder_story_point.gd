extends StaticBody3D

signal story_active_changed(active: bool)
signal story_completed

const DISCOVERY_ID := "mars_pathfinder_lander"

@onready var panel: Control = $StoryHUD/Panel
@onready var title_label: Label = $StoryHUD/Panel/Title
@onready var body_label: Label = $StoryHUD/Panel/Body

var _player: Node = null
var _active := false
var _completed := false


func _ready() -> void:
	panel.visible = false


func get_interaction_prompt() -> String:
	if _completed:
		return "E · Revisar Mars Pathfinder"

	return "E · Examinar Mars Pathfinder"


func interact(player: Node) -> void:
	if _active:
		return

	_player = player
	_active = true

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	panel.visible = true
	story_active_changed.emit(true)

	if not _completed:
		_completed = true
		_register_discovery()
		story_completed.emit()


func set_completed_state(completed: bool) -> void:
	_completed = completed


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("register_discovery"):
		return

	registry.call(
		"register_discovery",
		DISCOVERY_ID,
		"Mars Pathfinder",
		"Hardware en Marte",
		"Pathfinder aterrizó en Ares Vallis el 4 de julio de 1997 usando paracaídas, retrocohetes y airbags. Tras detenerse, abrió sus pétalos, desplegó sus sistemas y liberó al rover Sojourner."
	)


func _close_panel() -> void:
	_active = false
	panel.visible = false

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)

	story_active_changed.emit(false)
