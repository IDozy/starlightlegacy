extends SceneTree
## Apollo 15: contrato del quinto recuerdo, pendiente de ejecutar:
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/apollo_15_lrv_story_loop_smoke.gd

const AIRBAG := "rescue_rover_airbag_upgrade"
const SOLAR := "rescue_rover_solar_upgrade"
const ORIENTATION := "rescue_rover_orientation_upgrade"
const MODULE := "rescue_rover_modular_release_upgrade"
const APOLLO11 := "apollo_11_descent_stage"
const TRACTION_PROBLEM := "rescue_rover_traction_problem"
const APOLLO15 := "apollo_15_lrv"
const TRACTION_UPGRADE := "rescue_rover_traction_upgrade"

var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)


func _register(registry: Node, id: String) -> void:
	registry.call("register_discovery", id, id, "Prueba", "Estado de prueba.")


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: KnowledgeRegistry autoload ausente.")
		quit(1)
		return
	for previous_id in [AIRBAG, SOLAR, ORIENTATION, APOLLO11, MODULE]:
		_register(registry, previous_id)

	var project_packed := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var npc_packed := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	var memory_packed := load("res://levels/apollo_15/apollo_15_memory.tscn") as PackedScene
	if project_packed == null or npc_packed == null or memory_packed == null:
		printerr("FAIL: un recurso del recuerdo Apollo 15 no carga.")
		quit(1)
		return
	var project := project_packed.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame

	_expect(str(project.call("get_interaction_prompt")).contains("terreno irregular"),
		"La prueba de tracción debe seguir a la mejora modular de Apollo 11.")
	_expect(not registry.has_discovery(TRACTION_PROBLEM),
		"No se puede marcar problema antes de probar el rover.")
	project.call("_record_traction_failure")
	_expect(registry.has_discovery(TRACTION_PROBLEM),
		"El problema de tracción no se guarda.")

	var grandfather := npc_packed.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Apollo 15"),
		"El abuelo no ofrece Apollo 15 tras el fallo de movilidad.")

	var memory := memory_packed.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var rover := memory.get_node_or_null("Apollo15LunarRover") as Node3D
	var console := memory.get_node_or_null("Apollo15MobilityConsole") as StaticBody3D
	_expect(rover != null, "Falta LRV greybox en la escena.")
	_expect(console != null, "Falta consola de movilidad.")
	if rover != null and console != null:
		_expect(bool(rover.call("has_four_wheels")), "LRV debe tener cuatro ruedas.")
		_expect(rover.get_node_or_null("ChassisAndEquipment/SeatCushion_-1") != null,
			"Faltan asientos del LRV.")
		_expect(rover.get_node_or_null("WireMeshWheel_Left_Front") != null,
			"Falta rueda delantera izquierda.")
		_expect(not registry.has_discovery(APOLLO15),
			"El recuerdo no debe estar disponible antes de completar el reto.")

		console.set("_choice", 0)
		console.call("_confirm_wheels")
		_expect(not bool(console.get("_wheels_checked")),
			"Neumáticos lisos incorrectos no deben aprobar la etapa.")
		console.set("_choice", 1)
		console.call("_confirm_wheels")
		_expect(bool(console.get("_wheels_checked")), "No aprobó ruedas de malla.")

		console.set("_choice", 0)
		console.call("_confirm_load")
		_expect(not bool(console.get("_load_checked")),
			"Concentrar peso debe rechazarse.")
		console.set("_choice", 1)
		console.call("_confirm_load")
		_expect(bool(console.get("_load_checked")), "No aprobó reparto de carga.")

		console.set("_choice", 0)
		console.call("_confirm_drive")
		_expect(not registry.has_discovery(APOLLO15),
			"No debe registrar historia sin completar el recorrido.")
		console.set("_choice", 1)
		console.call("_confirm_drive")
		_expect(bool(console.get("_travel_checked")), "No se completó la ruta.")
		_expect(registry.has_discovery(APOLLO15),
			"No aparece Apollo 15 en el Archivo NASA.")

	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"No se habilitó portal al taller.")

	var catalog: Dictionary = registry.call("get_catalog_entry", APOLLO15)
	_expect(int(catalog.get("year", 0)) == 1971,
		"LRV debe figurar en el año 1971.")
	_expect(str(catalog.get("application_discovery_id", "")) == TRACTION_UPGRADE,
		"El Archivo no enlaza la mejora de tracción.")

	project.call("_open_traction_upgrade")
	project.set("_traction_selection", 0)
	project.call("_confirm_traction_upgrade")
	_expect(not registry.has_discovery(TRACTION_UPGRADE),
		"Elegir solo más potencia no debe desbloquear la mejora.")
	project.set("_traction_selection", 1)
	project.call("_confirm_traction_upgrade")
	_expect(registry.has_discovery(TRACTION_UPGRADE),
		"No se instaló la mejora del vehículo.")

	var tires := project.get_node_or_null("TractionWheelUpgradeVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	var camera := project.get_node_or_null("OrientationUpgradeVisual") as Node3D
	var release := project.get_node_or_null("ModularReleaseVisual") as Node3D
	_expect(tires != null and tires.visible, "No aparece mejora de ruedas.")
	_expect(airbags != null and airbags.visible, "Se perdieron airbags.")
	_expect(camera != null and camera.visible, "Se perdió cámara orientable.")
	_expect(release != null and release.visible, "Se perdió liberación modular.")
	_expect(registry.has_discovery(APOLLO11) and registry.has_discovery(MODULE),
		"El Archivo perdió el capítulo Apollo 11.")
	if errors.is_empty():
		print("PASS: Apollo 11 -> fallo de tracción -> abuelo -> Apollo 15 -> Archivo -> ruedas mejoradas.")
		quit(0)
	else:
		for error in errors:
			printerr("FAIL: ", error)
		quit(1)
