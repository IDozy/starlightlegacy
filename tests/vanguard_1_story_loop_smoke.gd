extends SceneTree

# Ejecutar en raiz del proyecto:
# godot --headless --editor --path . --quit
# godot --headless --path . --script res://tests/vanguard_1_story_loop_smoke.gd
#
# Prueba el fallo inicial, el recuerdo, el Archivo y la mejora del taller.
# No altera la historia original de Pathfinder/Sojourner.

const IMPACT_PROBLEM := "rescue_rover_impact_problem"
const PATHFINDER := "mars_pathfinder_lander"
const SOJOURNER := "sojourner_apxs"
const AIRBAG_UPGRADE := "rescue_rover_airbag_upgrade"
const ENERGY_PROBLEM := "rescue_rover_energy_problem"
const VANGUARD := "vanguard_1"
const SOLAR_UPGRADE := "rescue_rover_solar_upgrade"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _record(registry: Node, id: String) -> void:
	registry.call("register_discovery", id, id, "Proyecto", "Prueba temporal.")


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: falta el autoload KnowledgeRegistry")
		quit(1)
		return

	var project_scene := load("res://systems/gameplay/rescue_rover_project.tscn") as PackedScene
	var memory_scene := load("res://levels/vanguard_1/vanguard_1_memory.tscn") as PackedScene
	var grandfather_scene := load("res://systems/dialogue/grandfather_placeholder.tscn") as PackedScene
	if project_scene == null or memory_scene == null or grandfather_scene == null:
		printerr("FAIL: falta una de las escenas del ciclo del recuerdo")
		quit(1)
		return

	_record(registry, IMPACT_PROBLEM)
	_record(registry, PATHFINDER)
	_record(registry, SOJOURNER)

	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_check(project.get_node_or_null("SolarUpgradeVisual") != null,
		"Falta el panel solar como mejora visual modular.")
	_check(not registry.has_discovery(AIRBAG_UPGRADE),
		"La prueba arranco con una mejora de amortiguacion indebida.")

	project.call("_register_upgrade")
	_check(registry.has_discovery(AIRBAG_UPGRADE),
		"La amortiguacion anterior debe seguir desbloqueandose.")
	_check(not registry.has_discovery(ENERGY_PROBLEM),
		"La falla de energia no debe suceder antes de la prueba.")
	project.call("_record_energy_failure")
	_check(registry.has_discovery(ENERGY_PROBLEM),
		"El fallo de bateria no se registra.")

	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_check(str(grandfather.call("get_interaction_prompt")).contains("Vanguard"),
		"El abuelo no abre su segundo relato despues del impacto.")

	var memory := memory_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var station := memory.get_node_or_null("VanguardEnergyStation") as StaticBody3D
	_check(station != null, "Falta la consola interactiva de energia.")
	if station != null:
		station.call("_start_test")
		for _step in range(3):
			station.call("_advance_test")
		_check(not registry.has_discovery(VANGUARD),
			"No se debe descubrir Vanguard 1 al fallar con bateria sola.")
		_check(bool(station.get("_battery_tested")),
			"No se activo el desbloqueo del modo solar tras el fallo.")
		station.set("_mode", 1)
		station.call("_start_test")
		for _step in range(4):
			station.call("_advance_test")
		_check(registry.has_discovery(VANGUARD),
			"Vanguard 1 no se registra al completar la comparacion solar.")
		_check(int(station.get("_energy")) > 0,
			"El modo solar deberia conservar energia en la analogia.")

	_check(memory.get_node_or_null("ReturnToWorkshop") != null,
		"El portal de regreso no se desbloqueo.")
	var entry: Dictionary = registry.call("get_catalog_entry", VANGUARD)
	_check(str(entry.get("application_discovery_id", "")) == SOLAR_UPGRADE,
		"La ficha de Vanguard no conecta a la mejora energetica.")

	project.call("_open_solar_upgrade")
	project.set("_energy_selection", 1)
	project.call("_confirm_solar_upgrade")
	_check(registry.has_discovery(SOLAR_UPGRADE),
		"El Vehiculo Explorador no aplica el panel solar y ahorro.")
	var solar_visual := project.get_node_or_null("SolarUpgradeVisual") as Node3D
	_check(solar_visual != null and solar_visual.visible,
		"La mejora solar no aparece fisicamente en el vehiculo.")
	_check(project.get_node_or_null("UpgradeVisual") != null,
		"La amortiguacion anterior desaparecio al mejorar energia.")

	if failures.is_empty():
		print("PASS: impacto -> bateria -> abuelo -> Vanguard -> Archivo -> panel solar.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
