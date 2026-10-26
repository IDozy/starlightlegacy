extends StaticBody3D
## Recuerdo Ingenuity 2021 y desenlace real 2024. Juego conceptual, NO piloto.
## No simula atmósfera, sustentación ni velocidades de vuelo auténticas.

signal challenge_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const DISCOVERY_ID := "ingenuity"
const STEP_AIR := 0
const STEP_ROTORS := 1
const STEP_SCOUT := 2
const STEP_FINISHED := 3

var _helicopter: Node3D = null
var _player: Node = null
var _active := false
var _complete := false
var _step := STEP_AIR
var _choice := 0
var _prepared := false
var _hovering := false
var _returned := false
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


func connect_helicopter(helicopter: Node3D) -> void:
	_helicopter = helicopter


func get_interaction_prompt() -> String:
	return "E · Revisar legado de Ingenuity" if _complete else "E · Preparar vuelo de Ingenuity"


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
		STEP_AIR:
			_confirm_air()
		STEP_ROTORS:
			_confirm_rotors()
		STEP_SCOUT:
			_confirm_scout()
		STEP_FINISHED:
			var show_archive := _choice == 1
			_close()
			if show_archive:
				var archive := get_node_or_null("/root/KnowledgeUI")
				if archive != null and archive.has_method("open_archive"):
					archive.call("open_archive", DISCOVERY_ID, 0)
	get_viewport().set_input_as_handled()


func _confirm_air() -> void:
	if _choice != 1:
		_feedback = "Marte tiene muy pocas moléculas de aire; una aeronave terrestre pesada no es una buena elección."
		_show()
		return
	if _helicopter == null or not _helicopter.has_method("prepare_for_thin_air"):
		_feedback = "Falta el modelo Ingenuity."
		_show()
		return
	if not bool(_helicopter.call("prepare_for_thin_air")):
		_feedback = "No se pudo preparar el helicóptero."
		_show()
		return
	_prepared = true
	_step = STEP_ROTORS
	_choice = 0
	_feedback = "Ingenuity era muy ligero y usaba rotores grandes que giraban a alta velocidad."
	_show()


func _confirm_rotors() -> void:
	if not _prepared:
		return
	if _choice != 1:
		_feedback = "Girar ambos rotores igual no compensa correctamente el par de reacción. Ingenuity tenía dos rotores coaxiales contrarrotativos."
		_show()
		return
	if _helicopter == null or not _helicopter.has_method("begin_controlled_hover"):
		_feedback = "El conjunto de rotores no está disponible."
		_show()
		return
	if not bool(_helicopter.call("begin_controlled_hover")):
		_feedback = "La maqueta no puede iniciar el vuelo de muestra."
		_show()
		return
	_hovering = true
	_step = STEP_SCOUT
	_choice = 0
	_feedback = "El 19 de abril de 2021 Ingenuity ascendió unos 3 metros y volvió a posarse tras su primer vuelo histórico."
	_show()


func _confirm_scout() -> void:
	if not _prepared or not _hovering:
		return
	if _choice != 1:
		_feedback = "La demostración inicial fue de vuelo controlado, no una travesía ilimitada. El vuelo final de 2024 dañó los rotores."
		_show()
		return
	if _helicopter == null or not _helicopter.has_method("complete_scout_and_land"):
		_feedback = "La secuencia de aterrizaje no está disponible."
		_show()
		return
	if not bool(_helicopter.call("complete_scout_and_land")):
		_feedback = "Primero completa el vuelo y regresa con seguridad."
		_show()
		return
	_returned = true
	_complete = true
	_step = STEP_FINISHED
	_choice = 0
	_register_discovery()
	challenge_completed.emit()
	_show()


func _show() -> void:
	_title.text = "INGENUITY · MARTE · 2021–2024"
	match _step:
		STEP_AIR:
			_status.text = "1 / 3 · ¿CÓMO VOLAR CON POCO AIRE?"
			_description.text = "La atmósfera superficial marciana ejerce cerca del 1%% de la presión de la terrestre.\n\n%s USAR UN HELICÓPTERO TERRESTRE MUY PESADO\n%s USAR UNA AERONAVE LIGERA Y ROTORES ADECUADOS\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_ROTORS:
			_status.text = "2 / 3 · CONTROLAR DOS ROTORES"
			_description.text = "Ingenuity utilizaba dos rotores coaxiales para producir sustentación y controlar el giro.\n\n%s HACERLOS GIRAR EN EL MISMO SENTIDO\n%s HACERLOS GIRAR EN SENTIDOS OPUESTOS\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_SCOUT:
			_status.text = "3 / 3 · ¿QUÉ PUEDE ENSEÑARNOS?"
			_description.text = "Su vuelo inicial demostró que era posible volar con control en Marte. Después ayudó a reconocer rutas para Perseverance.\n\n%s AFIRMAR QUE SIGUIÓ VOLANDO DESPUÉS DE 2024\n%s ATERRIZAR Y RECONOCER EL FIN REAL DE LA MISIÓN\n\n%s" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback
			]
		STEP_FINISHED:
			_status.text = "DESCUBRIMIENTO · PRIMER VUELO EN OTRO PLANETA"
			_description.text = "Primer vuelo: 19 de abril de 2021. Ingenuity completó 72 vuelos. El 18 de enero de 2024 sufrió daños en su último aterrizaje y NASA anunció el fin de misión el 25 de enero. La aeronave permanece en Marte.\n\n%s CONTINUAR\n%s SABER MÁS · Archivo NASA" % [
				"▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "
			]
	_hint.text = "A / D · Elegir    E · Confirmar    Esc · Salir"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null and registry.has_method("register_discovery"):
		registry.call("register_discovery", DISCOVERY_ID,
			"Ingenuity · Helicóptero", "Exploración aérea · Marte · 2021-2024",
			"Ingenuity fue el primer helicóptero en volar de forma controlada en otro planeta en abril de 2021. Tras 72 vuelos, su último vuelo de enero de 2024 dañó un rotor y la misión terminó. Permanece en Marte.")


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
	body.name = "FlightControlStation"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.20, 1.00, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.27, 0.31, 0.36)
	geometry.material = material
	body.mesh = geometry
	body.position.y = 0.50
	add_child(body)
	var screen := MeshInstance3D.new()
	screen.name = "FlightControlScreen"
	var monitor := BoxMesh.new()
	monitor.size = Vector3(0.94, 0.44, 0.03)
	var monitor_mat := StandardMaterial3D.new()
	monitor_mat.albedo_color = Color(0.08, 0.18, 0.22)
	monitor_mat.emission_enabled = true
	monitor_mat.emission = Color(0.05, 0.15, 0.18)
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
	canvas.name = "IngenuityHUD"
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
