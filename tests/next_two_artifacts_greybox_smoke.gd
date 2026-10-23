extends SceneTree
# Verificar desde la raiz del proyecto:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/next_two_artifacts_greybox_smoke.gd
#
# Confirma que las piezas nuevas son escenas independientes, no
# reemplazan Pathfinder y no traen terreno ni camaras propias.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_check_scenes")


func _check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)


func _check_scenes() -> void:
	var vanguard_packed := load("res://levels/vanguard_1/vanguard_1_greybox.tscn") as PackedScene
	var surveyor_packed := load("res://levels/surveyor_1/surveyor_1_greybox.tscn") as PackedScene
	if vanguard_packed == null or surveyor_packed == null:
		printerr("FAIL: no se pudieron cargar ambos modelos temporales.")
		quit(1)
		return

	var vanguard := vanguard_packed.instantiate() as Node3D
	var surveyor := surveyor_packed.instantiate() as Node3D
	_check(vanguard != null, "Vanguard no es Node3D.")
	_check(surveyor != null, "Surveyor no es Node3D.")
	if vanguard == null or surveyor == null:
		quit(1)
		return

	root.add_child(vanguard)
	root.add_child(surveyor)
	await process_frame

	var sphere := vanguard.get_node_or_null("ArtifactModel/SphereBody") as MeshInstance3D
	_check(sphere != null, "Vanguard no contiene la esfera principal.")
	if sphere != null:
		var vanguard_sphere := sphere.mesh as SphereMesh
		_check(vanguard_sphere != null, "Vanguard no tiene SphereMesh.")
		if vanguard_sphere != null:
			_check(absf(vanguard_sphere.radius * 2.0 - 0.164) < 0.004,
				"Vanguard no esta a la escala historica de 16.5 cm.")

	var solar_parts := 0
	var antenna_parts := 0
	for child in vanguard.get_node("ArtifactModel").get_children():
		if child.name.begins_with("Solar_"):
			solar_parts += 1
		if child.name.begins_with("Antenna_"):
			antenna_parts += 1
	_check(solar_parts == 6, "Vanguard debe representar seis grupos solares.")
	_check(antenna_parts == 6, "Vanguard debe representar seis antenas.")

	var feet := 0
	for suffix in ["A", "B", "C"]:
		var foot := surveyor.get_node_or_null("ArtifactModel/LegMount_" + suffix + "/Footpad_" + suffix)
		if foot != null:
			feet += 1
	_check(feet == 3, "Surveyor 1 debe tener tres patas con zapatas.")
	_check(surveyor.get_node_or_null("ArtifactModel/SolarPanelStaticPreview") != null,
		"Surveyor 1 necesita panel solar.")
	_check(surveyor.get_node_or_null("ArtifactModel/TV_Camera") != null,
		"Surveyor 1 necesita camara de television.")
	_check(surveyor.get_node_or_null("ArtifactModel/DishAntenna") != null,
		"Surveyor 1 necesita antena.")

	_check(vanguard.get_node_or_null("Player") == null and surveyor.get_node_or_null("Player") == null,
		"Los modelos deben mantenerse separados de los niveles jugables.")
	if failures.is_empty():
		print("PASS: Vanguard 1 y Surveyor 1 greybox cargan con componentes esperados.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
