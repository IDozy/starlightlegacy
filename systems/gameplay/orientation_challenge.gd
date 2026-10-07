extends StaticBody3D

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")

signal challenge_active_changed(active: bool)
signal challenge_completed

@export var target_headings: PackedInt32Array = PackedInt32Array([90, 225, 45])
@export var step_degrees: int = 15

@onready var challenge_panel: Control = $ChallengeHUD/Panel
@onready var target_label: Label = $ChallengeHUD/Panel/Target
@onready var current_label: Label = $ChallengeHUD/Panel/Current
@onready var progress_label: Label = $ChallengeHUD/Panel/Progress
@onready var status_label: Label = $ChallengeHUD/Panel/Status
@onready var hint_label: Label = $ChallengeHUD/Panel/Hint

var _player: Node = null
var _active := false
var _completed := false
var _review_only := false
var _target_index := 0
var _current_heading := 0


func _ready() -> void:
	challenge_panel.visible = false


func get_interaction_prompt() -> String:
	if _completed:
		return "E · Revisar calibración"

	return "E · Calibrar orientación"


func interact(player: Node) -> void:
	if _active:
		return

	_player = player

	if _completed:
		_open_review()
	else:
		_start_challenge()


func set_completed_state(completed: bool) -> void:
	_completed = completed


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	if _review_only:
		if INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
			_close_panel()
			get_viewport().set_input_as_handled()
		return

	if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT):
		_current_heading = wrapi(_current_heading - step_degrees, 0, 360)
		_update_display()
		get_viewport().set_input_as_handled()
		return

	if INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
		_current_heading = wrapi(_current_heading + step_degrees, 0, 360)
		_update_display()
		get_viewport().set_input_as_handled()
		return

	if INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER):
		_confirm_heading()
		get_viewport().set_input_as_handled()
		return

	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close_panel()
		get_viewport().set_input_as_handled()


func _start_challenge() -> void:
	_active = true
	_review_only = false
	_target_index = 0
	_current_heading = 0

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	challenge_panel.visible = true
	status_label.text = "Alinea la lectura actual con la referencia indicada."
	hint_label.text = "A / D · Girar referencia    E · Confirmar    Esc · Salir"
	challenge_active_changed.emit(true)
	_update_display()


func _open_review() -> void:
	_active = true
	_review_only = true

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	challenge_panel.visible = true
	target_label.text = "SISTEMA ESTABLE"
	current_label.text = "ORIENTACIÓN CALIBRADA"
	progress_label.text = "3 / 3 referencias"
	status_label.text = "El sistema puede comparar cómo gira la nave con una referencia estable."
	hint_label.text = "E / Esc · Cerrar"
	challenge_active_changed.emit(true)


func _confirm_heading() -> void:
	if _target_index >= target_headings.size():
		return

	var target := int(target_headings[_target_index])

	if _current_heading != target:
		status_label.text = "La lectura todavía no coincide con la referencia."
		return

	_target_index += 1

	if _target_index >= target_headings.size():
		_complete_challenge()
		return

	status_label.text = "Referencia estable. Busca el siguiente rumbo."
	_update_display()


func _complete_challenge() -> void:
	_completed = true
	_review_only = true

	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call(
			"register_discovery",
			"gyroscopic_orientation",
			"Orientación y giroscopios",
			"Navegación",
			"Un giroscopio conserva una referencia de orientación. Comparando esa referencia con el movimiento de la nave, el sistema puede detectar cambios de actitud y ayudar a corregirlos."
		)

	target_label.text = "CALIBRACIÓN COMPLETADA"
	current_label.text = "REFERENCIA ESTABLE"
	progress_label.text = "%d / %d referencias" % [target_headings.size(), target_headings.size()]
	status_label.text = "Has comprobado cómo una referencia estable permite reconocer la orientación de una nave."
	hint_label.text = "E / Esc · Continuar"

	challenge_completed.emit()


func _close_panel() -> void:
	_active = false
	_review_only = false
	challenge_panel.visible = false

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)

	challenge_active_changed.emit(false)


func _update_display() -> void:
	if _target_index >= target_headings.size():
		return

	var target := int(target_headings[_target_index])
	target_label.text = "OBJETIVO   %03d°" % target
	current_label.text = "ACTUAL     %03d°" % _current_heading
	progress_label.text = "Referencia %d de %d" % [_target_index + 1, target_headings.size()]
