extends StaticBody3D
## Saber más: InSight. La feria NO depende de esta actividad.
## Los registros son historias NASA; no genera mediciones de vuelo.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "insight"
const STEP_PLACE := 0
const STEP_NOISE := 1
const STEP_HISTORY := 2
const STEP_COMPLETE := 3

var _lander: Node3D = null
var _player: Node = null
var _active := false
var _step := STEP_PLACE
var _choice := 0
var _placed := false
var _noise_checked := false
var _feedback := ""
var _started_frame := -1
var _panel: ColorRect
var _title: Label
var _status: Label
var _body: Label
var _hint: Label


func _ready() -> void:
	if _has_discovery(DISCOVERY_ID):
		_step = STEP_COMPLETE
	_build_station()
	_build_hud()


func connect_lander(lander: Node3D) -> void:
	_lander = lander


func get_interaction_prompt() -> String:
	return "E · Revisar InSight" if _has_discovery(DISCOVERY_ID) else "E · Saber más: escuchar Marte"


func interact(player: Node) -> void:
	if player == null or _active:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_panel.visible = true
	_step = STEP_COMPLETE if _has_discovery(DISCOVERY_ID) else _step
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return
	if not event.pressed or event.echo or Engine.get_process_frames() == _started_frame:
		return
	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close()
		get_viewport().set_input_as_handled()
		return
	if INPUT_COMPAT.key_matches(event, KEY_A) or INPUT_COMPAT.key_matches(event, KEY_LEFT) or INPUT_COMPAT.key_matches(event, KEY_D) or INPUT_COMPAT.key_matches(event, KEY_RIGHT):
		_choice = 1 - _choice
		_feedback = ""
		_show()
		get_viewport().set_input_as_handled()
		return
	if not (INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)):
		return
	match _step:
		STEP_PLACE:
			_confirm_placement()
		STEP_NOISE:
			_confirm_noise()
		STEP_HISTORY:
			_confirm_history()
		STEP_COMPLETE:
			var archive := _choice == 1
			_close()
			if archive:
				var ui := get_node_or_null("/root/KnowledgeUI")
				if ui != null and ui.has_method("open_archive"):
					ui.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_placement() -> void:
	if _step != STEP_PLACE:
		return
	if _choice != 1:
		_feedback = "InSight colocó SEIS sobre el suelo con su brazo robótico, no flotando en la nave."
		_show()
		return
	if _lander == null or not _lander.has_method("place_seismometer") or not bool(_lander.call("place_seismometer")):
		_feedback = "El instrumento no pudo colocarse."
		_show()
		return
	_placed = true
	_advance(STEP_NOISE, "Seis colocado en la superficie. Ahora revisa perturbaciones.")


func _confirm_noise() -> void:
	if _step != STEP_NOISE or not _placed:
		return
	if _choice != 1:
		_feedback = "El viento y las temperaturas variables pueden producir ruido: hay que proteger y analizar."
		_show()
		return
	if _lander == null or not _lander.has_method("check_environmental_noise") or not bool(_lander.call("check_environmental_noise")):
		_feedback = "El protector no está disponible."
		_show()
		return
	_noise_checked = true
	_advance(STEP_HISTORY, "La protección ayuda a distinguir vibraciones y ruido ambiental.")


func _confirm_history() -> void:
	if _step != STEP_HISTORY or not _placed or not _noise_checked:
		return
	if _choice != 1:
		_feedback = "InSight no se recuperó después de 2022. Su energía solar descendió con el polvo."
		_show()
		return
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("unlock_catalog_discovery"):
		_feedback = "Archivo NASA no disponible."
		_show()
		return
	if not bool(registry.call("unlock_catalog_discovery", DISCOVERY_ID)) and not _has_discovery(DISCOVERY_ID):
		_feedback = "No se pudo registrar InSight."
		_show()
		return
	_step = STEP_COMPLETE
	_choice = 0
	challenge_completed.emit()
	_show()


func _advance(next_step: int, message: String) -> void:
	_step = next_step
	_choice = 0
	_feedback = message
	_show()


func _show() -> void:
	_title.text = "SABER MÁS · INSIGHT · ELYSIUM PLANITIA · 2018–2022"
	match _step:
		STEP_PLACE:
			_status.text = "1 / 3 · UN INSTRUMENTO EN EL SUELO"
			_body.text = "InSight aterrizó en noviembre de 2018 y utilizó un brazo robótico para colocar su sismómetro SEIS.\n\n%s DEJAR EL SENSOR SUELTO SOBRE LA NAVE\n%s COLOCAR SEIS DIRECTAMENTE EN LA SUPERFICIE\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_NOISE:
			_status.text = "2 / 3 · DETECTAR SEÑALES REALES"
			_body.text = "Para escuchar Marte, SEIS debía distinguir vibraciones de ruido debido al viento y a cambios de temperatura.\n\n%s TRATAR TODO RUIDO COMO UN MARTEMOTO\n%s PROTEGER EL SENSOR Y VERIFICAR LAS SEÑALES\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_HISTORY:
			_status.text = "3 / 3 · ¿QUÉ QUEDÓ ATRÁS?"
			_body.text = "InSight detectó 1.319 sismos marcianos. NASA concluyó la misión en diciembre de 2022, cuando su energía solar se agotó.\n\n%s DECIR QUE VOLVIÓ A COMUNICARSE EN 2023\n%s RECONOCER EL LEGADO CIENTÍFICO DE 2018–2022\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_COMPLETE:
			_status.text = "¡ARTÍCULO OPCIONAL RECUPERADO!"
			_body.text = "El sismómetro SEIS estudió la corteza, el manto y el núcleo de Marte. InSight quedó en Elysium Planitia cuando NASA dio por terminada la misión el 21 de diciembre de 2022.\n\n%s CONTINUAR · REGRESAR A LA FERIA\n%s SABER MÁS · ARCHIVO NASA" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "]
	_hint.text = "A / D · Elegir    E / Enter · Confirmar    Esc · Salir"


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
	body.name = "SEISListeningConsole"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.25, 0.92, 0.78)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.28, 0.33)
	mesh.material = mat
	body.mesh = mesh
	body.position.y = 0.46
	add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.28, 0.96, 0.81)
	collider.shape = shape
	collider.position.y = 0.48
	add_child(collider)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "InSightHUD"
	canvas.layer = 76
	add_child(canvas)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.20
	_panel.anchor_top = 0.15
	_panel.anchor_right = 0.80
	_panel.anchor_bottom = 0.85
	_panel.color = Color(0.027, 0.041, 0.055, 0.98)
	canvas.add_child(_panel)
	_title = _make_label("Title", 0.04, 0.04, 0.96, 0.13, 20, Color(0.96, 0.80, 0.44))
	_status = _make_label("Status", 0.06, 0.17, 0.94, 0.28, 20, Color(0.50, 0.88, 0.87))
	_body = _make_label("Body", 0.07, 0.31, 0.93, 0.86, 17, Color(0.91, 0.94, 0.97))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _make_label("Hint", 0.03, 0.88, 0.97, 0.97, 14, Color(0.76, 0.82, 0.86))


func _make_label(name: String, left: float, top: float, right: float,
	bottom: float, size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = name
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
