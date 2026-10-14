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
