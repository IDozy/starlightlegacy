extends StaticBody3D
## Troy, Spirit (2009-2010). Decisiones educativas, no comandos reales.
## Nunca simular que Spirit escapó del suelo blando de Troy.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "spirit"
const STEP_DETECT := 0
const STEP_ASSESS := 1
const STEP_DECIDE := 2
const STEP_FINISHED := 3

var _rover: Node3D = null
var _player: Node = null
var _active := false
var _complete := false
var _step := STEP_DETECT
var _choice := 0
var _stopped := false
var _risk_checked := false
var _science_prioritized := false
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


func connect_rover(rover: Node3D) -> void:
	_rover = rover


func get_interaction_prompt() -> String:
	return "E · Revisar la historia de Spirit" if _complete else "E · Analizar el riesgo en Troy"


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
		STEP_DETECT:
			_confirm_detection()
		STEP_ASSESS:
			_confirm_assessment()
		STEP_DECIDE:
			_confirm_decision()
		STEP_FINISHED:
			var show_archive := _choice == 1
			_close()
			if show_archive:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_detection() -> void:
	if _choice != 1:
		_feedback = "Las ruedas pueden girar sin avanzar: insistir puede hundir más el rover."
		_show()
		return
	if _rover == null or not _rover.has_method("indicate_slip"):
		_feedback = "Falta el rover del recuerdo para comprobar el deslizamiento."
		_show()
		return
	_rover.call("indicate_slip")
	_stopped = true
	_step = STEP_ASSESS
	_choice = 0
	_feedback = "Detuviste la marcha. Antes de actuar hay que medir el terreno y la inclinación."
	_show()


func _confirm_assessment() -> void:
	if not _stopped:
		return
	if _choice != 1:
		_feedback = "Aumentar potencia sin estudiar suelo e inclinación puede empeorar el atasco."
		_show()
		return
	_risk_checked = true
	_step = STEP_DECIDE
	_choice = 0
	_feedback = "En Troy, los equipos probaron maniobras con modelos en la Tierra y estudiaron datos."
	_show()


func _confirm_decision() -> void:
	if not _stopped or not _risk_checked:
		return
	if _choice != 1:
		_feedback = "Spirit no logró salir de Troy. En 2010 su misión pasó a ciencia estacionaria."
		_show()
		return
	if _rover == null or not _rover.has_method("enter_stationary_science"):
		_feedback = "La estación científica no está disponible."
		_show()
		return
	_rover.call("enter_stationary_science")
	_science_prioritized = true
	_complete = true
	_step = STEP_FINISHED
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "SPIRIT · MARTE · TROY · 2009-2010"
	match _step:
		STEP_DETECT:
			_status.text = "1 / 3 · LAS RUEDAS GIRAN, ¿Y AHORA?"
			_description.text = "La maqueta muestra patinaje intenso y avance mínimo.\n\n%s ACELERAR MÁS SIN MEDIR\n%s DETENERSE Y COMPROBAR DESLIZAMIENTO\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_ASSESS:
			_status.text = "2 / 3 · EVALUAR ANTES DE MOVER"
			_description.text = "Spirit quedó atrapado en Troy en 2009. Sus ingenieros investigaron suelo, ruedas y orientación.\n\n%s FORZAR LOS MOTORES\n%s MEDIR HUNDIMIENTO, INCLINACIÓN Y ENERGÍA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_DECIDE:
			_status.text = "3 / 3 · ¿CÓMO CONTINUÓ SU MISIÓN?"
			_description.text = "Los intentos reales de rescate no liberaron a Spirit. En enero de 2010 la NASA lo convirtió en plataforma científica estacionaria.\n\n%s DECIR QUE SPIRIT ESCAPÓ DE TROY\n%s PRIORIZAR CIENCIA ESTACIONARIA Y ENERGÍA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_FINISHED:
			_status.text = "DESCUBRIMIENTO · ADAPTARSE AL LÍMITE"
			_description.text = "Spirit exploró Marte desde 2004. En Troy quedó atrapado en 2009; se convirtió en estación científica en 2010. La última comunicación fue el 22 de marzo de 2010. Su vehículo quedó en Marte.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Spirit · Rover", "Exploración de Marte · Troy, 2009-2010",
			"Spirit quedó atrapado en suelo blando de Troy en 2009. No logró liberarse; NASA lo convirtió en una plataforma científica estacionaria en enero de 2010. Enseña a medir, detenerse y replantear objetivos.")


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
	body.name = "RiskControlStation"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.20, 1.00, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.29, 0.32, 0.34)
	geometry.material = material
	body.mesh = geometry
	body.position.y = 0.50
	add_child(body)
	var screen := MeshInstance3D.new()
	screen.name = "WheelSlipMonitor"
	var monitor := BoxMesh.new()
	monitor.size = Vector3(0.94, 0.44, 0.03)
	var monitor_mat := StandardMaterial3D.new()
	monitor_mat.albedo_color = Color(0.07, 0.16, 0.19)
	monitor_mat.emission_enabled = true
	monitor_mat.emission = Color(0.05, 0.16, 0.17)
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
	canvas.name = "SpiritHUD"
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
