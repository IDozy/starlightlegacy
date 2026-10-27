extends StaticBody3D
## Final del Capítulo I de Starlight Legacy, NO final de la saga.
## La feria es una prueba escolar; los objetos NASA históricos permanecen aparte.

signal exhibition_completed

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const FAIR_ID := "rescue_rover_science_fair_completed"
const IN_SIGHT_SCENE := "res://levels/insight/insight_memory.tscn"
const CHAPTER_TWO_TEASER := "res://levels/chapter_two_preview/chapter_two_preview.tscn"
const REQUIRED_UPGRADES := [
	"rescue_rover_airbag_upgrade",
	"rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade",
	"rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade",
	"rescue_rover_science_verification_upgrade",
	"rescue_rover_slip_guard_upgrade",
	"rescue_rover_power_budget_upgrade",
	"rescue_rover_touchdown_release_upgrade",
	"rescue_rover_aerial_scout_upgrade"
]
const STEP_SAFETY := 0
const STEP_POWER := 1
const STEP_DELIVERY := 2
const STEP_SCOUT := 3
const STEP_FINISHED := 4

var _player: Node = null
var _active := false
var _step := STEP_SAFETY
var _choice := 0
var _feedback := ""
var _started_frame := -1
var _panel: ColorRect
var _title: Label
var _status: Label
var _body: Label
var _hint: Label


func _ready() -> void:
	_build_station()
	_build_hud()
	if _has_discovery(FAIR_ID):
		_step = STEP_FINISHED


func missing_upgrades() -> Array[String]:
	var missing: Array[String] = []
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	for upgrade_id in REQUIRED_UPGRADES:
		if registry == null or not bool(registry.call("has_discovery", upgrade_id)):
			missing.append(upgrade_id)
	return missing


func is_ready_for_fair() -> bool:
	return missing_upgrades().is_empty()


func get_interaction_prompt() -> String:
	if _has_discovery(FAIR_ID):
		return "E · Capítulo I completado · Continuar / Saber más"
	return "E · Presentar el rover en la feria" if is_ready_for_fair() else "E · Feria: faltan mejoras"


func interact(player: Node) -> void:
	if player == null or _active:
		return
	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_panel.visible = true
	_step = STEP_FINISHED if _has_discovery(FAIR_ID) else _step
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
	if not is_ready_for_fair():
		_feedback = "Antes de concluir instala las mejoras que todavía faltan."
		_show()
		get_viewport().set_input_as_handled()
		return
	match _step:
		STEP_SAFETY:
			_confirm_safety()
		STEP_POWER:
			_confirm_power()
		STEP_DELIVERY:
			_confirm_delivery()
		STEP_SCOUT:
			_confirm_scout()
		STEP_FINISHED:
			var wants_more := _choice == 1
			_close()
			if wants_more:
				_go_to_optional_insight()
			else:
				_go_to_chapter_two_preview()
	get_viewport().set_input_as_handled()


func _confirm_safety() -> void:
	if not is_ready_for_fair() or _step != STEP_SAFETY:
		return
	if _choice != 1:
		_feedback = "Las ruedas no deben girar sin control. Usa tracción, protección y detección de patinaje."
		_show()
		return
	_advance(STEP_POWER, "Protección y control del terreno comprobados.")


func _confirm_power() -> void:
	if not is_ready_for_fair() or _step != STEP_POWER:
		return
	if _choice != 1:
		_feedback = "No hay energía infinita. Comprueba el panel, la luz disponible y las prioridades."
		_show()
		return
	_advance(STEP_DELIVERY, "Autonomía y protección eléctrica verificadas.")


func _confirm_delivery() -> void:
	if not is_ready_for_fair() or _step != STEP_DELIVERY:
		return
	if _choice != 1:
		_feedback = "El soporte se libera después del contacto con el suelo, nunca antes."
		_show()
		return
	_advance(STEP_SCOUT, "Secuencia de entrega segura verificada.")


func _confirm_scout() -> void:
	if not is_ready_for_fair() or _step != STEP_SCOUT:
		return
	if _choice != 1:
		_feedback = "Antes de anunciar un hallazgo, verifica los datos y observa la ruta con el acompañante aéreo."
		_show()
		return
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("register_discovery"):
		_feedback = "Archivo NASA no disponible: la presentación no se puede completar."
		_show()
		return
	registry.call("register_discovery", FAIR_ID,
		"Capítulo I · Primera feria de ciencias",
		"Proyecto escolar de los niños",
		"El primer capítulo termina con la presentación de un rover escolar: seguridad, energía, entrega y exploración auxiliar. El Archivo NASA sigue abierto; se desconocen otras historias por descubrir. La feria es un logro ficticio, no una misión NASA.")
	_step = STEP_FINISHED
	_choice = 0
	_feedback = ""
	exhibition_completed.emit()
	_show()


func _advance(next_step: int, feedback: String) -> void:
	_step = next_step
	_choice = 0
	_feedback = feedback
	_show()


func _show() -> void:
	_title.text = "CAPÍTULO I · FERIA DE CIENCIAS"
	if not is_ready_for_fair():
		_status.text = "AÚN FALTAN MEJORAS"
		_body.text = "Tienes que completar el rover en el taller antes de dar la demostración.\n\nMejoras pendientes: %d de %d.\n\n%s" % [missing_upgrades().size(), REQUIRED_UPGRADES.size(), _feedback]
		_hint.text = "E / Esc · Volver"
		return
	match _step:
		STEP_SAFETY:
			_status.text = "1 / 4 · TERRENO Y SEGURIDAD"
			_body.text = "En la primera prueba, ¿cómo evita dañarse o quedar atascado?\n\n%s ACELERAR AUNQUE LAS RUEDAS PATINEN\n%s PROTEGER, MEDIR PATINAJE Y DETENERSE\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_POWER:
			_status.text = "2 / 4 · ENERGÍA RESPONSABLE"
			_body.text = "La luz cambia durante la ruta. ¿Qué necesita la maqueta?\n\n%s MANTENER TODO ENCENDIDO SIN MEDIR\n%s MEDIR LUZ, RESERVA Y PRIORIZAR CONSUMOS\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_DELIVERY:
			_status.text = "3 / 4 · SOPORTE DE ENTREGA"
			_body.text = "El rover baja desde su soporte. ¿Cuándo soltarlo?\n\n%s ANTES DE QUE LAS RUEDAS TOQUEN SUELO\n%s DESPUÉS DE CONFIRMAR EL CONTACTO\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_SCOUT:
			_status.text = "4 / 4 · EXPLORAR Y COMPROBAR"
			_body.text = "La cámara no puede ver más allá de la cresta. ¿Cómo presentar resultados responsables?\n\n%s SUPONER QUE HAY UN CAMINO SEGURO\n%s OBSERVAR DESDE ARRIBA Y VERIFICAR DATOS\n\n%s" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " ", _feedback]
		STEP_FINISHED:
			_status.text = "CAPÍTULO I COMPLETADO · EL PRIMER LEGADO"
			_body.text = "El abuelo sonríe: «Tu primer rover está listo. No has construido una máquina de la NASA; has aprendido a hacer preguntas y encontrar soluciones».\n\nLa primera feria termina entre aplausos. Pero el Archivo NASA todavía guarda siluetas y recuerdos pendientes de descubrir. Esta historia apenas comienza.\n\n%s CONTINUAR · UNA NUEVA PISTA\n%s SABER MÁS · INSIGHT, SISMOS DE MARTE" % ["▶" if _choice == 0 else " ", "▶" if _choice == 1 else " "]
	_hint.text = "A / D · Elegir    E / Enter · Confirmar    Esc · Cerrar"


func _has_discovery(discovery_id: String) -> bool:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	return registry != null and registry.has_method("has_discovery") and bool(registry.call("has_discovery", discovery_id))


func _go_to_chapter_two_preview() -> void:
	# Es una escena de presentación del futuro capítulo, NO contenido jugable aún.
	# El logro del Capítulo I y los avances del Archivo permanecen intactos.
	if not _has_discovery(FAIR_ID):
		return
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", CHAPTER_TWO_TEASER)


func _go_to_optional_insight() -> void:
	# Nunca cambia el estado de la feria ni exige descubrir InSight.
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", IN_SIGHT_SCENE)


func _close() -> void:
	_active = false
	_panel.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_station() -> void:
	var station := MeshInstance3D.new()
	station.name = "ScienceFairDemoStand"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.30, 1.05, 0.78)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.34, 0.39)
	mesh.material = material
	station.mesh = mesh
	station.position.y = 0.53
	add_child(station)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.34, 1.08, 0.82)
	collider.shape = shape
	collider.position.y = 0.54
	add_child(collider)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ScienceFairHUD"
	canvas.layer = 76
	add_child(canvas)
	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.anchor_left = 0.20
	_panel.anchor_top = 0.14
	_panel.anchor_right = 0.80
	_panel.anchor_bottom = 0.86
	_panel.color = Color(0.027, 0.041, 0.055, 0.98)
	canvas.add_child(_panel)
	_title = _make_label("Title", 0.05, 0.03, 0.95, 0.13, 20, Color(0.95, 0.76, 0.37))
	_status = _make_label("Status", 0.07, 0.17, 0.93, 0.28, 20, Color(0.51, 0.85, 0.88))
	_body = _make_label("Body", 0.07, 0.32, 0.93, 0.86, 17, Color(0.92, 0.94, 0.97))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _make_label("Hint", 0.03, 0.88, 0.97, 0.97, 13, Color(0.74, 0.79, 0.86))


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
