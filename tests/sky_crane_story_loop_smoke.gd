extends SceneTree
## Contrato Sky Crane, preparar ahora y ejecutar solo en validación posterior.
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/sky_crane_story_loop_smoke.gd

const PREVIOUS := [
	"rescue_rover_airbag_upgrade",
	"rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade",
	"rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade",
	"rescue_rover_science_verification_upgrade",
	"rescue_rover_slip_guard_upgrade",
	"rescue_rover_power_budget_upgrade",
	"opportunity",
	"spirit",
	"viking_1"
]
const PROBLEM := "rescue_rover_delivery_problem"
const DISCOVERY := "perseverance_sky_crane"
const UPGRADE := "rescue_rover_touchdown_release_upgrade"
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
	var memory_scene := load("res://levels/perseverance_sky_crane/sky_crane_memory.tscn") as PackedScene
	if project_scene == null or grandfather_scene == null or memory_scene == null:
		printerr("FAIL: escenas Sky Crane ausentes.")
		quit(1)
		return
	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_expect(str(project.call("get_interaction_prompt")).contains("descenso"),
		"Tras Opportunity debe comenzar la prueba de entrega.")
	_expect(not registry.has_discovery(PROBLEM), "Problema registrado antes de la prueba.")
	project.call("_record_delivery_failure")
	_expect(registry.has_discovery(PROBLEM), "No registró entrega prematura.")
	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Sky Crane"),
		"El abuelo no propone la memoria Sky Crane.")
	var memory := memory_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var rig := memory.get_node_or_null("SkyCraneLandingRig") as Node3D
	var console := memory.get_node_or_null("SkyCraneLandingConsole") as StaticBody3D
	_expect(rig != null, "Falta maqueta Sky Crane.")
	_expect(console != null, "Falta consola Sky Crane.")

	if rig != null and console != null:
		_expect(bool(rig.call("rig_parts_exist")), "Faltan etapas del modelo.")
		_expect(rig.get_node_or_null("PerseveranceRover/CameraMast") != null,
			"Falta el rover independiente.")
		_expect(rig.get_node_or_null("PoweredDescentStage/EightEngineFrame") != null,
			"Falta etapa de descenso.")
		_expect(not bool(rig.call("cut_cables_and_fly_away")),
			"No puede separarse una etapa antes del contacto.")
		_expect(not registry.has_discovery(DISCOVERY), "Recuerdo registrado antes de resolver.")
		console.set("_choice", 0)
		console.call("_confirm_site")
		_expect(not bool(console.get("_safe_site")), "No debe ignorar obstáculos.")
		console.set("_choice", 1)
		console.call("_confirm_site")
		_expect(bool(console.get("_safe_site")), "Falta elección de sitio seguro.")
		console.set("_choice", 0)
		console.call("_confirm_lowering")
		_expect(not bool(console.get("_lowered")), "No se puede soltar rover en caída.")
		console.set("_choice", 1)
		console.call("_confirm_lowering")
		_expect(bool(console.get("_lowered")), "Falta descenso suspendido.")
		_expect(not bool(rig.call("cut_cables_and_fly_away")),
			"No cortar cables hasta confirmar touchdown.")
		console.set("_choice", 0)
		console.call("_confirm_separation")
		_expect(not bool(console.get("_released")), "Liberación prematura aprobada.")
		console.set("_choice", 1)
		console.call("_confirm_separation")
		_expect(bool(console.get("_released")), "No se completó separación segura.")
		_expect(bool(rig.get("_touchdown_confirmed")), "No se confirmó apoyo.")
		_expect(bool(rig.get("_cables_cut")), "Cables sin liberar.")
		_expect(bool(rig.get("_stage_flew_away")), "Etapa debe alejarse.")
		_expect(bool(rig.call("rover_remains_landed")), "Rover debe quedar en Jezero.")
		_expect(registry.has_discovery(DISCOVERY), "Falta el Archivo NASA.")
	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"Portal de regreso no se habilitó.")
	var entry: Dictionary = registry.call("get_catalog_entry", DISCOVERY)
	_expect(int(entry.get("year", 0)) == 2021, "Cronología incorrecta de aterrizaje.")
	_expect(str(entry.get("application_discovery_id", "")) == UPGRADE,
		"Archivo no está enlazado con mejora escolar.")
	_expect(str(entry.get("history", "")).contains("Jezero"),
		"No se ubicó cráter Jezero.")
	project.call("_open_delivery_upgrade")
	project.set("_delivery_selection", 0)
	project.call("_confirm_delivery_upgrade")
	_expect(not registry.has_discovery(UPGRADE), "Soltar antes de touchdown no vale.")
	project.set("_delivery_selection", 1)
	project.call("_confirm_delivery_upgrade")
	_expect(registry.has_discovery(UPGRADE), "Falta mejora de entrega segura.")
	var indicator := project.get_node_or_null("TouchdownReleaseUpgradeVisual") as Node3D
	var energy := project.get_node_or_null("PowerBudgetUpgradeVisual") as Node3D
	var slip := project.get_node_or_null("SlipSafetyUpgradeVisual") as Node3D
	var science := project.get_node_or_null("ScienceVerificationUpgradeVisual") as Node3D
	_expect(indicator != null and indicator.visible, "No se ve seguro de liberación.")
	_expect(energy != null and energy.visible, "Se perdió presupuesto energético.")
	_expect(slip != null and slip.visible, "Se perdió sensor de Spirit.")
	_expect(science != null and science.visible, "Se perdió ciencia Viking.")
	for key in PREVIOUS:
		_expect(registry.has_discovery(key), "Desapareció un avance previo: " + key)
	if failures.is_empty():
		print("PASS: Opportunity -> entrega -> abuelo -> Sky Crane -> aterrizaje -> Archivo -> mejora.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
