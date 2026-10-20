extends StaticBody3D
## Unica consola interactiva del recuerdo Vanguard 1.
## Comparacion didactica de energia: NO es telemetria historica.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "vanguard_1"
const MODE_BATTERY := 0
const MODE_SOLAR := 1
const STAGE_SELECT := 0
const STAGE_RUNNING := 1
const STAGE_FAILURE := 2
const STAGE_SUCCESS := 3
const SUNLIGHT := [true, true, false, true]
const CONSUMPTION := 35
const SOLAR_INPUT := 26
const SAVING_CONSUMPTION := 27

var _player: Node = null
var _active := false
var _complete := false
var _battery_tested := false
var _mode := MODE_BATTERY
var _stage := STAGE_SELECT
var _step := 0
var _energy := 100
var _choice := 0
var _started_frame := -1

var _layer: CanvasLayer
var _panel: ColorRect
var _title: Label
var _status: Label
var _description: Label
var _controls: Label


func _ready() -> void:
	_complete = _has_discovery(DISCOVERY_ID)
	_build_visuals()
	_build_panel()


func get_interaction_prompt() -> String:
	return "E · Revisar energia de Vanguard 1" if _complete else "E · Simular energia de Vanguard 1"


func interact(player: Node) -> void:
	if _active or player == null:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_panel.visible = true
	if _complete:
		_stage = STAGE_SUCCESS
		_choice = 0
	else:
		_stage = STAGE_SELECT
		_mode = MODE_BATTERY
		_step = 0
		_energy = 100
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey) or not event.pressed or event.echo:
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
	if _stage == STAGE_SELECT and (left or right):
		if _battery_tested:
			_mode = MODE_SOLAR if _mode == MODE_BATTERY else MODE_BATTERY
			_show()
		get_viewport().set_input_as_handled()
		return
	if _stage == STAGE_SUCCESS and (left or right):
		_choice = 1 - _choice
		_show()
		get_viewport().set_input_as_handled()
		return
	if not confirm:
		return
	match _stage:
		STAGE_SELECT:
			_start_test()
		STAGE_RUNNING:
			_advance_test()
		STAGE_FAILURE:
			_mode = MODE_SOLAR
			_stage = STAGE_SELECT
			_show()
		STAGE_SUCCESS:
			var wants_archive := _choice == 1
			_close()
			if wants_archive:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _start_test() -> void:
	_step = 0
	_energy = 100
	_stage = STAGE_RUNNING
	_show()


func _advance_test() -> void:
	var is_sunlit: bool = SUNLIGHT[_step]
	if _mode == MODE_BATTERY:
		_energy -= CONSUMPTION
	else:
		_energy -= SAVING_CONSUMPTION
		if is_sunlit:
			_energy += SOLAR_INPUT
	_energy = mini(_energy, 100)
	_step += 1
	if _energy <= 0:
		_energy = 0
		_battery_tested = true
		_stage = STAGE_FAILURE
	elif _step >= SUNLIGHT.size():
		if _mode == MODE_SOLAR:
			_complete = true
			_stage = STAGE_SUCCESS
			_choice = 0
			_register_discovery()
			challenge_completed.emit()
		else:
			_battery_tested = true
			_stage = STAGE_FAILURE
	_show()


func _show() -> void:
	_title.text = "VANGUARD 1 · 1958 · ENERGIA EN ORBITA"
	match _stage:
		STAGE_SELECT:
			_status.text = "DISENO DE PRUEBA · %s" % ("BATERIA SOLA" if _mode == MODE_BATTERY else "CELULAS SOLARES + AHORRO")
			_description.text = "Simulacion educativa (valores inventados para el juego).\nElige el sistema de energia y observa el efecto de la sombra terrestre.\nNo representa telemetria historica del satelite."
			_controls.text = "A / D · Elegir (tras fallo inicial)     E · Iniciar     Esc · Salir"
		STAGE_RUNNING:
			var illumination := "LUZ SOLAR" if SUNLIGHT[_step] else "SOMBRA DE LA TIERRA"
			_status.text = "TURNO %d / 4 · %s" % [_step + 1, illumination]
			_description.text = "Carga disponible: %d %%\nSistema: %s\nLa celula solar solo aporta energia cuando recibe luz." % [
				_energy, "BATERIA" if _mode == MODE_BATTERY else "SOLAR + AHORRO"
			]
			_controls.text = "E · Continuar simulacion     Esc · Salir"
		STAGE_FAILURE:
			_status.text = "FALLO · TRANSMISION INTERRUMPIDA"
			_description.text = "La reserva electrica se agoto. Vanguard 1 empleaba celulas solares ademas de sus baterias.\nPrueba ahora el apoyo solar con consumo reducido."
			_controls.text = "E · Probar otra configuracion     Esc · Salir"
		STAGE_SUCCESS:
			_status.text = "EXITO · ENERGIA ADMINISTRADA"
			_description.text = "La simulacion conserva %d %% de carga.\nLa luz puede producir electricidad; en sombra, la bateria sigue siendo necesaria.\n\n%s CONTINUAR\n%s SABER MAS · Historia / Ingenieria / Tu proyecto" % [
				_energy,
				"▶" if _choice == 0 else " ",
				"▶" if _choice == 1 else " "
			]
			_controls.text = "A / D · Elegir     E · Confirmar     Esc · Cerrar"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID, "Vanguard 1",
			"Satélite de 1958 · Programa Vanguard",
			"Vanguard 1 fue lanzado el 17 de marzo de 1958 por un programa estadounidense anterior a NASA. Sus celulas solares prolongaron el trabajo de su transmisor. La practica de carga del recuerdo es una analogia educativa.")


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_visuals() -> void:
	var console := MeshInstance3D.new()
	console.name = "EnergyConsoleCase"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.15, 1.02, 0.72)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.27, 0.34)
	mat.roughness = 0.65
	mesh.material = mat
	console.mesh = mesh
	console.position.y = 0.52
	add_child(console)

	var screen := MeshInstance3D.new()
	screen.name = "EnergyReadout"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.91, 0.47, 0.03)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.06, 0.23, 0.28)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.035, 0.18, 0.19)
	panel_mesh.material = screen_mat
	screen.mesh = panel_mesh
	screen.position = Vector3(0, 0.72, 0.38)
	add_child(screen)

	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.16, 1.04, 0.75)
	collider.position.y = 0.52
	collider.shape = shape
	add_child(collider)


func _build_panel() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "EnergyHUD"
	_layer.layer = 76
	add_child(_layer)

	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.22
	_panel.anchor_top = 0.17
	_panel.anchor_right = 0.78
	_panel.anchor_bottom = 0.83
	_panel.color = Color(0.025, 0.045, 0.06, 0.97)
	_layer.add_child(_panel)

	_title = _label("Title", 0.07, 0.07, 0.93, 0.15, 21, Color(0.92, 0.77, 0.43))
	_status = _label("Status", 0.07, 0.20, 0.93, 0.31, 19, Color(0.40, 0.84, 0.90))
	_description = _label("Description", 0.08, 0.35, 0.92, 0.78, 18, Color(0.92, 0.94, 0.96))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls = _label("Controls", 0.04, 0.88, 0.96, 0.98, 14, Color(0.75, 0.80, 0.84))


func _label(label_name: String, left: float, top: float, right: float, bottom: float,
	size: int, tint: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.anchor_left = left
	label.anchor_top = top
	label.anchor_right = right
	label.anchor_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	_panel.add_child(label)
	return label
