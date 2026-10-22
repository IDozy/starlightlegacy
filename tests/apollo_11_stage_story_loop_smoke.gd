extends SceneTree
## Secuencia histórica y jugable Apollo 11. Pendiente ejecutar en Godot:
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/apollo_11_stage_story_loop_smoke.gd
##
## No modifica la campaña actual en repositorio; registra descubrimientos
## temporales en el autoload de este proceso de prueba.

const ORIENTATION_UPGRADE := "rescue_rover_orientation_upgrade"
const SURVEYOR := "surveyor_1"
const SOLAR := "rescue_rover_solar_upgrade"
const IMPACT := "rescue_rover_airbag_upgrade"
const MODULE_PROBLEM := "rescue_rover_module_separation_problem"
const APOLLO := "apollo_11_descent_stage"
const MODULE_UPGRADE := "rescue_rover_modular_release_upgrade"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _record(registry: Node, id: String) -> void:
	registry.call("register_discovery", id, id, "Prueba", "Estado de prueba")


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: autoload KnowledgeRegistry ausente.")
		quit(1)
		return
	for id in [IMPACT, SOLAR, SURVEYOR, ORIENTATION_UPGRADE]:
		_record(registry, id)

	var project_scene := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var grandpa_scene := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	var scene := load("res://levels/apollo_11/apollo_11_memory.tscn") as PackedScene
	if project_scene == null or grandpa_scene == null or scene == null:
		printerr("FAIL: recurso de historia Apollo 11 no disponible.")
		quit(1)
		return

	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_check(str(project.call("get_interaction_prompt")).contains("base auxiliar"),
		"La prueba de la base debe activarse despues de Surveyor.")
	_check(not registry.has_discovery(MODULE_PROBLEM),
		"El fallo solo debe registrarse despues de probar el vehículo.")

	project.call("_record_module_failure")
	_check(registry.has_discovery(MODULE_PROBLEM),
		"No se registró el problema de separación modular.")

	var grandpa := grandpa_scene.instantiate() as StaticBody3D
	root.add_child(grandpa)
	await process_frame
	_check(str(grandpa.call("get_interaction_prompt")).contains("Apollo 11"),
		"Abuelo no habilita recuerdo Apollo 11 tras el nuevo fallo.")
	_check(not registry.has_discovery(APOLLO),
		"El recuerdo se desbloqueó sin superar el ejercicio.")

	var memory := scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var lander := memory.get_node_or_null("EagleLunarModule") as Node3D
	var console := memory.get_node_or_null("Apollo11StageConsole") as StaticBody3D
	_check(lander != null, "Falta el greybox Eagle.")
	_check(console != null, "Falta la consola de separación.")
	if lander != null and console != null:
		_check(bool(lander.call("stage_nodes_exist")),
			"El Eagle debe tener ambas etapas.")
		_check(lander.get_node_or_null("DescentStage/Footpad_0") != null,
			"Falta plataforma lunar de descenso con patas.")
		_check(lander.get_node_or_null("AscentStage/CrewCabin") != null,
			"Falta etapa de ascenso con cabina.")
		console.set("_selection", 1)
		console.call("_confirm_identification")
		_check(int(console.get("_stage")) == 0,
			"Respuesta incorrecta no debe aprobar identificación.")
		console.set("_selection", 0)
		console.call("_confirm_identification")
		_check(int(console.get("_stage")) == 1,
			"El recuerdo debe pasar a comprobar la plataforma.")
		console.set("_selection", 0)
		console.call("_confirm_support")
		_check(not bool(console.get("_support_checked")),
			"Retirar las patas es una solución equivocada.")
		console.set("_selection", 1)
		console.call("_confirm_support")
		_check(bool(console.get("_support_checked")),
			"No se confirmó la base estable.")
		console.set("_selection", 0)
		console.call("_confirm_release")
		_check(not bool(console.get("_released")),
			"El recuerdo no debe despegar las dos etapas juntas.")
		console.set("_selection", 1)
		console.call("_confirm_release")
		_check(bool(console.get("_released")),
			"No se decidió separar las etapas.")
		_check(not registry.has_discovery(APOLLO),
			"No se debe registrar el descubrimiento antes del despegue.")
		console.call("_confirm_ascent")
		_check(registry.has_discovery(APOLLO),
			"El Archivo NASA no recibió la etapa de descenso.")
		_check(bool(lander.call("descent_stage_still_on_ground")),
			"La plataforma de descenso no debe abandonar la Luna.")
		_check(not bool(lander.call("launch_ascent_preview")),
			"Una segunda orden no debe lanzar la cabina otra vez.")

	_check(memory.get_node_or_null("ReturnToWorkshop") != null,
		"El portal del taller no se desbloqueó.")
	var entry: Dictionary = registry.call("get_catalog_entry", APOLLO)
	_check(int(entry.get("year", 0)) == 1969,
		"La etapa de descenso debe estar en el año 1969.")
	_check(str(entry.get("application_discovery_id", "")) == MODULE_UPGRADE,
		"Falta conexión del artículo con la mejora modular.")

	project.call("_open_module_upgrade")
	project.set("_module_selection", 0)
	project.call("_confirm_module_upgrade")
	_check(not registry.has_discovery(MODULE_UPGRADE),
		"No debe premiarse retirar las ruedas.")
	project.set("_module_selection", 1)
	project.call("_confirm_module_upgrade")
	_check(registry.has_discovery(MODULE_UPGRADE),
		"El rover no aplicó el mecanismo modular.")
	var transport := project.get_node_or_null("TransportBaseVisual") as Node3D
	var detached := project.get_node_or_null("ReleasedBaseVisual") as Node3D
	var mechanism := project.get_node_or_null("ModularReleaseVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	var camera := project.get_node_or_null("OrientationUpgradeVisual") as Node3D
	_check(transport != null and not transport.visible,
		"Base auxiliar antigua sigue superpuesta al rover.")
	_check(detached != null and detached.visible,
		"La base auxiliar no queda en el taller.")
	_check(mechanism != null and mechanism.visible,
		"No se agregó mecanismo de desacoplamiento.")
	_check(airbags != null and airbags.visible,
		"No conservaron las protecciones de Pathfinder.")
	_check(camera != null and camera.visible,
		"Se perdió orientación de Surveyor.")
	_check(registry.has_discovery(SURVEYOR) and registry.has_discovery(IMPACT),
		"Se perdieron hitos históricos previos.")

	if failures.is_empty():
		print("PASS: rover -> abuelo -> Apollo 11 -> Archivo -> base liberable.")
		quit(0)
	else:
		for reason in failures:
			printerr("FAIL: ", reason)
		quit(1)
