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
	if node.name.begins_with("RoverFrontWheel."):
		count += 1
	for child in node.get_children():
		count += _count_rover_wheels(child)
	return count


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

	root.add_child(challenge)
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

	for legacy_name in ["Body", "SolarPanel", "APXS", "WheelFL", "WheelFR"]:
		var old := challenge.get_node_or_null("RoverVisual/" + legacy_name) as Node3D
		_check(old != null, "Falta la pieza de respaldo " + legacy_name)
		if old != null and imported != null:
			_check(not old.visible, "Una pieza provisional sigue superpuesta: " + legacy_name)

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

	if failures.is_empty():
		print("PASS: Sojourner GLB sin rocas/suelo duplicados, 6 ruedas y APXS intacto.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
