extends SceneTree

# Ejecutar desde la raiz del proyecto:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/ares_vallis_v33_smoke.gd
#
# Verifica la integracion del GLB sin alterar los descubrimientos del juego.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_smoke_test")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run_smoke_test() -> void:
	var packed := load("res://levels/ares_vallis/ares_vallis.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: no se pudo cargar Ares Vallis.")
		quit(1)
		return

	var level := packed.instantiate() as Node3D
	if level == null:
		printerr("FAIL: no se pudo instanciar el nivel.")
		quit(1)
		return

	root.add_child(level)
	await physics_frame
	await physics_frame

	var landscape := level.get_node_or_null("AresVallisLandscape_v33") as Node3D
	_check(landscape != null, "Falta la integracion del modelo v33.")
	if landscape != null:
		_check(landscape.get_node_or_null("AresVallis_v33_Visual") != null,
			"Falta la instancia del GLB.")
		_check(not bool(landscape.call("using_fallback_floor")),
			"El GLB no produjo colision de terreno; se uso piso temporal.")

	_check(level.get_node_or_null("AresGround") == null,
		"El suelo provisional se duplica con el GLB.")
	_check(level.get_node_or_null("NASAPathfinderTerrainPreview") == null,
		"El terreno de vista previa NASA se duplica con el GLB.")
	_check(level.get_node_or_null("WestMoundA") == null,
		"Los monticulos provisionales siguen visibles.")
	_check(level.get_node_or_null("SojournerSoilPatch") == null,
		"Se ha vuelto a dibujar la plataforma circular de Sojourner encima del GLB.")
	_check(level.get_node_or_null("MarsSun") != null,
		"Falta la iluminacion marciana del nivel.")
	var mars_environment := level.get_node_or_null("MarsEnvironment") as WorldEnvironment
	_check(mars_environment != null and mars_environment.environment != null,
		"Falta el ambiente de Marte.")
	if mars_environment != null and mars_environment.environment != null:
		_check(mars_environment.environment.background_mode == Environment.BG_SKY,
			"Volvio el cielo marron plano en vez del gradiente.")
	if landscape != null:
		var terrain_visual := landscape.get_node_or_null("AresVallis_v33_Visual") as Node3D
		var colored := _count_terrain_override_materials(terrain_visual)
		_check(colored >= 1,
			"El suelo no tiene material estable; pueden reaparecer manchas blancas.")

	var player := level.get_node_or_null("Player") as CharacterBody3D
	_check(player != null, "Falta el jugador.")
	if player != null and landscape != null:
		var ground := float(landscape.call(
			"ground_height_at", player.global_position.x, player.global_position.z))
		_check(absf(player.position.y - ground - 1.0) < 0.4,
			"El jugador no esta apoyado sobre el suelo del GLB.")
		_check(player.get_node_or_null("Head/Camera3D") != null,
			"Se perdio la camara del jugador.")

	_check(level.get_node_or_null("HUD/Objective") != null,
		"Falta el HUD de objetivos.")
	_check(level.get_node_or_null("HUD/InteractionPrompt") != null,
		"Falta el indicador de interaccion.")

	# Los dos retos deben conservarse, sin reemplazar su logica por decoraciones.
	var challenges := 0
	for child in level.get_children():
		if child.has_method("set_completed_state"):
			challenges += 1
	_check(challenges >= 2, "Faltan los retos de Pathfinder o Sojourner.")

	if failures.is_empty():
		print("PASS: Ares Vallis v33, terreno, colision y gameplay conservado.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)


func _count_terrain_override_materials(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.name.to_lower().contains("av28_") and instance.material_override != null:
			count += 1
	for child in node.get_children():
		count += _count_terrain_override_materials(child)
	return count
