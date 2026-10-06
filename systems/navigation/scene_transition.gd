extends CanvasLayer

var _overlay: ColorRect
var _transitioning := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.015, 0.02, 0.03, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)


func fade_to_scene(scene_path: String, duration: float = 0.45) -> void:
	if _transitioning:
		return

	_transitioning = true
	_overlay.visible = true

	var fade_out := create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(_overlay, "color:a", 1.0, duration)
	await fade_out.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo cambiar a la escena: %s" % scene_path)
		_overlay.color.a = 0.0
		_overlay.visible = false
		_transitioning = false
		return

	await get_tree().process_frame

	_overlay.color.a = 1.0
	var fade_in := create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(_overlay, "color:a", 0.0, duration)
	await fade_in.finished

	_overlay.visible = false
	_transitioning = false
