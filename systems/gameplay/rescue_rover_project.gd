extends StaticBody3D

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")

signal project_active_changed(active: bool)
signal project_state_changed

const PROBLEM_ID := "rescue_rover_impact_problem"
const PATHFINDER_ID := "mars_pathfinder_lander"
const SOJOURNER_ID := "sojourner_apxs"
const UPGRADE_ID := "rescue_rover_airbag_upgrade"

const MODE_TEST := 0
const MODE_WAITING := 1
const MODE_UPGRADE := 2
const MODE_REVIEW := 3

const OPTION_MOTOR := 0
const OPTION_ELASTIC := 1
const OPTION_WHEELS := 2
const OPTION_COUNT := 3

@onready var panel: Control = $ProjectHUD/Panel
@onready var title_label: Label = $ProjectHUD/Panel/Title
@onready var status_label: Label = $ProjectHUD/Panel/Status
@onready var body_label: Label = $ProjectHUD/Panel/Body
@onready var option_label: Label = $ProjectHUD/Panel/Option
@onready var feedback_label: Label = $ProjectHUD/Panel/Feedback
@onready var hint_label: Label = $ProjectHUD/Panel/Hint
@onready var upgrade_visual: Node3D = $UpgradeVisual

var _player: Node = null
var _active := false
var _mode := MODE_TEST
var _test_step := 0
var _selection := OPTION_ELASTIC
var _started_frame := -1


func _ready() -> void:
	panel.visible = false
	_refresh_visual_state()


func get_interaction_prompt() -> String:
	if _has_discovery(UPGRADE_ID):
		return "E · Revisar Vehículo Explorador de Rescate"

	if _memories_complete():
		return "E · Aplicar lo aprendido al vehículo"

	if _has_discovery(PROBLEM_ID):
		return "E · Revisar fallo del vehículo"

	return "E · Probar Vehículo Explorador de Rescate"


func interact(player: Node) -> void:
	if _active or player == null:
		return

	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()

	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	panel.visible = true
	project_active_changed.emit(true)

	if _has_discovery(UPGRADE_ID):
		_open_review()
	elif _memories_complete():
		_open_upgrade()
	elif _has_discovery(PROBLEM_ID):
		_open_waiting()
	else:
		_open_test()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	if Engine.get_process_frames() == _started_frame:
		return

	if not event.pressed or event.echo:
		return

	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close_panel()
		get_viewport().set_input_as_handled()
		return

	match _mode:
		MODE_TEST:
			if _is_confirm_key(event):
				if _test_step == 0:
					_record_failure()
					_test_step = 1
					_show_failure_result()
				else:
					_close_panel()
				get_viewport().set_input_as_handled()

		MODE_WAITING, MODE_REVIEW:
			if _is_confirm_key(event):
				_close_panel()
				get_viewport().set_input_as_handled()

		MODE_UPGRADE:
			if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT):
				_selection = wrapi(_selection - 1, 0, OPTION_COUNT)
				_render_upgrade_option()
				get_viewport().set_input_as_handled()
			elif INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
				_selection = wrapi(_selection + 1, 0, OPTION_COUNT)
				_render_upgrade_option()
				get_viewport().set_input_as_handled()
			elif _is_confirm_key(event):
				_confirm_upgrade()
				get_viewport().set_input_as_handled()


func _open_test() -> void:
	_mode = MODE_TEST
	_test_step = 0
	title_label.text = "PROYECTO DE LOS NIÑOS"
	status_label.text = "PRUEBA · CAÍDA CONTROLADA"
	body_label.text = "El Vehículo Explorador de Rescate debe sobrevivir a una pequeña caída de prueba antes de la feria. El chasis está listo, pero todavía no sabemos cómo reaccionará al impacto."
	option_label.text = "ALTURA DE PRUEBA · 1 METRO"
	feedback_label.text = ""
	hint_label.text = "E / Enter · Ejecutar prueba    Esc · Salir"


func _show_failure_result() -> void:
	status_label.text = "FALLO · IMPACTO DEMASIADO FUERTE"
	body_label.text = "El vehículo llega al suelo, rebota y los componentes se sueltan. El problema no es llegar más rápido: necesitamos absorber y repartir la energía del golpe."
	option_label.text = "NUEVO PROBLEMA · ABSORBER EL IMPACTO"
	feedback_label.text = "Abuelo: Ese golpe me recuerda a una misión que tuvo que aterrizar en Marte de una forma bastante peculiar..."
	hint_label.text = "E / Enter · Continuar"


func _open_waiting() -> void:
	_mode = MODE_WAITING
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PROBLEMA PENDIENTE · IMPACTO"
	body_label.text = "El chasis sigue sin una solución para amortiguar la caída. Quizá el abuelo conozca una misión que resolvió un problema parecido."
	option_label.text = "OBJETIVO · HABLA CON EL ABUELO"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _open_upgrade() -> void:
	_mode = MODE_UPGRADE
	_selection = OPTION_ELASTIC
	title_label.text = "APLICAR LO APRENDIDO"
	status_label.text = "PATHFINDER · ABSORCIÓN DE IMPACTO"
	body_label.text = "Ya viste cómo Pathfinder sobrevivió al contacto con Marte. Elige qué modificación ataca realmente el problema de la caída del vehículo."
	feedback_label.text = ""
	hint_label.text = "A / D o ← / → · Elegir    E / Enter · Aplicar    Esc · Salir"
	_render_upgrade_option()


func _render_upgrade_option() -> void:
	match _selection:
		OPTION_MOTOR:
			option_label.text = "◀  MÁS POTENCIA AL MOTOR  ▶"
		OPTION_ELASTIC:
			option_label.text = "◀  ESTRUCTURA ELÁSTICA DE IMPACTO  ▶"
		OPTION_WHEELS:
			option_label.text = "◀  RUEDAS MÁS GRANDES  ▶"


func _confirm_upgrade() -> void:
	match _selection:
		OPTION_ELASTIC:
			_register_upgrade()
			_mode = MODE_REVIEW
			status_label.text = "MEJORA APLICADA · PRUEBA SUPERADA"
			body_label.text = "La estructura elástica se comprime durante el impacto y reparte la desaceleración en más tiempo. El vehículo rebota, pero sus componentes permanecen protegidos."
			option_label.text = "PROYECTO EVOLUCIONADO · AMORTIGUACIÓN DE IMPACTO"
			feedback_label.text = "Conocimiento recuperado → solución aplicada."
			hint_label.text = "E / Esc · Cerrar"
		OPTION_MOTOR:
			feedback_label.text = "Más potencia no reduce el golpe al aterrizar. El problema ocurre cuando el vehículo toca el suelo."
		OPTION_WHEELS:
			feedback_label.text = "Las ruedas ayudarán con el terreno, pero todavía no absorben la energía de una caída."


func _open_review() -> void:
	_mode = MODE_REVIEW
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "MEJORA INSTALADA · AMORTIGUACIÓN"
	body_label.text = "El proyecto ya incorporó una estructura elástica inspirada en la estrategia de aterrizaje de Pathfinder. El siguiente problema del vehículo abrirá una nueva historia."
	option_label.text = "ESTADO · PRUEBA DE IMPACTO SUPERADA"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _record_failure() -> void:
	var registry := _registry()
	if registry == null:
		return

	registry.call(
		"register_discovery",
		PROBLEM_ID,
		"Problema: absorber el impacto",
		"Proyecto del niño",
		"El Vehículo Explorador de Rescate necesita disipar la energía de una caída sin que sus componentes se suelten."
	)
	project_state_changed.emit()


func _register_upgrade() -> void:
	var registry := _registry()
	if registry == null:
		return

	registry.call(
		"register_discovery",
		UPGRADE_ID,
		"Mejora: amortiguación de impacto",
		"Proyecto del niño",
		"El vehículo incorpora una estructura elástica que aumenta el tiempo de desaceleración y protege sus componentes durante el impacto."
	)
	_refresh_visual_state()
	project_state_changed.emit()


func _refresh_visual_state() -> void:
	upgrade_visual.visible = _has_discovery(UPGRADE_ID)


func _memories_complete() -> bool:
	return _has_discovery(PATHFINDER_ID) and _has_discovery(SOJOURNER_ID)


func _has_discovery(discovery_id: String) -> bool:
	var registry := _registry()
	if registry == null:
		return false

	return bool(registry.call("has_discovery", discovery_id))


func _registry() -> Node:
	return get_node_or_null("/root/KnowledgeRegistry")


func _is_confirm_key(event: InputEventKey) -> bool:
	return (
		INPUT_COMPAT.key_matches(event, KEY_E)
		or INPUT_COMPAT.key_matches(event, KEY_ENTER)
		or INPUT_COMPAT.key_matches(event, KEY_SPACE)
	)


func _close_panel() -> void:
	_active = false
	panel.visible = false

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)

	project_active_changed.emit(false)
