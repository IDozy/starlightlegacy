extends SceneTree
## Contrato Opportunity: NO ejecutar aún. Godot Desktop/Web pendiente.
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/opportunity_power_story_loop_smoke.gd

const PREVIOUS := [
	"rescue_rover_airbag_upgrade",
	"rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade",
	"rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade",
	"rescue_rover_science_verification_upgrade",
	"rescue_rover_slip_guard_upgrade",
	"viking_1",
	"spirit"
]
const POWER_PROBLEM := "rescue_rover_low_light_problem"
const OPPORTUNITY := "opportunity"
const POWER_UPGRADE := "rescue_rover_power_budget_upgrade"
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: KnowledgeRegistry no disponible.")
		quit(1)
		return
	for key in PREVIOUS:
		registry.call("register_discovery", key, key, "Prueba", "Resultado de prueba.")

	var project_scene := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var grandfather_scene := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	var memory_scene := load("res://levels/opportunity/opportunity_memory.tscn") as PackedScene
	if project_scene == null or grandfather_scene == null or memory_scene == null:
		printerr("FAIL: no cargaron las escenas Opportunity.")
		quit(1)
		return

	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_expect(str(project.call("get_interaction_prompt")).contains("luz solar"),
		"Después de Spirit debe comenzar el reto de poca luz.")
	_expect(not registry.has_discovery(POWER_PROBLEM),
		"El problema no debe aparecer antes de hacer la prueba.")
	project.call("_record_low_light_failure")
	_expect(registry.has_discovery(POWER_PROBLEM), "No registró el fallo energético.")

	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Opportunity"),
		"El abuelo no introduce Opportunity.")

	var memory := memory_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var rover := memory.get_node_or_null("OpportunityMarsRover") as Node3D
	var console := memory.get_node_or_null("OpportunityPowerConsole") as StaticBody3D
	_expect(rover != null, "Falta el rover provisional Opportunity.")
	_expect(console != null, "Falta consola de energía Opportunity.")

	if rover != null and console != null:
		_expect(bool(rover.call("has_six_wheels")), "Opportunity tenía seis ruedas.")
		_expect(rover.get_node_or_null("MERHardware/SpiritHardware/SolarPanel_L") != null,
			"Falta el panel solar MER.")
		_expect(rover.get_node_or_null("MERHardware/SpiritHardware/CameraMast") != null,
			"Falta mástil de cámaras MER.")
		_expect(not registry.has_discovery(OPPORTUNITY),
			"No debe desbloquearse sin superar decisiones.")

		console.set("_choice", 0)
		console.call("_confirm_light")
		_expect(not bool(console.get("_light_observed")),
			"Reorientar el panel no despeja la tormenta.")
		console.set("_choice", 1)
		console.call("_confirm_light")
		_expect(bool(console.get("_light_observed")),
			"No se midió la disminución de luz.")
		_expect(bool(rover.get("_light_observed")), "No se mostró caída de iluminación.")

		console.set("_choice", 0)
		console.call("_confirm_budget")
		_expect(not bool(console.get("_power_budget_protected")),
			"No debe conservar todos los consumos al máximo.")
		console.set("_choice", 1)
		console.call("_confirm_budget")
		_expect(bool(console.get("_power_budget_protected")),
			"Falta el presupuesto de energía.")
		_expect(bool(rover.get("_power_guard_enabled")),
			"No se refleja la activación de ahorro.")

		console.set("_choice", 0)
		console.call("_confirm_history")
		_expect(not registry.has_discovery(OPPORTUNITY),
			"La historia no debe decir que Opportunity volvió a comunicarse.")
		console.set("_choice", 1)
		console.call("_confirm_history")
		_expect(bool(console.get("_history_respected")),
			"No reconoce el final real de la misión.")
		_expect(registry.has_discovery(OPPORTUNITY),
			"No se registró Opportunity en Archivo NASA.")

	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"Falta portal de regreso tras el recuerdo.")
	var entry: Dictionary = registry.call("get_catalog_entry", OPPORTUNITY)
	_expect(int(entry.get("year", 0)) == 2018,
		"El Archivo debe listar el año de la última señal.")
	_expect(str(entry.get("history", "")).contains("2019"),
		"El Archivo debe distinguir última señal y cierre de misión.")
	_expect(str(entry.get("application_discovery_id", "")) == POWER_UPGRADE,
		"Falta vincular ficha Opportunity con mejora escolar.")

	project.call("_open_low_light_upgrade")
	project.set("_light_selection", 0)
	project.call("_confirm_low_light_upgrade")
	_expect(not registry.has_discovery(POWER_UPGRADE),
		"Ignorar el consumo nunca debe aplicar mejora.")
	project.set("_light_selection", 1)
	project.call("_confirm_low_light_upgrade")
	_expect(registry.has_discovery(POWER_UPGRADE),
		"No se instaló el presupuesto energético.")
	var power := project.get_node_or_null("PowerBudgetUpgradeVisual") as Node3D
	var slip := project.get_node_or_null("SlipSafetyUpgradeVisual") as Node3D
	var science := project.get_node_or_null("ScienceVerificationUpgradeVisual") as Node3D
	var traction := project.get_node_or_null("TractionWheelUpgradeVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	_expect(power != null and power.visible, "Módulo de energía no visible.")
	_expect(slip != null and slip.visible, "Se perdió el detector de Spirit.")
	_expect(science != null and science.visible, "Se perdió la mejora Viking.")
	_expect(traction != null and traction.visible, "Se perdió la mejora Apollo 15.")
	_expect(airbags != null and airbags.visible, "Se perdió la amortiguación.")
	for key in PREVIOUS:
		_expect(registry.has_discovery(key), "Se perdió descubrimiento previo: " + key)

	if failures.is_empty():
		print("PASS: Spirit -> luz baja -> abuelo -> Opportunity -> Archivo -> presupuesto.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
