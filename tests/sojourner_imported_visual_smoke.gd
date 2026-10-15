extends SceneTree

# Ejecutar desde la raiz del proyecto Godot:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/sojourner_imported_visual_smoke.gd
#
# Comprueba que el GLB trae solo el Sojourner al reto, manteniendo
# la logica APXS y los controles de movimiento.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _count_rover_wheels(node: Node) -> int:
	var count := 0
	if str(node.name).to_lower().begins_with("roverfrontwheel"):
		count += 1
	for child in node.get_children():
		count += _count_rover_wheels(child)
	return count



func _count_restored_surfaces(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for i in range(instance.mesh.get_surface_count()):
				var restored := instance.get_surface_override_material(i) as StandardMaterial3D
				if restored != null and restored.resource_name.begins_with("SL_rover_"):
					total += 1
				elif restored != null and restored.resource_name == "SL_solarpanels":
					_check(restored.albedo_color.b > restored.albedo_color.r, "El panel solar deberia ser azul oscuro.")
					total += 1
				elif restored != null and restored.resource_name.begins_with("SL_"):
					total += 1
	for child in node.get_children():
		total += _count_restored_surfaces(child)
	return total


func _largest_wheel_gap(node: Node) -> float:
	var gap := 0.0
	if node is MeshInstance3D and str(node.name).to_lower().begins_with("roverfrontwheel"):
		var wheel := node as MeshInstance3D
		var low_y := INF
		for surface_idx in range(wheel.mesh.get_surface_count()):
			var arrays := wheel.mesh.surface_get_arrays(surface_idx)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex in positions:
				low_y = minf(low_y, (wheel.global_transform * vertex).y)
		if low_y < INF:
			gap = maxf(0.0, low_y)
	for child in node.get_children():
		gap = maxf(gap, _largest_wheel_gap(child))
	return gap


func _has_real_rock_mesh(node: Node) -> bool:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null and not (instance.mesh is SphereMesh):
			return true
	for child in node.get_children():
		if _has_real_rock_mesh(child):
			return true
	return false


func _run() -> void:
	var packed := load("res://systems/gameplay/sojourner_scan_challenge.tscn") as PackedScene
	if packed == null:
		printerr("FAIL: la escena del reto de Sojourner no carga.")
		quit(1)
		return

	var challenge := packed.instantiate() as StaticBody3D
	if challenge == null:
		printerr("FAIL: la escena de Sojourner no se instancia.")
		quit(1)
		return

	var stage := Node3D.new()
	stage.name = "SojournerVisualSmokeStage"
	root.add_child(stage)
	var test_ground := Node3D.new()
	test_ground.name = "AresVallisLandscape_v33"
	test_ground.set_script(preload("res://tests/fixtures/flat_ares_terrain.gd"))
	stage.add_child(test_ground)
	stage.add_child(challenge)
	await process_frame

	var visual := challenge.get_node_or_null("RoverVisual") as Node3D
	var imported := challenge.get_node_or_null("RoverVisual/SojournerImportedModel") as Node3D
	_check(visual != null, "Falta el nodo RoverVisual del gameplay.")
	_check(imported != null, "No se extrajo SojournerRover desde el GLB.")
	_check(challenge.get_node_or_null("RoverVisual/ground") == null, "Se importo un piso duplicado.")
	_check(challenge.get_node_or_null("RoverVisual/Rocks") == null, "Se importaron rocas duplicadas.")
	if imported != null:
		_check(_count_rover_wheels(imported) == 6,
			"El Sojourner importado debe conservar exactamente seis ruedas.")
		_check(imported.scale.x > 0.001 and imported.scale.x < 10.0,
			"La escala del rover importado es inusual.")
		_check(absf(imported.rotation_degrees.y - 90.0) < 0.2,
			"El frente del rover no mira hacia la roca Yogi.")
		_check(visual.has_method("snap_to_terrain"),
			"Falta el ajuste de altura sobre las seis ruedas.")
		if visual.has_method("snap_to_terrain"):
			_check(bool(visual.call("snap_to_terrain")),
				"No se detectaron las seis ruedas reales o no se aplico el apoyo.")
			_check(_largest_wheel_gap(imported) < 0.025,
				"Una o mas ruedas quedaron suspendidas respecto al terreno plano.")
			var supported_y: float = visual.position.y
			_check(bool(visual.call("snap_to_terrain")),
				"El apoyo debe poder repetirse tras mover el rover.")
			_check(absf(visual.position.y - supported_y) < 0.002,
				"El apoyo se acumula y hunde al rover al ejecutar varias veces.")
		var restored_surfaces := _count_restored_surfaces(imported)
		_check(restored_surfaces >= 12,
			"Falta restaurar la paleta del GLB: demasiadas superficies sin material.")

	for legacy_name in ["Body", "SolarPanel", "APXS", "WheelFL", "WheelFR"]:
		var old := challenge.get_node_or_null("RoverVisual/" + legacy_name) as Node3D
		_check(old != null, "Falta la pieza de respaldo " + legacy_name)
		if old != null and imported != null:
			_check(not old.visible, "Una pieza provisional sigue superpuesta: " + legacy_name)

	# Yogi ya no debe verse como una esfera ovalada ni tocar el rover
	# desde el comienzo. Su colision acompana al modelo importado.
	var yogi := challenge.get_node_or_null("Rock") as Node3D
	var yogi_collision := challenge.get_node_or_null("YogiCollision") as CollisionShape3D
	_check(yogi != null, "Falta la roca Yogi.")
	_check(yogi_collision != null, "Falta la colision de Yogi.")
	if yogi != null:
		_check(yogi.position.z <= -2.0,
			"Yogi volvio a quedar demasiado cerca del rover.")
		_check(yogi.scale.x <= 0.181 and yogi.scale.y <= 0.126,
			"Yogi volvio a quedar demasiado grande.")
		_check(_has_real_rock_mesh(yogi),
			"Yogi no usa la malla irregular, o volvio la esfera-huevo.")
	if yogi != null and yogi_collision != null:
		_check(absf(yogi.position.x - yogi_collision.position.x) < 0.001,
			"La colision de Yogi se desplazo lateralmente respecto a la roca.")
		_check(absf(yogi.position.z - yogi_collision.position.z) < 0.001,
			"La colision de Yogi no coincide con la roca visual.")
	_check(challenge.has_signal("challenge_completed"), "Se perdio la senal de APXS.")
	_check(challenge.get_node_or_null("ChallengeHUD/Panel/ScanProgress") != null,
		"Se perdio la interfaz del APXS.")
	_check(challenge.get_node_or_null("CollisionShape3D") != null,
		"Se perdio la colision de interaccion del rover.")

	if visual != null:
		var before_z := visual.position.z
		challenge.call("set_completed_state", true)
		_check(not is_equal_approx(before_z, visual.position.z),
			"El reto no mueve el rover cuando avanza.")
		_check(is_equal_approx(visual.position.z, -1.10),
			"El rover no llega hasta la nueva posicion de analisis APXS.")

	if failures.is_empty():
		print("PASS: Sojourner GLB con paleta reparada, 6 ruedas y APXS intacto.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
