extends Control
## Video del recuerdo 01; usa VideoStreamPlayer (.ogv) de Godot 4.
## El video es UNA intro. El nivel y las interacciones siguen en Ares Vallis.
## Si aún falta render, entra directamente al mapa (sin un softlock).

const VIDEO_PATH := "res://assets/videos/pathfinder/pathfinder_intro.ogv"
const PLAYABLE_SCENE := "res://levels/ares_vallis/ares_vallis.tscn"
const CAPTIONS := [
	{"start": 0.0, "title": "MARTE · 4 DE JULIO DE 1997", "body": "Mars Pathfinder se aproxima a Ares Vallis."},
	{"start": 2.7, "title": "DESCENSO", "body": "Paracaídas y retrocohetes reducen la velocidad."},
	{"start": 5.5, "title": "ATERRIZAJE", "body": "Los airbags protegen al módulo mientras rebota."},
	{"start": 8.5, "title": "PATHFINDER", "body": "El módulo se estabiliza, retrae los airbags y abre sus pétalos."},
	{"start": 12.0, "title": "SOL 2 · SOJOURNER", "body": "El rover desciende por la rampa trasera en un momento posterior."},
	{"start": 15.0, "title": "ARES VALLIS", "body": "Ahora te toca explorar el recuerdo."}
]

@onready var movie: VideoStreamPlayer = $Backdrop/Aspect/Movie
@onready var caption_title: Label = $Overlay/Title
@onready var caption_body: Label = $Overlay/Body
@onready var caption_hint: Label = $Overlay/Hint

var _leaving := false
var _last_caption := -1


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	movie.finished.connect(_complete_video)
	if not ResourceLoader.exists(VIDEO_PATH):
		# No reactivar la cinemática in-engine: se conserva solo para comparar.
		push_warning("Pathfinder: video .ogv aún no renderizado; se abre el nivel directamente.")
		call_deferred("_complete_video")
		return
	var resource := load(VIDEO_PATH) as VideoStream
	if resource == null:
		push_warning("Pathfinder: .ogv no compatible; se omite la introducción.")
		call_deferred("_complete_video")
		return
	movie.stream = resource
	movie.expand = true
	movie.loop = false
	_update_caption(0.0)
	movie.play()
	set_process(true)


func _process(_delta: float) -> void:
	if _leaving:
		return
	_update_caption(movie.stream_position)


func _update_caption(seconds: float) -> void:
	var index := 0
	for i in range(CAPTIONS.size()):
		if seconds >= float(CAPTIONS[i]["start"]):
			index = i
		else:
			break
	if index == _last_caption:
		return
	_last_caption = index
	caption_title.text = str(CAPTIONS[index]["title"])
	caption_body.text = str(CAPTIONS[index]["body"])
	caption_hint.text = "E / Esc · Omitir"


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
		_complete_video()
		get_viewport().set_input_as_handled()


func _complete_video() -> void:
	if _leaving:
		return
	_leaving = true
	set_process(false)
	movie.stop()
	# La transición ya existente crea un fundido de salida y de entrada.
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("fade_to_scene"):
		transition.call("fade_to_scene", PLAYABLE_SCENE, 0.28)
	else:
		get_tree().change_scene_to_file(PLAYABLE_SCENE)
