extends StaticBody3D
## Surveyor 1 (1966). Puesto de comandos EDUCATIVO que representa ordenes
## enviadas desde Tierra. Angulos y evaluacion = mecanica ficticia.
## El original recibia ordenes; NO poseia sensores autonomos de este minijuego.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "surveyor_1"
const STAGE_PANEL := 0
const STAGE_CAMERA := 1
const STAGE_TRANSMIT := 2
const STAGE_COMPLETED := 3
const PANEL_DEGREES := [-30, 0, 30]
const CAMERA_DEGREES := [-30, 0, 30]
const TARGET_PANEL := 2
const TARGET_CAMERA := 0

var _player: Node = null
var _active := false
var _completed := false
var _stage := STAGE_PANEL
var _panel_choice := 1
var _camera_choice := 1
var _panel_aligned := false
var _camera_aligned := false
var _image_received := false
var _choice := 0
var _feedback := ""
var _started_frame := -1
var _lander: Node3D = null
var _panel: ColorRect
var _title: Label
var _status: Label
var _description: Label
var _hint: Label


func _ready() -> void:
	_completed = _has_discovery(DISCOVERY_ID)
	_build_console()
	_build_hud()
	if _completed:
		_stage = STAGE_COMPLETED


func connect_lander(lander: Node3D) -> void:
	_lander = lander
	_update_preview()


func get_interaction_prompt() -> String:
	if _completed:
		return "E · Revisar comandos de Surveyor 1"
	return "E · Enviar comandos a Surveyor 1"


func interact(player: Node) -> void:
	if _active or player == null:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	if _completed:
		_stage = STAGE_COMPLETED
		_choice = 0
	_panel.visible = true
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
	var confirm := INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)

	if left or right:
		var offset: int = -1 if left else 1
		match _stage:
			STAGE_PANEL:
				_panel_choice = clampi(_panel_choice + offset, 0, 2)
			STAGE_CAMERA:
				_camera_choice = clampi(_camera_choice + offset, 0, 2)
			STAGE_COMPLETED:
				_choice = 1 - _choice
		_feedback = ""
		_update_preview()
		_show()
		get_viewport().set_input_as_handled()
		return

	if not confirm:
		return
	match _stage:
		STAGE_PANEL:
			_confirm_panel_command()
		STAGE_CAMERA:
			_confirm_camera_command()
		STAGE_TRANSMIT:
			_confirm_image_command()
		STAGE_COMPLETED:
			var open_details := _choice == 1
			_close()
			if open_details:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_panel_command() -> void:
	if _panel_choice != TARGET_PANEL:
		_feedback = "La fuente de luz simulada no ilumina suficiente el panel. Prueba otra orden."
	else:
		_panel_aligned = true
		_stage = STAGE_CAMERA
		_feedback = "Orden recibida: panel orientado. Ahora dirige la cámara a una roca."
	_show()


func _confirm_camera_command() -> void:
	if not _panel_aligned:
		return
	if _camera_choice != TARGET_CAMERA:
		_feedback = "La cámara todavía no apunta a la roca señalada a la izquierda."
	else:
		_camera_aligned = true
		_stage = STAGE_TRANSMIT
		_feedback = "Cámara orientada. Envía la orden de transmitir una imagen."
	_show()


func _confirm_image_command() -> void:
	if not _panel_aligned or not _camera_aligned:
		return
	_image_received = true
	_completed = true
	_stage = STAGE_COMPLETED
	_choice = 0
	_feedback = "Imagen reconstruida recibida en Tierra. El desafío ha terminado."
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "SURVEYOR 1 · 1966 · OCEANUS PROCELLARUM"
	match _stage:
		STAGE_PANEL:
			_status.text = "1 / 3 · ORIENTAR PANEL SOLAR"
			_description.text = "Envía una orden desde Tierra para orientar el panel hacia la luz.\nÁngulo simulado: %d°\nLa luz llega desde la derecha del panel.\n\n%s" % [
				int(PANEL_DEGREES[_panel_choice]), _feedback
			]
			_hint.text = "A / D · Cambiar ángulo    E · Enviar orden    Esc · Salir"
		STAGE_CAMERA:
			_status.text = "2 / 3 · ORIENTAR CÁMARA DE TV"
			_description.text = "El panel recibe luz. Ahora observa la roca marcada a la izquierda.\nÁngulo de cámara simulado: %d°\n\n%s" % [
				int(CAMERA_DEGREES[_camera_choice]), _feedback
			]
			_hint.text = "A / D · Girar cámara    E · Enviar orden    Esc · Salir"
		STAGE_TRANSMIT:
			_status.text = "3 / 3 · RECIBIR IMAGEN"
			_description.text = "La cámara está orientada. La misión real transmitió miles de imágenes por radio.\nEsta imagen será una reconstrucción educativa.\n\n%s" % _feedback
			_hint.text = "E · Transmitir imagen    Esc · Salir"
		STAGE_COMPLETED:
			_status.text = "DESCUBRIMIENTO RECUPERADO · SURVEYOR 1"
			_description.text = "En 1966 Surveyor 1 logró el primer alunizaje suave estadounidense y envió imágenes de la Luna.\nEn este ejercicio enviaste órdenes a la nave, orientaste su panel y su cámara.\n\n%s CONTINUAR\n%s SABER MÁS · Historia / Ingeniería / Tu proyecto" % [
				"▶" if _choice == 0 else " ",
				"▶" if _choice == 1 else " "
			]
			_hint.text = "A / D · Elegir    E · Confirmar    Esc · Cerrar"


func _update_preview() -> void:
	if _lander == null:
		return
	var solar := _lander.get_node_or_null("ArtifactModel/SolarPanelStaticPreview") as Node3D
	if solar != null:
		solar.rotation_degrees.x = 15.0 + float(PANEL_DEGREES[_panel_choice])
	var camera := _lander.get_node_or_null("ArtifactModel/TV_Camera") as Node3D
	if camera != null:
		camera.rotation_degrees.y = float(CAMERA_DEGREES[_camera_choice])


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery",
			DISCOVERY_ID, "Surveyor 1", "Aterrizador lunar · 1966",
			"Surveyor 1 alunizó suavemente en Oceanus Procellarum el 2 de junio de 1966 y transmitió 11.240 imágenes. Se orientaron panel y cámara con órdenes simuladas, no telemetría real.")


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_console() -> void:
	var casing := MeshInstance3D.new()
	casing.name = "EarthCommandTerminal"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.18, 0.98, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.37, 0.39, 0.40)
	material.roughness = 0.67
	mesh.material = material
	casing.mesh = mesh
	casing.position.y = 0.49
	add_child(casing)

	var display := MeshInstance3D.new()
	display.name = "CommandDisplay"
	var screen := BoxMesh.new()
	screen.size = Vector3(0.94, 0.45, 0.03)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.17, 0.23)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.02, 0.12, 0.16)
	screen.material = screen_mat
	display.mesh = screen
	display.position = Vector3(0, 0.68, 0.40)
	add_child(display)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.20, 1.0, 0.80)
	collision.position.y = 0.50
	collision.shape = shape
	add_child(collision)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CommandHUD"
	layer.layer = 76
	add_child(layer)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.22
	_panel.anchor_top = 0.17
	_panel.anchor_right = 0.78
	_panel.anchor_bottom = 0.83
	_panel.color = Color(0.035, 0.045, 0.059, 0.97)
	layer.add_child(_panel)
	_title = _make_label("Title", 0.07, 0.06, 0.93, 0.16, 20, Color(0.94, 0.78, 0.50))
	_status = _make_label("Status", 0.07, 0.20, 0.93, 0.32, 19, Color(0.54, 0.89, 0.91))
	_description = _make_label("Description", 0.09, 0.36, 0.91, 0.79, 18, Color(0.91, 0.94, 0.95))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _make_label("Hint", 0.04, 0.87, 0.96, 0.98, 14, Color(0.76, 0.79, 0.82))


func _make_label(label_name: String, left: float, top: float, right: float,
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
