extends StaticBody3D
## Caja SIN identificar: no representa aún un hardware histórico concreto.
## Cliffhanger jugable. Nunca registra un descubrimiento NASA inexistente.

const INPUT_COMPAT := preload("res://systems/input/input_compat.gd")
const LINES := [
	"Al regresar de la feria, el abuelo encuentra una pequeña caja cubierta de polvo, sin etiqueta. Hay hojas y bocetos, pero ninguna identificación segura.",
	"Abuelo: «No sabemos a qué misión pertenecen estos dibujos. Todavía hay muchas historias por investigar; antes de contar una tendremos que comprobarla».",
	"Las siluetas del Archivo siguen esperando. Por ahora, el primer rover está listo y el Capítulo I ha terminado.\n\nSTARLIGHT LEGACY · CONTINUARÁ..."
]

var _player: Node = null
var _active := false
var _line := 0
var _started_frame := -1
var _overlay: ColorRect
var _body: Label


func _ready() -> void:
	_build_case()
	_build_hud()


func get_interaction_prompt() -> String:
	return "E · Examinar la caja sin identificar"


func interact(player: Node) -> void:
	if player == null or _active:
		return
	_player = player
	_active = true
	_line = 0
	_started_frame = Engine.get_process_frames()
	if _player.has_method("set_control_locked"):
		_player.call("set_control_locked", true)
	_overlay.visible = true
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return
	if not event.pressed or event.echo or Engine.get_process_frames() == _started_frame:
		return
	if INPUT_COMPAT.key_matches(event, KEY_ESCAPE):
		_close()
		get_viewport().set_input_as_handled()
		return
	if not (INPUT_COMPAT.key_matches(event, KEY_E) or INPUT_COMPAT.key_matches(event, KEY_ENTER)):
		return
	if _line + 1 < LINES.size():
		_line += 1
		_refresh()
	else:
		_close()
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	_body.text = "%s\n\nE / Enter · Continuar    Esc · Salir" % LINES[_line]


func _close() -> void:
	_active = false
	_overlay.visible = false
	if _player != null and _player.has_method("set_control_locked"):
		_player.call("set_control_locked", false)


func _build_case() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "UnidentifiedBox"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.55, 0.76, 1.05)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.37, 0.28, 0.20)
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.41
	add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.60, 0.80, 1.10)
	collider.shape = shape
	collider.position.y = 0.40
	add_child(collider)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MysteryHUD"
	layer.layer = 76
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.name = "MysteryPanel"
	_overlay.visible = false
	_overlay.anchor_left = 0.18
	_overlay.anchor_top = 0.23
	_overlay.anchor_right = 0.82
	_overlay.anchor_bottom = 0.77
	_overlay.color = Color(0.026, 0.038, 0.054, 0.98)
	layer.add_child(_overlay)
	_body = Label.new()
	_body.name = "MysteryText"
	_body.anchor_left = 0.08
	_body.anchor_top = 0.12
	_body.anchor_right = 0.92
	_body.anchor_bottom = 0.88
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 20)
	_body.add_theme_color_override("font_color", Color(0.94, 0.92, 0.85))
	_overlay.add_child(_body)
