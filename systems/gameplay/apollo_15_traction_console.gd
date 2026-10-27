extends StaticBody3D
## Apollo 15 LRV (1971), simulador EDUCATIVO de traccion y reparto de carga.
## Selecciones de materiales/terreno son analogias del juego, no datos
## de velocidad, coeficiente de rozamiento o telemetria del Apollo 15.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "apollo_15_lrv"
const STAGE_WHEELS := 0
const STAGE_LOAD := 1
const STAGE_DRIVE := 2
const STAGE_COMPLETE := 3

var _rover: Node3D
var _player: Node
var _active := false
var _completed := false
var _stage := STAGE_WHEELS
var _choice := 0
var _last_feedback := ""
var _wheels_checked := false
var _load_checked := false
var _travel_checked := false
var _started_frame := -1
var _panel: ColorRect
var _title: Label
var _status: Label
var _description: Label
var _hint: Label


func _ready() -> void:
	_completed = _has_discovery(DISCOVERY_ID)
	if _completed:
		_stage = STAGE_COMPLETE
	_build_console()
	_build_ui()


func connect_rover(rover: Node3D) -> void:
	_rover = rover


func get_interaction_prompt() -> String:
	return "E · Revisar Lunar Roving Vehicle" if _completed else "E · Probar la movilidad del LRV"


func interact(player: Node) -> void:
	if player == null or _active:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_panel.visible = true
	if _completed:
		_stage = STAGE_COMPLETE
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
		_last_feedback = ""
		_show()
		get_viewport().set_input_as_handled()
		return
	if not (INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)):
		return
	match _stage:
		STAGE_WHEELS:
			_confirm_wheels()
		STAGE_LOAD:
			_confirm_load()
		STAGE_DRIVE:
			_confirm_drive()
		STAGE_COMPLETE:
			var more := _choice == 1
			_close()
			if more:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_wheels() -> void:
	if _choice != 1:
		_last_feedback = "En Apollo 15 se utilizaron ruedas flexibles de malla metálica, no neumáticos inflados."
		_show()
		return
	_wheels_checked = true
	_stage = STAGE_LOAD
	_choice = 0
	_last_feedback = "¡Bien! Las ruedas del LRV combinaban malla y bandas de tracción."
	_show()


func _confirm_load() -> void:
	if not _wheels_checked:
		return
	if _choice != 1:
		_last_feedback = "Si cargas todo sobre una rueda, el vehículo pierde estabilidad. Reparte los equipos."
		_show()
		return
	_load_checked = true
	_stage = STAGE_DRIVE
	_choice = 0
	_last_feedback = "La carga se distribuye. Falta elegir cómo atravesar terreno suelto."
	_show()


func _confirm_drive() -> void:
	if not _load_checked or _rover == null or not _rover.has_method("preview_travel"):
		_last_feedback = "No se puede completar sin el modelo LRV."
		_show()
		return
	if _choice != 1:
		_last_feedback = "Sobre suelo irregular conviene controlar el movimiento y observar los obstáculos."
		_show()
		return
	_travel_checked = true
	_rover.call("preview_travel", 1.6)
	_completed = true
	_stage = STAGE_COMPLETE
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "APOLLO 15 · LUNAR ROVING VEHICLE · 1971"
	match _stage:
		STAGE_WHEELS:
			_status.text = "1 / 3 · ELEGIR RUEDAS"
			_description.text = "El LRV real utilizaba malla metálica flexible con bandas para aumentar la tracción.\n\n%s RUEDAS DE AIRE, LISAS\n%s MALLA METÁLICA + BANDAS DE TRACCIÓN\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _last_feedback
			]
		STAGE_LOAD:
			_status.text = "2 / 3 · REPARTIR EQUIPOS"
			_description.text = "El LRV llevaba astronautas, instrumentos y muestras. En esta maqueta escolar, ¿cómo colocas la carga?\n\n%s TODO EL PESO EN UNA ESQUINA\n%s REPARTIDO SOBRE EL CHASIS\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _last_feedback
			]
		STAGE_DRIVE:
			_status.text = "3 / 3 · CRUZAR SUELO IRREGULAR"
			_description.text = "Simulación educativa de movilidad, sin reproducir la conducción histórica.\n\n%s ACELERAR SIN MIRAR EL TERRENO\n%s AVANZAR CON CONTROL Y ELEGIR RUTA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _last_feedback
			]
		STAGE_COMPLETE:
			_status.text = "DESCUBRIMIENTO · PRIMER ROVER LUNAR TRIPULADO"
			_description.text = "Apollo 15 desplegó el primer Lunar Roving Vehicle usado en la Luna el 31 de julio de 1971. Era eléctrico, con cuatro ruedas de malla metálica y dos asientos.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Lunar Roving Vehicle · Apollo 15", "Vehículo lunar tripulado · 1971",
			"El LRV se usó por primera vez en la Luna el 31 de julio de 1971. Scott e Irwin lo condujeron durante Apollo 15; sus ruedas fueron de malla metálica y tenía propulsión eléctrica.")


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_console() -> void:
	var body := MeshInstance3D.new()
	body.name = "MobilityConsole"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.25, 0.98, 0.80)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.28, 0.32)
	mesh.material = mat
	body.mesh = mesh
	body.position.y = 0.49
	add_child(body)
	var display := MeshInstance3D.new()
	display.name = "ConsoleScreen"
	var screen := BoxMesh.new()
	screen.size = Vector3(1.00, 0.46, 0.03)
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.06, 0.17, 0.22)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.02, 0.12, 0.15)
	screen.material = s_mat
	display.mesh = screen
	display.position = Vector3(0.0, 0.69, 0.41)
	add_child(display)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.28, 1.00, 0.83)
	collision.shape = shape
	collision.position.y = 0.50
	add_child(collision)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobilityHUD"
	layer.layer = 76
	add_child(layer)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.20
	_panel.anchor_top = 0.17
	_panel.anchor_right = 0.80
	_panel.anchor_bottom = 0.83
	_panel.color = Color(0.024, 0.038, 0.051, 0.98)
	layer.add_child(_panel)
	_title = _label("Title", 0.06, 0.05, 0.94, 0.16, 21, Color(0.96, 0.79, 0.43))
	_status = _label("Status", 0.07, 0.19, 0.93, 0.32, 19, Color(0.48, 0.85, 0.89))
	_description = _label("Description", 0.08, 0.35, 0.92, 0.82, 17, Color(0.93, 0.94, 0.96))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _label("Hint", 0.05, 0.87, 0.95, 0.97, 14, Color(0.76, 0.82, 0.87))


func _label(label_name: String, left: float, top: float, right: float,
	bottom: float, size: int, color: Color) -> Label:
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
