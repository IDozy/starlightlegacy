extends StaticBody3D
## Perseverance Valley, Opportunity (2018). Simulación educativa, no telemetría real.
## Opportunity dejó de transmitir en 2018; no inventar que despertó.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "opportunity"
const STEP_LIGHT := 0
const STEP_BUDGET := 1
const STEP_HISTORY := 2
const STEP_FINISHED := 3

var _rover: Node3D = null
var _player: Node = null
var _active := false
var _complete := false
var _step := STEP_LIGHT
var _choice := 0
var _light_observed := false
var _power_budget_protected := false
var _history_respected := false
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
	return "E · Revisar historia de Opportunity" if _complete else "E · Medir energía de Opportunity"


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
		STEP_LIGHT:
			_confirm_light()
		STEP_BUDGET:
			_confirm_budget()
		STEP_HISTORY:
			_confirm_history()
		STEP_FINISHED:
			var show_archive := _choice == 1
			_close()
			if show_archive:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_light() -> void:
	if _choice != 1:
		_feedback = "Orientar un panel no despeja una tormenta atmosférica. Antes hay que medir la iluminación."
		_show()
		return
	if _rover == null or not _rover.has_method("observe_low_light"):
		_feedback = "Falta el rover del recuerdo para medir la luz."
		_show()
		return
	_rover.call("observe_low_light")
	_light_observed = true
	_step = STEP_BUDGET
	_choice = 0
	_feedback = "La tormenta redujo la luz para los paneles. Ahora revisa el consumo disponible."
	_show()


func _confirm_budget() -> void:
	if not _light_observed:
		return
	if _choice != 1:
		_feedback = "Con poca luz, mantener motor, cámara y radio activos puede agotar la batería."
		_show()
		return
	_power_budget_protected = true
	_step = STEP_HISTORY
	_choice = 0
	_feedback = "En el rover escolar suspendemos tareas no esenciales; no es una orden histórica de Opportunity."
	_show()


func _confirm_history() -> void:
	if not _light_observed or not _power_budget_protected:
		return
	if _choice != 1:
		_feedback = "Opportunity no volvió a comunicarse después del 10 de junio de 2018."
		_show()
		return
	if _rover == null or not _rover.has_method("protect_power_budget"):
		_feedback = "El módulo de ahorro no está disponible."
		_show()
		return
	_rover.call("protect_power_budget")
	_history_respected = true
	_complete = true
	_step = STEP_FINISHED
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "OPPORTUNITY · PERSEVERANCE VALLEY · MARTE · 2018"
	match _step:
		STEP_LIGHT:
			_status.text = "1 / 3 · ¿CUÁNTA LUZ SOLAR LLEGA?"
			_description.text = "La maqueta muestra una tormenta que oscurece el cielo y reduce la luz disponible.\n\n%s SOLO REORIENTAR EL PANEL\n%s MEDIR LA LUZ RECIBIDA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_BUDGET:
			_status.text = "2 / 3 · CONSERVAR LA RESERVA"
			_description.text = "El panel funciona, pero entra poca luz para recargar. Esta decisión es una simulación de feria.\n\n%s MANTENER TODAS LAS ACTIVIDADES\n%s SUSPENDER CARGAS NO ESENCIALES\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_HISTORY:
			_status.text = "3 / 3 · ¿QUÉ OCURRIÓ REALMENTE?"
			_description.text = "La última comunicación de Opportunity fue el 10 de junio de 2018; NASA declaró terminada su misión el 13 de febrero de 2019.\n\n%s AFIRMAR QUE OPPORTUNITY DESPERTÓ\n%s RECONOCER EL FINAL REAL DE LA MISIÓN\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_FINISHED:
			_status.text = "DESCUBRIMIENTO · ENERGÍA Y PERSEVERANCIA"
			_description.text = "Opportunity llegó a Marte en 2004 y recorrió más de 45 kilómetros. Perdió contacto durante la tormenta de 2018. La misión terminó en febrero de 2019. El rover quedó en Marte.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Opportunity · Rover", "Exploración de Marte · 2004-2018",
			"Opportunity fue un rover solar gemelo de Spirit. Tras más de 45 km, su última comunicación llegó el 10 de junio de 2018 durante una tormenta de polvo. NASA declaró terminada la misión en 2019.")


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
	body.name = "PowerBudgetStation"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.20, 1.00, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.29, 0.32, 0.34)
	geometry.material = material
	body.mesh = geometry
	body.position.y = 0.50
	add_child(body)
	var screen := MeshInstance3D.new()
	screen.name = "SolarLightMonitor"
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
	canvas.name = "OpportunityHUD"
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
