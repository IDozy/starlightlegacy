extends StaticBody3D
## Recuerdo Viking 1: ejercicio de método científico, NO reproduccion
## de los resultados, experimentos o datos reales de biología Viking.
## NASA: experimentos revelaron actividad química, pero no evidencia
## definitiva de vida marciana en los lugares estudiados.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "viking_1"
const STEP_SAMPLE := 0
const STEP_COMPARE := 1
const STEP_CONCLUSION := 2
const STEP_FINISHED := 3

var _lander: Node3D = null
var _player: Node = null
var _active := false
var _complete := false
var _step := STEP_SAMPLE
var _choice := 0
var _sample_collected := false
var _controls_checked := false
var _responsible_conclusion := false
var _feedback := ""
var _started_frame := -1

var _panel: ColorRect
var _title: Label
var _status: Label
var _description: Label
var _hint: Label


func _ready() -> void:
	_complete = _has_discovery(DISCOVERY_ID)
	if _complete:
		_step = STEP_FINISHED
	_build_station()
	_build_hud()


func connect_lander(lander: Node3D) -> void:
	_lander = lander


func get_interaction_prompt() -> String:
	return "E · Revisar laboratorio de Viking 1" if _complete else "E · Analizar muestras de suelo con Viking 1"


func interact(player: Node) -> void:
	if player == null or _active:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_panel.visible = true
	if _complete:
		_step = STEP_FINISHED
		_choice = 0
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if Engine.get_process_frames() == _started_frame:
		return
	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close()
		get_viewport().set_input_as_handled()
		return
	var left := INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT)
	var right := INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT)
	if left or right:
		_choice = 1 - _choice
		_feedback = ""
		_show()
		get_viewport().set_input_as_handled()
		return
	if not (INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)):
		return
	match _step:
		STEP_SAMPLE:
			_confirm_sample()
		STEP_COMPARE:
			_confirm_comparison()
		STEP_CONCLUSION:
			_confirm_conclusion()
		STEP_FINISHED:
			var details := _choice == 1
			_close()
			if details:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_sample() -> void:
	if _choice != 1:
		_feedback = "Viking 1 no transportó astronautas: tomó suelo mediante un brazo mecánico."
		_show()
		return
	if _lander == null or not _lander.has_method("deploy_sampler_preview"):
		_feedback = "Falta el modelo del aterrizador para recoger la muestra."
		_show()
		return
	_lander.call("deploy_sampler_preview")
	_sample_collected = true
	_step = STEP_COMPARE
	_choice = 0
	_feedback = "La muestra se introduce en el laboratorio. Observamos una reacción simulada."
	_show()


func _confirm_comparison() -> void:
	if not _sample_collected:
		return
	if _choice != 1:
		_feedback = "Una reacción aislada no demuestra qué la produjo. Necesitamos comparar resultados."
		_show()
		return
	_controls_checked = true
	_step = STEP_CONCLUSION
	_choice = 0
	_feedback = "Comparación educativa: también hay procesos químicos sin vida."
	_show()


func _confirm_conclusion() -> void:
	if not _sample_collected or not _controls_checked:
		return
	if _choice != 1:
		_feedback = "La NASA NO concluyó que Viking 1 hubiera descubierto vida en Marte."
		_show()
		return
	_responsible_conclusion = true
	_complete = true
	_step = STEP_FINISHED
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "VIKING 1 · MARTE · CHRYSE PLANITIA · 1976"
	match _step:
		STEP_SAMPLE:
			_status.text = "1 / 3 · ¿CÓMO LLEGA LA MUESTRA?"
			_description.text = "El aterrizador está inmóvil sobre Marte. Debemos recoger suelo sin traerlo a la Tierra.\n\n%s UN ASTRONAUTA SALE A RECOGERLO\n%s EL BRAZO ROBÓTICO RECOGE SUELO\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_COMPARE:
			_status.text = "2 / 3 · ¿QUÉ SIGNIFICA LA REACCIÓN?"
			_description.text = "En la maqueta aparece una señal química, pero no sabemos su causa. Es un resultado inventado para este reto.\n\n%s AFIRMAR VIDA SOLO POR UNA SEÑAL\n%s COMPARAR PRUEBAS Y POSIBLES CAUSAS\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_CONCLUSION:
			_status.text = "3 / 3 · ELEGIR CONCLUSIÓN CIENTÍFICA"
			_description.text = "Los experimentos auténticos de Viking produjeron actividad química desconcertante, pero NO demostraron la presencia de microorganismos marcianos.\n\n%s VIKING DEMOSTRÓ QUE HABÍA VIDA\n%s RESULTADOS INTERESANTES, NO CONCLUYENTES\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_FINISHED:
			_status.text = "DESCUBRIMIENTO · UNA PREGUNTA ABIERTA"
			_description.text = "Viking 1 aterrizó el 20 de julio de 1976, examinó suelo marciano y transmitió datos. No confirmó vida. Su aterrizador sigue sobre Marte y fue visto desde órbita.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Viking 1 · Lander", "Exploración científica de Marte · 1976",
			"Viking 1 aterrizó en Chryse Planitia el 20 de julio de 1976. Su brazo tomó muestras y los experimentos biológicos obtuvieron señales químicas, sin evidencia definitiva de vida. El aterrizador no fue recuperado.")


func _has_discovery(id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_station() -> void:
	var body := MeshInstance3D.new()
	body.name = "ScienceConsole"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.20, 1.00, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.26, 0.31, 0.33)
	geometry.material = material
	body.mesh = geometry
	body.position.y = 0.50
	add_child(body)
	var screen := MeshInstance3D.new()
	screen.name = "SampleAnalysisScreen"
	var monitor := BoxMesh.new()
	monitor.size = Vector3(0.94, 0.44, 0.03)
	var monitor_mat := StandardMaterial3D.new()
	monitor_mat.albedo_color = Color(0.07, 0.15, 0.20)
	monitor_mat.emission_enabled = true
	monitor_mat.emission = Color(0.025, 0.12, 0.17)
	monitor.material = monitor_mat
	screen.mesh = monitor
	screen.position = Vector3(0, 0.69, 0.40)
	add_child(screen)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.24, 1.01, 0.82)
	collision.shape = shape
	collision.position.y = 0.51
	add_child(collision)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ScienceHUD"
	canvas.layer = 76
	add_child(canvas)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.20
	_panel.anchor_top = 0.17
	_panel.anchor_right = 0.80
	_panel.anchor_bottom = 0.83
	_panel.color = Color(0.027, 0.040, 0.055, 0.98)
	canvas.add_child(_panel)
	_title = _make_label("Title", 0.06, 0.05, 0.94, 0.15, 21, Color(0.95, 0.78, 0.44))
	_status = _make_label("Status", 0.08, 0.18, 0.92, 0.31, 19, Color(0.48, 0.86, 0.91))
	_description = _make_label("Description", 0.08, 0.34, 0.92, 0.83, 17, Color(0.92, 0.94, 0.97))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _make_label("Hint", 0.05, 0.87, 0.95, 0.98, 14, Color(0.75, 0.81, 0.86))


func _make_label(label_name: String, left: float, top: float,
	right: float, bottom: float, size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.anchor_left = left
	label.anchor_top = top
	label.anchor_right = right
	label.anchor_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_panel.add_child(label)
	return label
