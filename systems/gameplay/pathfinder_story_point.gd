extends StaticBody3D

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")

signal story_active_changed(active: bool)
signal story_completed

const DISCOVERY_ID := "mars_pathfinder_lander"
const LAST_PAGE := 2

@onready var panel: Control = $StoryHUD/Panel
@onready var stage_label: Label = $StoryHUD/Panel/Stage
@onready var body_label: Label = $StoryHUD/Panel/Body
@onready var progress_label: Label = $StoryHUD/Panel/Progress
@onready var hint_label: Label = $StoryHUD/Panel/Hint

var _player: Node = null
var _active := false
var _completed := false
var _review_only := false
var _page_index := 0
var _started_frame := -1


func _ready() -> void:
	panel.visible = false


func get_interaction_prompt() -> String:
	if _completed:
		return "E · Revisar Mars Pathfinder"

	return "E · Reconstruir llegada de Pathfinder"


func interact(player: Node) -> void:
	if _active:
		return

	_player = player
	_active = true
	_started_frame = Engine.get_process_frames()

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)

	panel.visible = true
	story_active_changed.emit(true)

	if _completed:
		_open_review()
	else:
		_review_only = false
		_page_index = 0
		_show_page()


func set_completed_state(completed: bool) -> void:
	_completed = completed


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	if Engine.get_process_frames() == _started_frame:
		return

	if not event.pressed or event.echo:
		return

	if _review_only:
		if INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
			_close_panel()
			get_viewport().set_input_as_handled()
		return

	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close_panel()
		get_viewport().set_input_as_handled()
		return

	var advance := (
		INPUT_COMPAT.key_matches(event, KEY_E)
		or INPUT_COMPAT.key_matches(event, KEY_ENTER)
		or INPUT_COMPAT.key_matches(event, KEY_SPACE)
	)

	if not advance:
		return

	if _page_index < LAST_PAGE:
		_page_index += 1
		_show_page()
	else:
		_complete_story()

	get_viewport().set_input_as_handled()


func _show_page() -> void:
	match _page_index:
		0:
			stage_label.text = "1 · ATERRIZAJE CON AIRBAGS"
			body_label.text = "Pathfinder llegó a Marte el 4 de julio de 1997. Fue la primera nave estadounidense que usó airbags para amortiguar el aterrizaje. Tocó la superficie a unos 50 km/h y rebotó al menos 15 veces antes de detenerse."
		1:
			stage_label.text = "2 · LOS PÉTALOS SE ABREN"
			body_label.text = "Los airbags se desinflaron y, 87 minutos después del aterrizaje, Pathfinder abrió sus pétalos. Así quedaron expuestos sus paneles solares, instrumentos y el pequeño rover que viajaba plegado sobre la estación."
		2:
			stage_label.text = "3 · SOJOURNER SALE A MARTE"
			body_label.text = "Cuando el terreno estuvo listo, Sojourner descendió por una rampa y comenzó a explorar Ares Vallis. Pathfinder quedó como estación base y pasó a llamarse Carl Sagan Memorial Station."

	progress_label.text = "%d / 3" % (_page_index + 1)
	hint_label.text = "E / Enter / Espacio · Siguiente    Esc · Salir"


func _complete_story() -> void:
	_completed = true
	_review_only = true
	_register_discovery()
	story_completed.emit()

	stage_label.text = "HISTORIA RECUPERADA · MARS PATHFINDER"
	body_label.text = "Airbags → pétalos → Sojourner. El hardware quedó en Ares Vallis, pero aquel aterrizaje demostró una forma nueva y económica de llevar ciencia a Marte."
	progress_label.text = "3 / 3 · COMPLETADO"
	hint_label.text = "E / Esc · Continuar"


func _open_review() -> void:
	_review_only = true
	stage_label.text = "MARS PATHFINDER · ARES VALLIS · 1997"
	body_label.text = "Pathfinder aterrizó con airbags, abrió sus pétalos y desplegó a Sojourner. La estación quedó en Marte como Carl Sagan Memorial Station."
	progress_label.text = "HISTORIA RECUPERADA"
	hint_label.text = "E / Esc · Cerrar"


func _register_discovery() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("register_discovery"):
		return

	registry.call(
		"register_discovery",
		DISCOVERY_ID,
		"Mars Pathfinder",
		"Hardware en Marte",
		"Pathfinder aterrizó en Ares Vallis el 4 de julio de 1997 usando paracaídas, retrocohetes y airbags. Tras rebotar y detenerse, sus airbags se desinflaron, abrió sus pétalos y desplegó al rover Sojourner."
	)


func _close_panel() -> void:
	_active = false
	_review_only = false
	panel.visible = false

	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)

	story_active_changed.emit(false)
