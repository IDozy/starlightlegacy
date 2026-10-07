extends Node

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")

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
var _lines: Array[String] = []
var _line_index := 0
var _active := false
var _started_frame := -1
var _advance_key_was_pressed := false


func _ready() -> void:
	add_to_group("dialogue_controller")
	_dialogue_panel.visible = false
	set_process(true)


func _process(_delta: float) -> void:
	var advance_pressed := (
		Input.is_physical_key_pressed(KEY_E)
		or Input.is_physical_key_pressed(KEY_ENTER)
		or Input.is_physical_key_pressed(KEY_SPACE)
	)

	if _active and advance_pressed and not _advance_key_was_pressed:
		advance_dialogue()

	_advance_key_was_pressed = advance_pressed


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if Engine.get_process_frames() == _started_frame:
		return

	var advance := false

	if event is InputEventMouseButton and event.pressed:
		advance = event.button_index == MOUSE_BUTTON_LEFT

	if advance:
		advance_dialogue()
		get_viewport().set_input_as_handled()


func start_dialogue(
	dialogue_id: String,
	speaker: String,
	lines: Array[String],
	source_player: Node = null
) -> void:
	if _active or lines.is_empty():
		return

	if source_player != null:
		player = source_player

	_dialogue_id = dialogue_id
	_speaker = speaker
	_lines = lines.duplicate()
	_line_index = 0
	_active = true
	_started_frame = Engine.get_process_frames()
	_advance_key_was_pressed = (
		Input.is_physical_key_pressed(KEY_E)
		or Input.is_physical_key_pressed(KEY_ENTER)
		or Input.is_physical_key_pressed(KEY_SPACE)
	)

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	_dialogue_panel.visible = true
	hint_label.text = "E / Enter / clic · Continuar"
	dialogue_active_changed.emit(true)
	_show_current_line()


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
