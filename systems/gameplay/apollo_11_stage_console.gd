extends StaticBody3D
## Apollo 11, Eagle, 1969. Simulador didactico de dos etapas:
## etapa inferior permanece en la Luna; superior despega de ella.
## Opciones, tiempos y controles NO son procedimientos reales de NASA.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "apollo_11_descent_stage"
const STAGE_IDENTIFY := 0
const STAGE_SUPPORT := 1
const STAGE_RELEASE := 2
const STAGE_ASCENT := 3
const STAGE_SUCCESS := 4

var _lander: Node3D = null
var _player: Node = null
var _stage := STAGE_IDENTIFY
var _selection := 0
var _success_selection := 0
var _support_checked := false
var _released := false
var _completed := false
var _active := false
var _feedback := ""
var _started_frame := -1

var _panel: ColorRect
var _title: Label
var _status: Label
var _description: Label
var _hint: Label


func _ready() -> void:
	_completed = _has_discovery(DISCOVERY_ID)
	if _completed:
		_stage = STAGE_SUCCESS
	_build_visuals()
	_build_hud()


func connect_lander(lander: Node3D) -> void:
	_lander = lander


func get_interaction_prompt() -> String:
	return "E · Revisar historia del Eagle" if _completed else "E · Estudiar las etapas del Eagle"


func interact(player: Node) -> void:
	if _active or player == null:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if player.has_method("set_control_locked"):
		player.call("set_control_locked", true)
	_panel.visible = true
	if _completed:
		_stage = STAGE_SUCCESS
		_success_selection = 0
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
		if _stage == STAGE_SUCCESS:
			_success_selection = 1 - _success_selection
		else:
			_selection = 1 - _selection
		_feedback = ""
		_show()
		get_viewport().set_input_as_handled()
		return
	var confirm := INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)
	if not confirm:
		return
	match _stage:
		STAGE_IDENTIFY:
			_confirm_identification()
		STAGE_SUPPORT:
			_confirm_support()
		STAGE_RELEASE:
			_confirm_release()
		STAGE_ASCENT:
			_confirm_ascent()
		STAGE_SUCCESS:
			var details := _success_selection == 1
			_close()
			if details:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_identification() -> void:
	# Opcion 0: descenso fijo; opcion 1: ascenso fijo (incorrecto).
	if _selection != 0:
		_feedback = "La parte superior transportó a Armstrong y Aldrin de regreso a la órbita. No fue la que permaneció en la Luna."
		_show()
		return
	_stage = STAGE_SUPPORT
	_selection = 1
	_feedback = "Correcto: la etapa inferior sería la plataforma de despegue."
	_show()


func _confirm_support() -> void:
	# Opcion 1: plataforma estable y preparada; 0: retirar patas antes.
	if _selection != 1:
		_feedback = "Las cuatro patas mantienen estable la plataforma inferior. No deben retirarse antes del despegue."
		_show()
		return
	_support_checked = true
	_stage = STAGE_RELEASE
	_selection = 1
	_feedback = "Plataforma revisada. Ahora distingue la función de las dos etapas."
	_show()


func _confirm_release() -> void:
	if not _support_checked:
		return
	# Opcion 1: separar las etapas; 0: intentar elevar todo.
	if _selection != 1:
		_feedback = "La etapa de descenso ya cumplió su función. No hacía falta llevarla al espacio."
		_show()
		return
	_released = true
	_stage = STAGE_ASCENT
	_feedback = "Preparado: la etapa superior puede despegar dejando la plataforma debajo."
	_show()


func _confirm_ascent() -> void:
	if not _released or not _support_checked:
		return
	if _lander == null or not _lander.has_method("launch_ascent_preview"):
		_feedback = "No se encuentra el modelo provisional: no puede completarse el ejercicio."
		_show()
		return
	var launch_ok: bool = bool(_lander.call("launch_ascent_preview"))
	if not launch_ok:
		_feedback = "La simulación no pudo separar las etapas."
		_show()
		return
	_completed = true
	_stage = STAGE_SUCCESS
	_success_selection = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "APOLLO 11 · EAGLE · 1969"
	match _stage:
		STAGE_IDENTIFY:
			_status.text = "1 / 4 · ¿QUÉ QUEDÓ EN LA LUNA?"
			_description.text = "El Eagle tenía una etapa de descenso y una etapa de ascenso.\n\n%s ETAPA DE DESCENSO · patas y plataforma\n%s ETAPA DE ASCENSO · cabina" % [
				"▶" if _selection == 0 else " ",
				"▶" if _selection == 1 else " "
			] + "\n\n" + _feedback
		STAGE_SUPPORT:
			_status.text = "2 / 4 · PREPARAR LA PLATAFORMA"
			_description.text = "Para despegar desde la Luna, la etapa inferior sirvió como base.\n\n%s RETIRAR PRIMERO LAS PATAS\n%s CONSERVAR LA PLATAFORMA ESTABLE" % [
				"▶" if _selection == 0 else " ", "▶" if _selection == 1 else " "
			] + "\n\n" + _feedback
		STAGE_RELEASE:
			_status.text = "3 / 4 · ELEGIR QUÉ DESPEGA"
			_description.text = "La etapa inferior ya terminó la función de aterrizar.\n\n%s LLEVAR LAS DOS ETAPAS\n%s SEPARAR Y UTILIZAR SOLO LA ETAPA SUPERIOR" % [
				"▶" if _selection == 0 else " ", "▶" if _selection == 1 else " "
			] + "\n\n" + _feedback
		STAGE_ASCENT:
			_status.text = "4 / 4 · DESPEGUE DIDÁCTICO"
			_description.text = "En la misión real, la etapa superior despegó desde la inferior el 21 de julio de 1969.\n\nPulsa E para ver una animación simplificada, no una reconstrucción de velocidad o trayectoria.\n\n" + _feedback
		STAGE_SUCCESS:
			_status.text = "DESCUBRIMIENTO · ETAPA DE DESCENSO"
			_description.text = "La etapa de descenso quedó en el Mar de la Tranquilidad como plataforma de lanzamiento. La etapa superior llevó a los dos astronautas hacia la órbita para reunirse con Columbia.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _success_selection == 0 else " ",
				"▶" if _success_selection == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Etapa de descenso · Apollo 11", "Hardware lunar · 1969",
			"El Eagle alunizó el 20 de julio de 1969. Su etapa de ascenso despegó al día siguiente usando la etapa de descenso como plataforma, que quedó en el Mar de la Tranquilidad.")


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_visuals() -> void:
	var body := MeshInstance3D.new()
	body.name = "ControlConsole"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.25, 0.99, 0.75)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.19, 0.24, 0.31)
	mat.roughness = 0.69
	mesh.material = mat
	body.mesh = mesh
	body.position.y = 0.50
	add_child(body)
	var display := MeshInstance3D.new()
	display.name = "ConsoleScreen"
	var plate := BoxMesh.new()
	plate.size = Vector3(0.98, 0.46, 0.03)
	var display_mat := StandardMaterial3D.new()
	display_mat.albedo_color = Color(0.04, 0.14, 0.20)
	display_mat.emission_enabled = true
	display_mat.emission = Color(0.02, 0.12, 0.18)
	plate.material = display_mat
	display.mesh = plate
	display.position = Vector3(0, 0.68, 0.39)
	add_child(display)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.25, 1.01, 0.76)
	collision.position.y = 0.50
	collision.shape = shape
	add_child(collision)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SeparationHUD"
	canvas.layer = 76
	add_child(canvas)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.20
	_panel.anchor_top = 0.17
	_panel.anchor_right = 0.80
	_panel.anchor_bottom = 0.83
	_panel.color = Color(0.028, 0.041, 0.055, 0.98)
	canvas.add_child(_panel)
	_title = _label("Title", 0.06, 0.055, 0.94, 0.15, 22, Color(0.94, 0.78, 0.44))
	_status = _label("Status", 0.07, 0.19, 0.93, 0.32, 20, Color(0.46, 0.87, 0.90))
	_description = _label("Description", 0.08, 0.35, 0.92, 0.80, 17, Color(0.91, 0.93, 0.96))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _label("Hint", 0.04, 0.87, 0.96, 0.97, 14, Color(0.76, 0.82, 0.86))


func _label(label_name: String, left: float, top: float, right: float,
	bottom: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.anchor_left = left
	label.anchor_top = top
	label.anchor_right = right
	label.anchor_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_panel.add_child(label)
	return label
