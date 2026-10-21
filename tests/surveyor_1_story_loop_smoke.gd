extends SceneTree
## Contrato narrativo Surveyor 1: despues de Vanguard, sin alterar
## descubrimientos anteriores, Archivo NASA y decisiones Continuar/Saber mas.
##
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/surveyor_1_story_loop_smoke.gd

const IMPACT_ID := "rescue_rover_airbag_upgrade"
const VANGUARD_ID := "vanguard_1"
const SOLAR_UPGRADE_ID := "rescue_rover_solar_upgrade"
const ORIENTATION_PROBLEM_ID := "rescue_rover_orientation_problem"
const SURVEYOR_ID := "surveyor_1"
const ORIENTATION_UPGRADE_ID := "rescue_rover_orientation_upgrade"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(actual: bool, message: String) -> void:
	if not actual:
		failures.append(message)


func _record(registry: Node, id: String) -> void:
	registry.call("register_discovery", id, id, "Prueba", "Prueba temporal.")


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: KnowledgeRegistry autoload no disponible.")
		quit(1)
		return
	for prerequisite in [IMPACT_ID, VANGUARD_ID, SOLAR_UPGRADE_ID]:
		_record(registry, prerequisite)

	var project_scene := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var grandfather_scene := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	var moon_scene := load("res://levels/surveyor_1/surveyor_1_memory.tscn") as PackedScene
	if project_scene == null or grandfather_scene == null or moon_scene == null:
		printerr("FAIL: alguna escena del ciclo de Surveyor 1 no carga.")
		quit(1)
		return

	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_check(str(project.call("get_interaction_prompt")).contains("orientacion"),
		"El proyecto no ofrece el tercer fallo tras el upgrade solar.")
	_check(registry.has_discovery(IMPACT_ID),
		"El proyecto debe conservar amortiguacion de Pathfinder.")

	project.call("_record_orientation_failure")
	_check(registry.has_discovery(ORIENTATION_PROBLEM_ID),
		"El fallo de orientacion no se guarda.")

	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_check(str(grandfather.call("get_interaction_prompt")).contains("Surveyor 1"),
		"El abuelo no ofrece el recuerdo de Surveyor tras el fallo.")
	_check(not registry.has_discovery(SURVEYOR_ID),
		"Surveyor se desbloqueó antes de completar el reto.")

	var moon := moon_scene.instantiate() as Node3D
	root.add_child(moon)
	await process_frame
	var lander := moon.get_node_or_null("Surveyor1Lander") as Node3D
	var console := moon.get_node_or_null("SurveyorCommandConsole") as StaticBody3D
	_check(lander != null, "Falta modelo temporal Surveyor 1.")
	_check(console != null, "Falta consola educativa Surveyor 1.")
	if console != null and lander != null:
		_check(lander.get_node_or_null("ArtifactModel/SolarPanelStaticPreview") != null,
			"Falta panel reorientable del greybox.")
		_check(lander.get_node_or_null("ArtifactModel/TV_Camera") != null,
			"Falta camara del greybox.")
		_check(int(console.get("_stage")) == 0,
			"La prueba debe comenzar con orientación solar.")
		console.set("_panel_choice", 1)
		console.call("_confirm_panel_command")
		_check(not bool(console.get("_panel_aligned")),
			"Orden solar incorrecta no puede aprobar.")
		console.set("_panel_choice", 2)
		console.call("_confirm_panel_command")
		_check(bool(console.get("_panel_aligned")),
			"Fallo al alinear el panel solar.")
		console.set("_camera_choice", 1)
		console.call("_confirm_camera_command")
		_check(not bool(console.get("_camera_aligned")),
			"Orden incorrecta de camara no puede aprobar.")
		console.set("_camera_choice", 0)
		console.call("_confirm_camera_command")
		_check(bool(console.get("_camera_aligned")),
			"Fallo al orientar la camara.")
		_check(not registry.has_discovery(SURVEYOR_ID),
			"Surveyor no debe registrarse sin transmitir la imagen.")
		console.call("_confirm_image_command")
		_check(bool(console.get("_image_received")),
			"Simulador no confirma recepcion de la imagen.")
		_check(registry.has_discovery(SURVEYOR_ID),
			"Surveyor no aparece en Archivo NASA al terminar.")

	_check(moon.get_node_or_null("ReturnToWorkshop") != null,
		"No se desbloquea regreso al taller.")

	var entry: Dictionary = registry.call("get_catalog_entry", SURVEYOR_ID)
	_check(int(entry.get("year", 0)) == 1966, "Surveyor mal fechado en el Archivo.")
	_check(str(entry.get("application_discovery_id", "")) == ORIENTATION_UPGRADE_ID,
		"El Archivo no vincula Surveyor con la mejora del proyecto.")

	project.call("_open_orientation_upgrade")
	project.set("_orientation_selection", 0)
	project.call("_confirm_orientation_upgrade")
	_check(not registry.has_discovery(ORIENTATION_UPGRADE_ID),
		"Una solucion incorrecta no debe desbloquear la mejora.")
	project.set("_orientation_selection", 1)
	project.call("_confirm_orientation_upgrade")
	_check(registry.has_discovery(ORIENTATION_UPGRADE_ID),
		"No se aplica la mejora de panel y camara.")
	var adjustable := project.get_node_or_null("OrientationUpgradeVisual") as Node3D
	var old_solar := project.get_node_or_null("SolarUpgradeVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	_check(adjustable != null and adjustable.visible,
		"No aparece el modelo ajustable en el vehículo.")
	_check(old_solar != null and not old_solar.visible,
		"El panel fijo anterior se superpone al panel regulable.")
	_check(airbags != null and airbags.visible,
		"Se perdio la mejora de amortiguacion anterior.")

	if failures.is_empty():
		print("PASS: Vanguard -> fallo -> Abuelo -> Surveyor 1 -> Archivo -> mejora orientable.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
