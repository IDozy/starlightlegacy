extends SceneTree
## Contrato Viking 1. Pendiente de ejecutar en Godot:
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/viking_1_science_story_loop_smoke.gd

const AIRBAG := "rescue_rover_airbag_upgrade"
const SOLAR := "rescue_rover_solar_upgrade"
const ORIENTATION := "rescue_rover_orientation_upgrade"
const MODULE := "rescue_rover_modular_release_upgrade"
const TRACTION := "rescue_rover_traction_upgrade"
const APOLLO15 := "apollo_15_lrv"
const SCIENCE_PROBLEM := "rescue_rover_science_verification_problem"
const VIKING := "viking_1"
const SCIENCE_UPGRADE := "rescue_rover_science_verification_upgrade"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)


func _record(registry: Node, key: String) -> void:
	registry.call("register_discovery", key, key, "Prueba", "Resultado de prueba.")


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: KnowledgeRegistry no disponible.")
		quit(1)
		return
	for previous in [AIRBAG, SOLAR, ORIENTATION, MODULE, TRACTION, APOLLO15]:
		_record(registry, previous)

	var project_packed := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var grandfather_packed := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	var memory_packed := load("res://levels/viking_1/viking_1_memory.tscn") as PackedScene
	if project_packed == null or grandfather_packed == null or memory_packed == null:
		printerr("FAIL: no se cargaron todas las escenas Viking.")
		quit(1)
		return

	var project := project_packed.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_expect(str(project.call("get_interaction_prompt")).contains("sensor"),
		"Falta la prueba de análisis tras Apollo 15.")
	_expect(not registry.has_discovery(SCIENCE_PROBLEM),
		"El nuevo problema no debe existir antes de probar el vehículo.")
	project.call("_record_science_failure")
	_expect(registry.has_discovery(SCIENCE_PROBLEM),
		"No registró el problema de verificación.")

	var grandfather := grandfather_packed.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Viking 1"),
		"El abuelo no desbloquea Viking 1 después del fallo.")

	var memory := memory_packed.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var lander := memory.get_node_or_null("Viking1MarsLander") as Node3D
	var console := memory.get_node_or_null("Viking1ScienceConsole") as StaticBody3D
	_expect(lander != null, "Falta el aterrizador independiente.")
	_expect(console != null, "Falta la consola científica.")
	if lander != null and console != null:
		_expect(bool(lander.call("has_three_feet")),
			"Viking 1 tenía tres patas; el greybox está incorrecto.")
		_expect(lander.get_node_or_null("LanderHardware/RTGShield_-1") != null,
			"Falta generador RTG.")
		_expect(lander.get_node_or_null("LanderHardware/PanoramicCamera_0") != null,
			"Falta cámara panorámica.")
		_expect(lander.get_node_or_null("LanderHardware/SoilSamplingArm/SoilScoop") != null,
			"Falta brazo recolector.")
		_expect(not registry.has_discovery(VIKING),
			"Viking no puede desbloquearse antes de terminar el recuerdo.")

		console.set("_choice", 0)
		console.call("_confirm_sample")
		_expect(not bool(console.get("_sample_collected")),
			"El recuerdo no debe usar astronautas inexistentes.")
		console.set("_choice", 1)
		console.call("_confirm_sample")
		_expect(bool(console.get("_sample_collected")),
			"No tomó la muestra con el brazo.")

		console.set("_choice", 0)
		console.call("_confirm_comparison")
		_expect(not bool(console.get("_controls_checked")),
			"La reacción sin controles debe ser insuficiente.")
		console.set("_choice", 1)
		console.call("_confirm_comparison")
		_expect(bool(console.get("_controls_checked")),
			"No aprobó la comprobación de resultados.")

		console.set("_choice", 0)
		console.call("_confirm_conclusion")
		_expect(not registry.has_discovery(VIKING),
			"Afirmar vida en Marte no debe desbloquear la historia.")
		console.set("_choice", 1)
		console.call("_confirm_conclusion")
		_expect(bool(console.get("_responsible_conclusion")),
			"No se reconoció la conclusión con incertidumbre.")
		_expect(registry.has_discovery(VIKING),
			"Viking no figura como descubrimiento tras finalizar.")

	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"No se habilitó el portal al taller.")
	var entry: Dictionary = registry.call("get_catalog_entry", VIKING)
	_expect(int(entry.get("year", 0)) == 1976,
		"Viking 1 debe figurar en 1976.")
	_expect(str(entry.get("application_discovery_id", "")) == SCIENCE_UPGRADE,
		"Archivo NASA sin conexión a la mejora científica.")
	_expect(str(entry.get("engineering", "")).contains("NO pruebas definitivas"),
		"La ficha debe evitar declarar que Viking probó vida.")

	project.call("_open_science_upgrade")
	project.set("_science_selection", 0)
	project.call("_confirm_science_upgrade")
	_expect(not registry.has_discovery(SCIENCE_UPGRADE),
		"Una conclusión apresurada no puede aplicar la mejora.")
	project.set("_science_selection", 1)
	project.call("_confirm_science_upgrade")
	_expect(registry.has_discovery(SCIENCE_UPGRADE),
		"No se aplicó verificación científica al vehículo.")

	var science := project.get_node_or_null("ScienceVerificationUpgradeVisual") as Node3D
	var traction := project.get_node_or_null("TractionWheelUpgradeVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	var camera := project.get_node_or_null("OrientationUpgradeVisual") as Node3D
	var release := project.get_node_or_null("ModularReleaseVisual") as Node3D
	_expect(science != null and science.visible,
		"Falta el registrador de datos.")
	_expect(traction != null and traction.visible, "Se perdió la mejora de tracción.")
	_expect(airbags != null and airbags.visible, "Se perdió la amortiguación.")
	_expect(camera != null and camera.visible, "Se perdió la cámara ajustable.")
	_expect(release != null and release.visible, "Se perdió la liberación modular.")
	_expect(registry.has_discovery(APOLLO15) and registry.has_discovery(VIKING),
		"El Archivo perdió una historia anterior.")

	if failures.is_empty():
		print("PASS: Apollo 15 -> fallo científico -> abuelo -> Viking 1 -> Archivo -> verificación.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
