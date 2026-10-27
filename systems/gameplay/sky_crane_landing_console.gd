extends StaticBody3D
## Recuerdo NASA/JPL Jezero, 2021. Orden didáctico, no comandos de vuelo.
## La etapa NO se separa del rover antes de detectar touchdown.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "perseverance_sky_crane"
const STEP_SITE := 0
const STEP_LOWER := 1
const STEP_SEPARATE := 2
const STEP_FINISHED := 3

var _rig: Node3D = null
var _player: Node = null
var _active := false
var _complete := false
var _step := STEP_SITE
var _choice := 0
var _safe_site := false
var _lowered := false
var _released := false
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


func connect_rig(rig: Node3D) -> void:
	_rig = rig


func get_interaction_prompt() -> String:
	return "E · Revisar Sky Crane en el Archivo" if _complete else "E · Controlar secuencia de aterrizaje"


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
		STEP_SITE:
			_confirm_site()
		STEP_LOWER:
			_confirm_lowering()
		STEP_SEPARATE:
			_confirm_separation()
		STEP_FINISHED:
			var archive_requested := _choice == 1
			_close()
			if archive_requested:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_site() -> void:
	if _choice != 1:
		_feedback = "No elijas un punto lleno de rocas. La navegación relativa al terreno ayudaba a localizar uno seguro."
		_show()
		return
	if _rig == null or not _rig.has_method("select_safe_site"):
		_feedback = "Falta el modelo de la maniobra."
		_show()
		return
	if not bool(_rig.call("select_safe_site")):
		_feedback = "No se pudo seleccionar el lugar seguro."
		_show()
		return
	_safe_site = true
	_step = STEP_LOWER
	_choice = 0
	_feedback = "Sitio seguro seleccionado. El descenso final lo realizó una etapa con motores."
	_show()


func _confirm_lowering() -> void:
	if not _safe_site:
		return
	if _choice != 1:
		_feedback = "Perseverance NO fue lanzado en caída libre. Descendió sostenido por cables."
		_show()
		return
	if _rig == null or not _rig.has_method("lower_rover_with_cables"):
		_feedback = "Falta el sistema de suspensión."
		_show()
		return
	if not bool(_rig.call("lower_rover_with_cables")):
		_feedback = "No se completó el descenso suspendido."
		_show()
		return
	_lowered = true
	_step = STEP_SEPARATE
	_choice = 0
	_feedback = "Ruedas desplegadas; hay que confirmar contacto antes de cortar los cables."
	_show()


func _confirm_separation() -> void:
	if not _safe_site or not _lowered:
		return
	if _choice != 1:
		_feedback = "Cortar cables ANTES de touchdown puede hacer caer el rover. Primero confirma apoyo."
		_show()
		return
	if _rig == null or not _rig.has_method("confirm_touchdown") or not _rig.has_method("cut_cables_and_fly_away"):
		_feedback = "Falta el detector de apoyo o la separación de cables."
		_show()
		return
	if not bool(_rig.call("confirm_touchdown")):
		_feedback = "No se ha confirmado contacto con el terreno."
		_show()
		return
	if not bool(_rig.call("cut_cables_and_fly_away")):
		_feedback = "El módulo de descenso no se pudo separar."
		_show()
		return
	_released = true
	_complete = true
	_step = STEP_FINISHED
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "PERSEVERANCE · SKY CRANE · JEZERO · 2021"
	match _step:
		STEP_SITE:
			_status.text = "1 / 3 · ¿DÓNDE ATERRIZAR?"
			_description.text = "En 2021, Perseverance usó navegación relativa al terreno durante su descenso a Jezero.\n\n%s IGNORAR LOS OBSTÁCULOS Y BAJAR\n%s IDENTIFICAR UNA ZONA SEGURA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_LOWER:
			_status.text = "2 / 3 · ¿CÓMO BAJAR EL ROVER?"
			_description.text = "La plataforma de descenso propulsada está sobre el terreno.\n\n%s SOLTAR EL ROVER EN CAÍDA LIBRE\n%s DESCENDERLO SUJETO POR CABLES\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_SEPARATE:
			_status.text = "3 / 3 · ¿CUÁNDO SEPARAR?"
			_description.text = "Perseverance se posó sobre sus ruedas. Solo tras detectar apoyo se cortaron las conexiones y la etapa se alejó.\n\n%s CORTAR CABLES ANTES DEL CONTACTO\n%s CONFIRMAR CONTACTO, CORTAR Y ALEJAR ETAPA\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_FINISHED:
			_status.text = "DESCUBRIMIENTO · ORDEN DE OPERACIONES"
			_description.text = "El 18 de febrero de 2021 Perseverance llegó a Jezero. Una etapa propulsada lo bajó mediante cables y se alejó tras el aterrizaje. La etapa de descenso acabó impactando lejos del rover, no quedó bajo él.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Sky Crane · Perseverance", "Descenso en Marte · Jezero · 2021",
			"Perseverance llegó a Jezero el 18 de febrero de 2021. Bajó suspendido de cables desde una etapa con motores. Solo después de confirmar el contacto se cortaron cables; la etapa salió volando e impactó a distancia.")


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_station() -> void:
	var body := MeshInstance3D.new()
	body.name = "SkyCraneFlightConsole"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.25, 1.02, 0.80)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.29, 0.33, 0.38)
	geometry.material = material
	body.mesh = geometry
	body.position.y = 0.51
	add_child(body)
	var screen := MeshInstance3D.new()
	screen.name = "TouchdownSequenceScreen"
	var monitor := BoxMesh.new()
	monitor.size = Vector3(0.96, 0.45, 0.04)
	var monitor_mat := StandardMaterial3D.new()
	monitor_mat.albedo_color = Color(0.07, 0.19, 0.17)
	monitor_mat.emission_enabled = true
	monitor_mat.emission = Color(0.03, 0.14, 0.12)
	monitor.material = monitor_mat
	screen.mesh = monitor
	screen.position = Vector3(0, 0.70, 0.42)
	add_child(screen)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.28, 1.05, 0.84)
	collision.shape = shape
	collision.position.y = 0.53
	add_child(collision)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SkyCraneHUD"
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
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_panel.add_child(label)
	return label
