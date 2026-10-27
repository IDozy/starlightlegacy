extends SceneTree
## Validación de contrato del piloto de cinemática de Pathfinder.
## NO ejecutado: godot --headless --path . --script res://tests/pathfinder_cinematic_intro_smoke.gd

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _run() -> void:
	var packed := load("res://levels/ares_vallis/ares_vallis.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: Ares Vallis no carga")
		quit(1)
		return
	var level := packed.instantiate() as Node3D
	level.set("enable_pathfinder_intro", true)
	root.add_child(level)
	for i in range(5):
		await physics_frame
		await process_frame

	var controller := level.get_node_or_null("PathfinderCinematicIntro")
	var player := level.get_node_or_null("Player") as CharacterBody3D
	var hud := level.get_node_or_null("HUD") as CanvasLayer
	var original := level.get_node_or_null("PathfinderStoryPoint")
	var sojourner := level.get_node_or_null("SojournerScanChallenge")
	_expect(controller != null, "No se instanció la cinemática en Ares Vallis")
	_expect(player != null and hud != null, "Falta jugador o HUD")
	_expect(original != null and sojourner != null,
		"Los dos objetos interactivos originales desaparecieron")
	var registry := root.get_node_or_null("KnowledgeRegistry")
	var discoveries_before := registry.call("get_discovery_count") if registry != null else -1
	if controller != null and player != null and hud != null:
		_expect(bool(controller.call("is_playing")), "La intro no se inició")
		_expect(bool(player.get("_control_locked")), "Se puede caminar durante la intro")
		_expect(not hud.visible, "El HUD jugable tapa la intro")
		_expect(controller.get_node_or_null("IntroCamera") != null, "Sin cámara propia")
		_expect(controller.get_node_or_null("CinematicHUD") != null, "Sin subtítulos")
		_expect(not original.visible, "Pathfinder real se duplica durante la intro")
		# Verificar salto temporal incluso sin esperar 15 segundos.
		controller.call("_apply_frame", 11.2)
		var caption := controller.get_node_or_null("CinematicHUD/ShotTitle") as Label
		_expect(caption != null and caption.text.contains("SOLES SIGUIENTES"),
			"Falta aclaración histórica de despliegue de Sojourner")
		controller.call("skip_intro")
		_expect(not bool(controller.call("is_playing")), "Esc no devuelve el control")
		_expect(not bool(player.get("_control_locked")), "Jugador bloqueado tras omitir")
		_expect(hud.visible, "HUD no restaurado")
		_expect(original.visible and sojourner.visible, "Objetos ocultos tras omitir")
		_expect(player.get_node("Head/Camera3D").current,
			"No se restauró la cámara FPS original")
		_expect(original.has_method("interact") and sojourner.has_method("interact"),
			"Se perdieron las interacciones históricas")
		_expect(not controller.get_node("IntroCamera").current,
			"Cámara cinemática aún activa después del salto")
		_expect(not controller.call("is_playing"), "Cinemática reactivada tras omitir")
	if registry != null:
		_expect(int(registry.call("get_discovery_count")) == discoveries_before,
			"La intro registró falsos descubrimientos")
	if failures.is_empty():
		print("PASS: Pathfinder in-engine intro, temporal caption, skip, FPS and discoveries")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
