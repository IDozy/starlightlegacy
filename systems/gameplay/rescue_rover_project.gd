extends StaticBody3D

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")

signal project_active_changed(active: bool)
signal project_state_changed

const PROBLEM_ID := "rescue_rover_impact_problem"
const PATHFINDER_ID := "mars_pathfinder_lander"
const SOJOURNER_ID := "sojourner_apxs"
const UPGRADE_ID := "rescue_rover_airbag_upgrade"
const ENERGY_PROBLEM_ID := "rescue_rover_energy_problem"
const VANGUARD_ID := "vanguard_1"
const SOLAR_UPGRADE_ID := "rescue_rover_solar_upgrade"
const ORIENTATION_PROBLEM_ID := "rescue_rover_orientation_problem"
const SURVEYOR_ID := "surveyor_1"
const ORIENTATION_UPGRADE_ID := "rescue_rover_orientation_upgrade"
const MODULE_PROBLEM_ID := "rescue_rover_module_separation_problem"
const APOLLO_ID := "apollo_11_descent_stage"
const MODULE_UPGRADE_ID := "rescue_rover_modular_release_upgrade"
const TRACTION_PROBLEM_ID := "rescue_rover_traction_problem"
const APOLLO15_ID := "apollo_15_lrv"
const TRACTION_UPGRADE_ID := "rescue_rover_traction_upgrade"

const MODE_TEST := 0
const MODE_WAITING := 1
const MODE_UPGRADE := 2
const MODE_REVIEW := 3
const MODE_ENERGY_TEST := 4
const MODE_ENERGY_WAITING := 5
const MODE_SOLAR_UPGRADE := 6
const MODE_SOLAR_REVIEW := 7
const MODE_ORIENTATION_TEST := 8
const MODE_ORIENTATION_WAITING := 9
const MODE_ORIENTATION_UPGRADE := 10
const MODE_ORIENTATION_REVIEW := 11
const MODE_MODULE_TEST := 12
const MODE_MODULE_WAITING := 13
const MODE_MODULE_UPGRADE := 14
const MODE_MODULE_REVIEW := 15
const MODE_TRACTION_TEST := 16
const MODE_TRACTION_WAITING := 17
const MODE_TRACTION_UPGRADE := 18
const MODE_TRACTION_REVIEW := 19

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
@onready var solar_visual: Node3D = $SolarUpgradeVisual
@onready var adjustable_visual: Node3D = $OrientationUpgradeVisual
@onready var transport_base_visual: Node3D = $TransportBaseVisual
@onready var modular_visual: Node3D = $ModularReleaseVisual
@onready var released_base_visual: Node3D = $ReleasedBaseVisual
@onready var traction_visual: Node3D = $TractionWheelUpgradeVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _player: Node = null
var _active := false
var _mode := MODE_TEST
var _test_step := 0
var _selection := OPTION_ELASTIC
var _energy_selection := 1
var _energy_test_step := 0
var _orientation_test_step := 0
var _orientation_selection := 1
var _module_test_step := 0
var _module_selection := 1
var _traction_test_step := 0
var _traction_selection := 1
var _started_frame := -1


func _ready() -> void:
	panel.visible = false
	_refresh_visual_state()


func get_interaction_prompt() -> String:
	if _has_discovery(TRACTION_UPGRADE_ID):
		return "E · Revisar mejora de movilidad sobre terreno suelto"
	if _has_discovery(APOLLO15_ID):
		return "E · Mejorar tracción inspirada en Apollo 15"
	if _has_discovery(TRACTION_PROBLEM_ID):
		return "E · Revisar bloqueo por falta de tracción"
	if _has_discovery(MODULE_UPGRADE_ID):
		return "E · Probar desplazamiento por terreno irregular"
	if _has_discovery(APOLLO_ID):
		return "E · Aplicar diseño de separación Apollo 11"
	if _has_discovery(MODULE_PROBLEM_ID):
		return "E · Revisar base auxiliar bloqueada"
	if _has_discovery(ORIENTATION_UPGRADE_ID):
		return "E · Probar liberación de base auxiliar"
	if _has_discovery(SURVEYOR_ID):
		return "E · Aplicar orientacion del panel y la camara"
	if _has_discovery(ORIENTATION_PROBLEM_ID):
		return "E · Revisar fallo de orientacion"
	if _has_discovery(SOLAR_UPGRADE_ID):
		return "E · Probar orientacion de panel y camara"
	if _has_discovery(VANGUARD_ID):
		return "E · Instalar panel solar y ahorro de energia"
	if _has_discovery(ENERGY_PROBLEM_ID):
		return "E · Revisar la bateria agotada"
	if _has_discovery(UPGRADE_ID):
		return "E · Probar autonomia del Vehiculo Explorador"

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

	if _has_discovery(TRACTION_UPGRADE_ID):
		_open_traction_review()
	elif _has_discovery(APOLLO15_ID):
		_open_traction_upgrade()
	elif _has_discovery(TRACTION_PROBLEM_ID):
		_open_traction_waiting()
	elif _has_discovery(MODULE_UPGRADE_ID):
		_open_traction_test()
	elif _has_discovery(APOLLO_ID):
		_open_module_upgrade()
	elif _has_discovery(MODULE_PROBLEM_ID):
		_open_module_waiting()
	elif _has_discovery(ORIENTATION_UPGRADE_ID):
		_open_module_test()
	elif _has_discovery(SURVEYOR_ID):
		_open_orientation_upgrade()
	elif _has_discovery(ORIENTATION_PROBLEM_ID):
		_open_orientation_waiting()
	elif _has_discovery(SOLAR_UPGRADE_ID):
		_open_orientation_test()
	elif _has_discovery(VANGUARD_ID):
		_open_solar_upgrade()
	elif _has_discovery(ENERGY_PROBLEM_ID):
		_open_energy_waiting()
	elif _has_discovery(UPGRADE_ID):
		_open_energy_test()
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

		MODE_TRACTION_TEST:
			if _is_confirm_key(event):
				if _traction_test_step == 0:
					_record_traction_failure()
					_traction_test_step = 1
					_show_traction_failure()
				else:
					_close_panel()
				get_viewport().set_input_as_handled()

		MODE_TRACTION_UPGRADE:
			if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT) or INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
				_traction_selection = 1 - _traction_selection
				_render_traction_option()
				get_viewport().set_input_as_handled()
			elif _is_confirm_key(event):
				_confirm_traction_upgrade()
				get_viewport().set_input_as_handled()

		MODE_MODULE_TEST:
			if _is_confirm_key(event):
				if _module_test_step == 0:
					_record_module_failure()
					_module_test_step = 1
					_show_module_failure()
				else:
					_close_panel()
				get_viewport().set_input_as_handled()

		MODE_MODULE_UPGRADE:
			if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT) or INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
				_module_selection = 1 - _module_selection
				_render_module_option()
				get_viewport().set_input_as_handled()
			elif _is_confirm_key(event):
				_confirm_module_upgrade()
				get_viewport().set_input_as_handled()

		MODE_ORIENTATION_TEST:
			if _is_confirm_key(event):
				if _orientation_test_step == 0:
					_record_orientation_failure()
					_orientation_test_step = 1
					_show_orientation_failure()
				else:
					_close_panel()
				get_viewport().set_input_as_handled()

		MODE_ORIENTATION_UPGRADE:
			if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT) or INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
				_orientation_selection = 1 - _orientation_selection
				_render_orientation_option()
				get_viewport().set_input_as_handled()
			elif _is_confirm_key(event):
				_confirm_orientation_upgrade()
				get_viewport().set_input_as_handled()

		MODE_ENERGY_TEST:
			if _is_confirm_key(event):
				if _energy_test_step == 0:
					_record_energy_failure()
					_energy_test_step = 1
					_show_energy_failure_result()
				else:
					_close_panel()
				get_viewport().set_input_as_handled()

		MODE_SOLAR_UPGRADE:
			if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT):
				_energy_selection = 1 - _energy_selection
				_render_solar_option()
				get_viewport().set_input_as_handled()
			elif INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
				_energy_selection = 1 - _energy_selection
				_render_solar_option()
				get_viewport().set_input_as_handled()
			elif _is_confirm_key(event):
				_confirm_solar_upgrade()
				get_viewport().set_input_as_handled()

		MODE_WAITING, MODE_REVIEW, MODE_ENERGY_WAITING, MODE_SOLAR_REVIEW, MODE_ORIENTATION_WAITING, MODE_ORIENTATION_REVIEW, MODE_MODULE_WAITING, MODE_MODULE_REVIEW, MODE_TRACTION_WAITING, MODE_TRACTION_REVIEW:
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


func _open_energy_test() -> void:
	_mode = MODE_ENERGY_TEST
	_energy_test_step = 0
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PRUEBA 2 · AUTONOMÍA ELÉCTRICA"
	body_label.text = "La amortiguación funciona. Ahora enciende motores, cámara y luz de rescate. ¿La batería alcanzará para completar la búsqueda?"
	option_label.text = "E · INICIAR PRUEBA ENERGÉTICA"
	feedback_label.text = ""
	hint_label.text = "E / Enter · Ejecutar prueba    Esc · Salir"


func _show_energy_failure_result() -> void:
	status_label.text = "FALLO · BATERÍA AGOTADA"
	body_label.text = "Los motores y las luces consumen la reserva antes de terminar la misión. El vehículo necesita conseguir y administrar mejor la energía."
	option_label.text = "NUEVO PROBLEMA · AUTONOMÍA"
	feedback_label.text = "Abuelo: Esto me recuerda a un pequeño satélite de 1958..."
	hint_label.text = "E / Enter · Continuar"


func _open_energy_waiting() -> void:
	_mode = MODE_ENERGY_WAITING
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PROBLEMA PENDIENTE · ENERGÍA"
	body_label.text = "El vehículo ya resiste la caída, pero la batería se agota. Habla con el abuelo para conocer Vanguard 1."
	option_label.text = "OBJETIVO · HABLA CON EL ABUELO"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _open_solar_upgrade() -> void:
	_mode = MODE_SOLAR_UPGRADE
	_energy_selection = 1
	title_label.text = "APLICAR LO APRENDIDO"
	status_label.text = "VANGUARD 1 · ENERGÍA SOLAR"
	body_label.text = "En el recuerdo viste cómo las células solares ayudan a extender el funcionamiento de una nave. ¿Qué mejora conviene al Vehículo Explorador de Rescate?"
	feedback_label.text = ""
	hint_label.text = "A / D · Elegir    E / Enter · Aplicar    Esc · Salir"
	_render_solar_option()


func _render_solar_option() -> void:
	option_label.text = "◀ SOLO UNA BATERÍA MÁS GRANDE ▶" if _energy_selection == 0 else "◀ PANEL SOLAR + MODO DE AHORRO ▶"


func _confirm_solar_upgrade() -> void:
	if _energy_selection == 0:
		feedback_label.text = "Una batería mayor dura más, pero no repone la energía consumida. Prueba otra solución."
		return
	var registry := _registry()
	if registry == null:
		feedback_label.text = "El sistema de descubrimientos no está disponible."
		return
	registry.call("register_discovery", SOLAR_UPGRADE_ID,
		"Mejora: energía solar y ahorro",
		"Proyecto del niño",
		"El Vehículo Explorador integra un panel solar y una modalidad de ahorro para extender su autonomía cuando recibe luz.")
	_refresh_visual_state()
	project_state_changed.emit()
	_open_solar_review()


func _open_solar_review() -> void:
	_mode = MODE_SOLAR_REVIEW
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "MEJORA APLICADA · ENERGÍA"
	body_label.text = "El vehículo ya amortigua los impactos y cuenta con un módulo solar y ahorro de energía. El siguiente reto podrá exigir orientación del panel y de la cámara."
	option_label.text = "PROYECTO EVOLUCIONADO · AUTONOMÍA"
	feedback_label.text = "Vanguard 1 · Conocimiento aplicado"
	hint_label.text = "E / Esc · Cerrar"


func _record_energy_failure() -> void:
	var registry := _registry()
	if registry == null:
		return
	registry.call("register_discovery", ENERGY_PROBLEM_ID,
		"Problema: batería agotada",
		"Proyecto del niño",
		"El Vehículo Explorador de Rescate agota su batería al usar motor, luz y cámara antes de terminar la prueba.")
	project_state_changed.emit()


func _open_orientation_test() -> void:
	_mode = MODE_ORIENTATION_TEST
	_orientation_test_step = 0
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PRUEBA 3 · ORIENTACIÓN Y OBSERVACIÓN"
	body_label.text = "Ya tienes energía solar, pero al cambiar la dirección de la luz el panel no recibe suficiente iluminación. La cámara apunta fuera del objetivo de rescate. Prueba ambos sistemas."
	option_label.text = "E · INICIAR PRUEBA DE ORIENTACIÓN"
	feedback_label.text = ""
	hint_label.text = "E / Enter · Ejecutar prueba    Esc · Salir"


func _show_orientation_failure() -> void:
	status_label.text = "FALLO · PANEL Y CÁMARA MAL ORIENTADOS"
	body_label.text = "El panel recibe menos luz y la cámara no encuentra el objeto. No basta con tener electricidad: debemos dirigir los instrumentos correctamente."
	option_label.text = "NUEVO PROBLEMA · ORIENTACIÓN"
	feedback_label.text = "Abuelo: Surveyor 1 recibía órdenes de la Tierra para operar sobre la Luna..."
	hint_label.text = "E / Enter · Continuar"


func _open_orientation_waiting() -> void:
	_mode = MODE_ORIENTATION_WAITING
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PROBLEMA PENDIENTE · ORIENTACIÓN"
	body_label.text = "Nuestro panel y la cámara necesitan orientación controlada. Habla con el abuelo sobre Surveyor 1 antes de modificarlos."
	option_label.text = "OBJETIVO · HABLA CON EL ABUELO"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _open_orientation_upgrade() -> void:
	_mode = MODE_ORIENTATION_UPGRADE
	_orientation_selection = 1
	title_label.text = "APLICAR LO APRENDIDO"
	status_label.text = "SURVEYOR 1 · ÓRDENES Y ORIENTACIÓN"
	body_label.text = "En 1966 Surveyor 1 recibió órdenes desde Tierra para orientar sistemas y observar la Luna. ¿Cómo adaptarías esa idea al vehículo de la feria?"
	feedback_label.text = ""
	hint_label.text = "A / D · Elegir    E / Enter · Aplicar    Esc · Salir"
	_render_orientation_option()


func _render_orientation_option() -> void:
	option_label.text = "◀ MÁS BRILLO EN LA PANTALLA ▶" if _orientation_selection == 0 else "◀ SOPORTE DE PANEL Y CÁMARA REGULABLES ▶"


func _confirm_orientation_upgrade() -> void:
	if _orientation_selection == 0:
		feedback_label.text = "El brillo no orienta ni el panel solar ni la cámara. Prueba ajustar ambos mecanismos."
		return
	var registry := _registry()
	if registry == null:
		feedback_label.text = "No se pudo abrir el Archivo NASA."
		return
	registry.call("register_discovery", ORIENTATION_UPGRADE_ID,
		"Mejora: panel y cámara orientables",
		"Proyecto del niño",
		"El Vehículo Explorador integra un soporte regulable para orientar un panel solar y una cámara hacia su objetivo.")
	_refresh_visual_state()
	project_state_changed.emit()
	_open_orientation_review()


func _open_orientation_review() -> void:
	_mode = MODE_ORIENTATION_REVIEW
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "MEJORA APLICADA · ORIENTACIÓN"
	body_label.text = "La amortiguación y la autonomía ya funcionaban. Ahora el panel se puede orientar y la cámara puede observar el objetivo sin girar todo el vehículo."
	option_label.text = "PROYECTO EVOLUCIONADO · OBSERVACIÓN REMOTA"
	feedback_label.text = "Surveyor 1 · Conocimiento aplicado"
	hint_label.text = "E / Esc · Cerrar"


func _record_orientation_failure() -> void:
	var registry := _registry()
	if registry == null:
		return
	registry.call("register_discovery", ORIENTATION_PROBLEM_ID,
		"Problema: orientar panel y cámara",
		"Proyecto del niño",
		"El Vehículo Explorador no orienta adecuadamente el panel hacia la luz ni la cámara hacia el objetivo.")
	project_state_changed.emit()


func _open_module_test() -> void:
	_mode = MODE_MODULE_TEST
	_module_test_step = 0
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PRUEBA 4 · BASE AUXILIAR DE TRANSPORTE"
	body_label.text = "Los instrumentos ya funcionan. Para iniciar la fase final de rescate, el rover debe desprenderse de su base auxiliar de transporte. Todavía no tiene un mecanismo de liberación: queda bloqueado."
	option_label.text = "E · INICIAR PRUEBA DE SALIDA"
	feedback_label.text = ""
	hint_label.text = "E / Enter · Ejecutar prueba    Esc · Salir"


func _show_module_failure() -> void:
	status_label.text = "FALLO · SOPORTE AUXILIAR FIJO"
	body_label.text = "El vehículo tiene ruedas y energía, pero su soporte de transporte permanece unido y no puede continuar la ruta. Necesitamos separar funciones: una base estable para preparar la salida y un vehículo libre para explorar."
	option_label.text = "NUEVO PROBLEMA · SEPARACIÓN SEGURA"
	feedback_label.text = "Abuelo: Eagle utilizó dos etapas para aterrizar y regresar de la Luna."
	hint_label.text = "E / Enter · Continuar"


func _open_module_waiting() -> void:
	_mode = MODE_MODULE_WAITING
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PROBLEMA PENDIENTE · SEPARACIÓN"
	body_label.text = "La base auxiliar sigue bloqueando el vehículo. Habla con el abuelo para conocer las dos etapas del módulo Eagle de Apollo 11."
	option_label.text = "OBJETIVO · HABLA CON EL ABUELO"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _open_module_upgrade() -> void:
	_mode = MODE_MODULE_UPGRADE
	_module_selection = 1
	title_label.text = "APLICAR LO APRENDIDO"
	status_label.text = "APOLLO 11 · ETAPA DE DESCENSO"
	body_label.text = "Eagle dejó su etapa inferior en la Luna y utilizó la superior para volver a la órbita. Tu rover de feria no despega, pero también necesita liberar una base que ya cumplió su función."
	feedback_label.text = ""
	hint_label.text = "A / D · Elegir    E / Enter · Instalar    Esc · Salir"
	_render_module_option()


func _render_module_option() -> void:
	option_label.text = "◀ QUITAR LAS RUEDAS PARA ALIGERAR ▶" if _module_selection == 0 else "◀ SISTEMA DE LIBERACIÓN DE BASE AUXILIAR ▶"


func _confirm_module_upgrade() -> void:
	if _module_selection == 0:
		feedback_label.text = "Sin ruedas el vehículo no podrá explorar. La parte a separar es la base de transporte, no sus sistemas de movilidad."
		return
	if not _has_discovery(APOLLO_ID) or not _has_discovery(ORIENTATION_UPGRADE_ID):
		feedback_label.text = "Completa primero el recuerdo de Apollo 11 y los pasos anteriores."
		return
	var registry := _registry()
	if registry == null:
		feedback_label.text = "No se encontró el registro de descubrimientos."
		return
	registry.call("register_discovery", MODULE_UPGRADE_ID,
		"Mejora: liberación modular",
		"Proyecto del niño",
		"El rover incorpora un acoplamiento liberable para dejar la base auxiliar en el punto de partida y continuar la misión con sus sistemas de movilidad, energía y cámara.")
	_refresh_visual_state()
	project_state_changed.emit()
	_open_module_review()


func _open_module_review() -> void:
	_mode = MODE_MODULE_REVIEW
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "MEJORA APLICADA · SEPARACIÓN MODULAR"
	body_label.text = "La base auxiliar queda en el área de pruebas. El rover puede salir con sus ruedas, cámara, panel solar y protección de impacto. La etapa inferior de Eagle fue una plataforma lunar; aquí adaptamos la idea a un soporte de transporte."
	option_label.text = "PROYECTO EVOLUCIONADO · BASE LIBERABLE"
	feedback_label.text = "Apollo 11 · Conocimiento aplicado."
	hint_label.text = "E / Esc · Cerrar"


func _record_module_failure() -> void:
	var registry := _registry()
	if registry == null:
		return
	registry.call("register_discovery", MODULE_PROBLEM_ID,
		"Problema: base de transporte no liberable",
		"Proyecto del niño",
		"El Vehículo Explorador de Rescate tiene un soporte auxiliar que le impide iniciar la exploración. Debe acoplarse y separarse sin perder sus sistemas principales.")
	project_state_changed.emit()


func _open_traction_test() -> void:
	_mode = MODE_TRACTION_TEST
	_traction_test_step = 0
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PRUEBA 5 · MOVILIDAD SOBRE TERRENO SUELTO"
	body_label.text = "Tras liberar la base, el vehículo debe cruzar arena fina y piedras sin perder la estabilidad. Las ruedas actuales patinan y no consiguen avanzar."
	option_label.text = "E · EJECUTAR PRUEBA DE TRACCIÓN"
	feedback_label.text = ""
	hint_label.text = "E / Enter · Probar    Esc · Salir"


func _show_traction_failure() -> void:
	status_label.text = "FALLO · RUEDAS SIN TRACCIÓN"
	body_label.text = "Las ruedas giran, pero el vehículo apenas avanza sobre el suelo suelto. No necesitamos más potencia: debemos mejorar el contacto rueda-terreno y distribuir mejor la carga."
	option_label.text = "NUEVO PROBLEMA · MOVILIDAD"
	feedback_label.text = "Abuelo: Los astronautas de Apollo 15 exploraron la Luna usando ruedas muy especiales..."
	hint_label.text = "E / Enter · Continuar"


func _open_traction_waiting() -> void:
	_mode = MODE_TRACTION_WAITING
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "PROBLEMA PENDIENTE · TRACCIÓN"
	body_label.text = "El rover no puede atravesar terreno suelto. Habla con el abuelo y conoce el Lunar Roving Vehicle de Apollo 15."
	option_label.text = "OBJETIVO · HABLA CON EL ABUELO"
	feedback_label.text = ""
	hint_label.text = "E / Esc · Cerrar"


func _open_traction_upgrade() -> void:
	_mode = MODE_TRACTION_UPGRADE
	_traction_selection = 1
	title_label.text = "APLICAR LO APRENDIDO"
	status_label.text = "APOLLO 15 · RUEDAS Y CARGA"
	body_label.text = "El LRV tripulado tenía ruedas de malla metálica flexible con bandas de tracción. En tu vehículo de feria debes adaptar la idea de mejorar agarre y repartir la carga, sin copiar literalmente su estructura lunar."
	feedback_label.text = ""
	hint_label.text = "A / D · Elegir    E / Enter · Aplicar    Esc · Salir"
	_render_traction_option()


func _render_traction_option() -> void:
	option_label.text = "◀ SOLO AUMENTAR POTENCIA DEL MOTOR ▶" if _traction_selection == 0 else "◀ RUEDAS CON AGARRE + CARGA EQUILIBRADA ▶"


func _confirm_traction_upgrade() -> void:
	if _traction_selection == 0:
		feedback_label.text = "Más potencia no garantiza que las ruedas agarren un suelo suelto. Elige una solución para el contacto y el equilibrio."
		return
	if not _has_discovery(APOLLO15_ID) or not _has_discovery(MODULE_UPGRADE_ID):
		feedback_label.text = "Completa primero Apollo 15 y la separación modular previa."
		return
	var registry := _registry()
	if registry == null:
		feedback_label.text = "Archivo NASA no disponible."
		return
	registry.call("register_discovery", TRACTION_UPGRADE_ID,
		"Mejora: movilidad sobre terreno suelto",
		"Proyecto del niño",
		"El Vehículo Explorador recibe ruedas con bandas de agarre y una distribución de carga revisada, inspirado en la movilidad del Lunar Roving Vehicle de Apollo 15.")
	_refresh_visual_state()
	project_state_changed.emit()
	_open_traction_review()


func _open_traction_review() -> void:
	_mode = MODE_TRACTION_REVIEW
	title_label.text = "VEHÍCULO EXPLORADOR DE RESCATE"
	status_label.text = "MEJORA APLICADA · MOVILIDAD"
	body_label.text = "Ahora el vehículo dispone de agarre y carga equilibrada. Conserva la amortiguación, el módulo solar, la cámara orientable y la liberación de su soporte. La siguiente prueba podrá centrarse en el terreno o los instrumentos."
	option_label.text = "PROYECTO EVOLUCIONADO · TRACCIÓN"
	feedback_label.text = "Apollo 15 · Conocimiento aplicado."
	hint_label.text = "E / Esc · Cerrar"


func _record_traction_failure() -> void:
	var registry := _registry()
	if registry == null:
		return
	registry.call("register_discovery", TRACTION_PROBLEM_ID,
		"Problema: ruedas sin tracción",
		"Proyecto del niño",
		"El Vehículo Explorador pierde tracción al cruzar terreno de arena fina y piedras. Hay que adaptar ruedas y equilibrar su carga.")
	project_state_changed.emit()


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
	var upgraded := _has_discovery(UPGRADE_ID)
	upgrade_visual.visible = upgraded
	adjustable_visual.visible = _has_discovery(ORIENTATION_UPGRADE_ID)
	transport_base_visual.visible = _has_discovery(ORIENTATION_UPGRADE_ID) and not _has_discovery(MODULE_UPGRADE_ID)
	modular_visual.visible = _has_discovery(MODULE_UPGRADE_ID)
	released_base_visual.visible = _has_discovery(MODULE_UPGRADE_ID)
	traction_visual.visible = _has_discovery(TRACTION_UPGRADE_ID)
	# La mejora de Surveyor sustituye SOLO el panel fijo visual anterior;
	# el sistema de energía solar continúa instalado.
	solar_visual.visible = _has_discovery(SOLAR_UPGRADE_ID) and not _has_discovery(ORIENTATION_UPGRADE_ID)

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape == null:
		return

	if upgraded:
		box_shape.size = Vector3(0.96, 0.58, 0.80)
		collision_shape.position = Vector3(0.0, 0.29, 0.0)
	else:
		box_shape.size = Vector3(0.50, 0.52, 0.72)
		collision_shape.position = Vector3(0.0, 0.25, 0.0)


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
