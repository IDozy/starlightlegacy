class_name DialogueController
extends Node

signal dialogue_active_changed(active: bool)
signal dialogue_finished(dialogue_id: String)

@export var player_path: NodePath
@export var dialogue_panel_path: NodePath
@export var speaker_label_path: NodePath
@export var text_label_path: NodePath
@export var hint_label_path: NodePath

@onready var player = get_node(player_path)
@onready var _dialogue_panel := get_node(dialogue_panel_path) as Control
@onready var speaker_label := get_node(speaker_label_path) as Label
@onready var text_label := get_node(text_label_path) as Label
@onready var hint_label := get_node(hint_label_path) as Label

var _dialogue_id := ""
var _speaker := ""
var _lines: PackedStringArray = PackedStringArray()
var _line_index := 0
var _active := false
var _started_frame := -1


func _ready() -> void:
	add_to_group("dialogue_controller")
	_dialogue_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if Engine.get_process_frames() == _started_frame:
		return

	var advance := false

	if event is InputEventKey and event.pressed and not event.echo:
		advance = event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE
	elif event is InputEventMouseButton and event.pressed:
		advance = event.button_index == MOUSE_BUTTON_LEFT

	if advance:
		advance_dialogue()
		get_viewport().set_input_as_handled()


func start_dialogue_by_id(
	dialogue_id: String,
	speaker: String,
	source_player: Node = null
) -> bool:
	var lines := _get_dialogue_lines(dialogue_id)
	if lines.is_empty():
		_set_debug("ERROR · diálogo sin líneas: %s" % dialogue_id)
		return false

	return _start_dialogue(dialogue_id, speaker, lines, source_player)


func _start_dialogue(
	dialogue_id: String,
	speaker: String,
	lines: PackedStringArray,
	source_player: Node = null
) -> bool:
	if _active:
		_set_debug("ERROR · DialogueController ya estaba activo")
		return false

	if source_player != null:
		player = source_player

	_dialogue_id = dialogue_id
	_speaker = speaker
	_lines = lines.duplicate()
	_line_index = 0
	_active = true
	_started_frame = Engine.get_process_frames()

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	_dialogue_panel.visible = true
	hint_label.text = "E / Enter / clic · Continuar"
	dialogue_active_changed.emit(true)
	_show_current_line()
	_set_debug("5 · DIÁLOGO ACTIVO · %d líneas" % _lines.size())
	return true


func advance_dialogue() -> void:
	if not _active:
		return

	_line_index += 1

	if _line_index >= _lines.size():
		_finish_dialogue()
		return

	_show_current_line()


func is_dialogue_active() -> bool:
	return _active


func _get_dialogue_lines(dialogue_id: String) -> PackedStringArray:
	match dialogue_id:
		"grandfather_intro":
			return PackedStringArray([
				"Vaya... no veía uno de esos desde hace muchos años.",
				"Cuando era joven, piezas como esa podían decidir si una misión encontraba su camino... o se perdía allá arriba.",
				"¿Quieren saber para qué servía realmente?",
				"Entonces tendré que contarles dónde empezó todo."
			])
		_:
			return PackedStringArray()


func _show_current_line() -> void:
	speaker_label.text = _speaker
	text_label.text = _lines[_line_index]


func _finish_dialogue() -> void:
	var finished_id := _dialogue_id

	_active = false
	_dialogue_panel.visible = false
	_lines.clear()
	_line_index = 0
	_dialogue_id = ""

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", false)

	dialogue_active_changed.emit(false)
	dialogue_finished.emit(finished_id)


func _set_debug(message: String) -> void:
	var main_node := get_parent()
	if main_node != null and main_node.has_method("set_interaction_debug"):
		main_node.call("set_interaction_debug", message)
