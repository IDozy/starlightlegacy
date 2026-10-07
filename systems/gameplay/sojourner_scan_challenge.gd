extends StaticBody3D

signal challenge_active_changed(active: bool)
signal challenge_completed

const DISCOVERY_ID := "sojourner_apxs"

@export var max_drive_steps: int = 4
@export var scan_duration: float = 2.4

@onready var rover_visual: Node3D = $RoverVisual
@onready var panel: Control = $ChallengeHUD/Panel
@onready var mission_label: Label = $ChallengeHUD/Panel/Mission
@onready var instruction_label: Label = $ChallengeHUD/Panel/Instruction
@onready var distance_label: Label = $ChallengeHUD/Panel/Distance
@onready var status_label: Label = $ChallengeHUD/Panel/Status
@onready var scan_progress: ProgressBar = $ChallengeHUD/Panel/ScanProgress
@onready var hint_label: Label = $ChallengeHUD/Panel/Hint

var _player: Node = null
var _active := false
var _completed := false
var _review_only := false
var _drive_step := 0
var _scanning := false
var _scan_elapsed := 0.0


func _ready() -> void:
	panel.visible = false
	scan_progress.visible = false
	set_process(false)
	_update_rover_position()


func get_interaction_prompt() -> String:
	if _completed:
		return "E · Revisar Sojourner"

	return "E · Operar Sojourner"


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

	if completed:
		_drive_step = max_drive_steps
		_update_rover_position()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	if _review_only:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			_close_panel()
			get_viewport().set_input_as_handled()
		return

	if _scanning:
		return

	if event.keycode == KEY_W or event.keycode == KEY_UP:
		_drive_step = min(_drive_step + 1, max_drive_steps)
		_update_rover_position()
		_update_drive_display()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_S or event.keycode == KEY_DOWN:
		_drive_step = max(_drive_step - 1, 0)
		_update_rover_position()
		_update_drive_display()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_E or event.keycode == KEY_ENTER:
		if _drive_step >= max_drive_steps:
			_start_scan()
		else:
			status_label.text = "Sojourner todavía está demasiado lejos de la roca."
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _scanning:
		return

	_scan_elapsed = min(_scan_elapsed + delta, scan_duration)
	scan_progress.value = (_scan_elapsed / scan_duration) * 100.0

	if _scan_elapsed >= scan_duration:
		_finish_scan()


func _start_challenge() -> void:
	_active = true
	_review_only = false
	_scanning = false
	_scan_elapsed = 0.0

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	panel.visible = true
	scan_progress.visible = false
	mission_label.text = "MARS PATHFINDER · SOJOURNER · ARES VALLIS · 1997"
	instruction_label.text = "Acerca el rover a la roca para que el APXS pueda analizarla."
	hint_label.text = "W / S · Mover rover    E · Usar APXS    Esc · Salir"
	status_label.text = "Sojourner fue el primer vehículo con ruedas que recorrió otro planeta."
	challenge_active_changed.emit(true)
	_update_drive_display()


func _open_review() -> void:
	_active = true
	_review_only = true

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	panel.visible = true
	scan_progress.visible = false
	mission_label.text = "MARS PATHFINDER · SOJOURNER · MISIÓN COMPLETADA"
	instruction_label.text = "APXS · Alpha Proton X-Ray Spectrometer"
	distance_label.text = "ROCA Y SUELO · COMPOSICIÓN QUÍMICA"
	status_label.text = "Sojourner exploró Marte durante 83 días y ayudó a estudiar la composición de sus rocas y suelo."
	hint_label.text = "E / Esc · Cerrar"
	challenge_active_changed.emit(true)


func _start_scan() -> void:
	_scanning = true
	_scan_elapsed = 0.0
	scan_progress.value = 0.0
	scan_progress.visible = true
	instruction_label.text = "APXS en contacto · Analizando composición..."
	status_label.text = "El instrumento mide los elementos presentes en la roca y el suelo."
	hint_label.text = "Analizando..."
	set_process(true)


func _finish_scan() -> void:
	_scanning = false
	set_process(false)
	scan_progress.value = 100.0
	_completed = true
	_review_only = true

	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call(
			"register_discovery",
			DISCOVERY_ID,
			"Sojourner y su APXS",
			"Hardware en Marte",
			"Sojourner fue el primer rover que recorrió otro planeta. Su APXS analizó químicamente rocas y suelo en Ares Vallis; junto con otros datos de Mars Pathfinder, esas observaciones ayudaron a reconstruir un Marte antiguo más cálido y húmedo."
		)

	mission_label.text = "ANÁLISIS COMPLETADO · SOJOURNER"
	instruction_label.text = "APXS · COMPOSICIÓN REGISTRADA"
	distance_label.text = "LEGADO · UN CAMINO PARA LOS ROVERS DE MARTE"
	status_label.text = "La pequeña misión tecnológica terminó en 1997, pero el hardware y su historia siguen en Marte."
	hint_label.text = "E / Esc · Continuar"
	challenge_completed.emit()


func _close_panel() -> void:
	_active = false
	_review_only = false
	panel.visible = false
	scan_progress.visible = false
	_scanning = false
	set_process(false)

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)

	challenge_active_changed.emit(false)


func _update_drive_display() -> void:
	var remaining := max(max_drive_steps - _drive_step, 0)

	if remaining == 0:
		distance_label.text = "POSICIÓN · JUNTO A LA ROCA"
		status_label.text = "APXS listo. Pulsa E para realizar el análisis."
	else:
		distance_label.text = "TRAMO RESTANTE · %d / %d" % [remaining, max_drive_steps]


func _update_rover_position() -> void:
	if rover_visual == null:
		return

	var ratio := 0.0
	if max_drive_steps > 0:
		ratio = float(_drive_step) / float(max_drive_steps)

	rover_visual.position.z = lerp(0.48, -0.55, ratio)
