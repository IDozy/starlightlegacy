extends SceneTree
## Contrato de la intro de video OPCIONAL. No exige disponer del render.
## godot --headless --path . --script res://tests/pathfinder_video_intro_smoke.gd

var problems: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _assert(ok: bool, why: String) -> void:
	if not ok:
		problems.append(why)


func _run() -> void:
	var packed := load("res://levels/ares_vallis/pathfinder_video_intro.tscn") as PackedScene
	var memory := load("res://levels/ares_vallis/ares_vallis.tscn") as PackedScene
	_assert(packed != null and memory != null, "Debe existir intro y mapa jugable")
	if packed != null:
		var intro := packed.instantiate() as Control
		_assert(intro != null, "La intro debe ser un Control")
		if intro != null:
			var player := intro.get_node_or_null("Backdrop/Aspect/Movie") as VideoStreamPlayer
			_assert(player != null, "El video debe utilizar VideoStreamPlayer")
			_assert(intro.get_node_or_null("Overlay/Title") != null, "Falta título")
			_assert(intro.get_node_or_null("Overlay/Body") != null, "Faltan subtítulos")
			_assert(intro.has_method("_complete_video"), "No se puede omitir el video")
			_assert(intro.has_method("_update_caption"), "No existe controlador de textos")
			intro.free()
	if memory != null:
		var level := memory.instantiate() as Node3D
		_assert(bool(level.get("enable_pathfinder_intro")),
			"La intro in-engine debe ser la opción predeterminada")
		level.free()
	if problems.is_empty():
		print("PASS: video opcional, intro in-engine predeterminada, skip y mapa")
		quit(0)
	else:
		for problem in problems:
			printerr("FAIL: ", problem)
		quit(1)
