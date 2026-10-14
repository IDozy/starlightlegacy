extends SceneTree

# Ejecutar desde la raíz del proyecto:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/workshop_glb_smoke.gd

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_smoke_test")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run_smoke_test() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	if packed == null:
		printerr("Fallo: no se pudo cargar la escena principal.")
		quit(1)
		return

	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var workshop := main.get_node_or_null("Workshop") as Node3D
	_check(workshop != null, "Falta Workshop en Main.")
	if workshop != null:
		_check(workshop.get_node_or_null("Taller_NASA_v02_Visual") != null,
			"No se instanció el GLB del taller.")
		_check(workshop.get_node_or_null("ImportedLowerFloor") != null,
			"Falta la colisión del nivel inferior.")
		_check(workshop.get_node_or_null("ImportedUpperPlatform") != null,
			"Falta la colisión de la plataforma superior.")
		var ramp := workshop.get_node_or_null("ImportedRampCollision") as StaticBody3D
		_check(ramp != null, "Falta la colisión de la rampa.")
		if ramp != null:
			var ramp_shape := ramp.get_node_or_null("CollisionShape3D") as CollisionShape3D
			_check(ramp_shape != null and ramp_shape.shape is ConvexPolygonShape3D,
				"La rampa debe usar una cuña convexa de colisión.")
		_check(workshop.get_node_or_null("RescueRoverProject") != null,
			"No debe cambiar la ruta del proyecto de rover.")
		_check(workshop.get_node_or_null("GrandfatherPlaceholder") != null
			or workshop.get_node_or_null("Grandfather") != null,
			"Falta el abuelo en el taller.")
		_check(workshop.get_node_or_null("Floor") == null,
			"El suelo antiguo no debería generarse junto al GLB.")
		_check(workshop.get_node_or_null("TestMat") == null,
			"La alfombra negra antigua todavía existe.")
		_check(workshop.get_node_or_null("DropPlatformBase") == null,
			"El bloque antiguo de la prueba todavía existe.")
		_check(workshop.get_node_or_null("WorkbenchBackboard") == null,
			"El panel negro anterior a la mesa todavía existe.")
		var back_wall := workshop.get_node_or_null("ImportedBackWall") as StaticBody3D
		_check(back_wall != null, "Falta el muro trasero visible con colisión.")
		if back_wall != null:
			_check(back_wall.position.z > 9.5,
				"La pared debe cerrar el primer nivel (+Z), no el portón superior (-Z).")
			var wall_collision := back_wall.get_node_or_null("CollisionShape3D") as CollisionShape3D
			_check(wall_collision != null and wall_collision.shape is BoxShape3D,
				"La pared inferior debe mantener su colisión.")
		var lower_wall_finish := workshop.get_node_or_null("ImportedBackWallLower") as Node3D
		if lower_wall_finish != null and back_wall != null:
			_check(lower_wall_finish.position.z < back_wall.position.z,
				"El zócalo debe mirar hacia el interior del taller.")

		var grandfather := workshop.get_node_or_null("Grandfather") as Node3D
		if grandfather != null:
			_check(is_equal_approx(grandfather.position.y, 1.0),
				"El abuelo debería estar en el nivel superior.")
			_check(grandfather.position.x > 3.5,
				"El abuelo debería estar junto a la baranda derecha.")

		var bench := workshop.get_node_or_null("WorkbenchTop") as Node3D
		var device := workshop.get_node_or_null("PrototypeDevice") as Node3D
		if device != null:
			_check(device.position.y > 0.8 and device.position.y < 1.3,
				"El objeto inspeccionable debe seguir sobre la mesa del primer nivel.")
		if bench != null:
			_check(bench.position.x < -3.0,
				"La mesa debe quedar a la izquierda de la rampa.")
			_check(is_equal_approx(bench.position.y, 0.90),
				"La mesa debe quedar al nivel del piso inferior, no en la plataforma.")
			_check(bench.position.z > 0.20,
				"La mesa debe quedar en la zona inferior de la rampa.")

		for rail_name in ["ImportedRailRampEdgeLeft", "ImportedRailRampEdgeRight",
			"ImportedSideSafetyLeft", "ImportedSideSafetyRight"]:
			var rail := workshop.get_node_or_null(rail_name) as StaticBody3D
			_check(rail != null, "Falta protección anti-caída: " + rail_name)
			if rail != null:
				var guard := rail.get_node_or_null("CollisionShape3D") as CollisionShape3D
				_check(guard != null and guard.shape is BoxShape3D,
					"La barrera debe tener una colisión de caja: " + rail_name)
				if guard != null and guard.shape is BoxShape3D:
					var guard_box := guard.shape as BoxShape3D
					_check(guard_box.size.y >= 2.4,
						"La protección debe superar la altura de salto: " + rail_name)

	_check(main.get_node_or_null("Player") != null, "Falta el jugador.")
	_check(main.get_node_or_null("DialogueController") != null,
		"Falta el controlador de diálogos.")

	if failures.is_empty():
		print("PASS: GLB, colisiones básicas e interacciones del taller.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
