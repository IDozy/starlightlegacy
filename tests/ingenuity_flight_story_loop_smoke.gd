extends SceneTree
## Contrato Ingenuity preparado; ejecutar posteriormente en Godot Desktop/Web.
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/ingenuity_flight_story_loop_smoke.gd

const PREVIOUS := [
	"rescue_rover_airbag_upgrade",
	"rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade",
	"rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade",
	"rescue_rover_science_verification_upgrade",
	"rescue_rover_slip_guard_upgrade",
	"rescue_rover_power_budget_upgrade",
	"rescue_rover_touchdown_release_upgrade",
	"perseverance_sky_crane",
	"opportunity",
	"spirit",
	"viking_1"
]
const PROBLEM := "rescue_rover_aerial_scout_problem"
const DISCOVERY := "ingenuity"
const UPGRADE := "rescue_rover_aerial_scout_upgrade"
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
	var memory_scene := load("res://levels/ingenuity/ingenuity_memory.tscn") as PackedScene
	if project_scene == null or grandfather_scene == null or memory_scene == null:
		printerr("FAIL: escenas Ingenuity ausentes.")
		quit(1)
		return

	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_expect(str(project.call("get_interaction_prompt")).contains("reconocimiento aéreo"),
		"Después de Sky Crane debe aparecer la prueba de reconocimiento.")
	_expect(not registry.has_discovery(PROBLEM), "Problema registrado antes de la prueba.")
	project.call("_record_aerial_failure")
	_expect(registry.has_discovery(PROBLEM), "No registró el obstáculo no visible.")
	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Ingenuity"),
		"El abuelo no introduce Ingenuity.")

	var memory := memory_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var helicopter := memory.get_node_or_null("IngenuityMarsHelicopter") as Node3D
	var console := memory.get_node_or_null("IngenuityFlightConsole") as StaticBody3D
	_expect(helicopter != null, "Falta el helicóptero provisional.")
	_expect(console != null, "Falta la consola del recuerdo.")
	if helicopter != null and console != null:
		# Regresión de formato: al usar el operador % de GDScript, el
		# porcentaje literal de la atmósfera debe escapar como %%.
		console.call("_show")
		var description: Label = console.get("_description") as Label
		_expect(description != null, "La consola de Ingenuity no tiene descripción.")
		if description != null:
			_expect(description.text.contains("1% de la presión"),
				"La atmósfera debe mostrarse como 1% sin error de formato.")
			_expect(description.text.contains("AERONAVE LIGERA"),
				"Faltan las opciones del primer desafío de Ingenuity.")
		_expect(bool(helicopter.call("has_twin_counter_rotors")), "Faltan rotores coaxiales.")
		_expect(bool(helicopter.call("has_four_legs")), "Ingenuity tenía cuatro patas.")
		_expect(not bool(helicopter.call("begin_controlled_hover")),
			"No volar antes de preparar la maqueta.")
		_expect(not bool(helicopter.call("complete_scout_and_land")),
			"No se puede completar vuelo sin despegue.")
		_expect(not registry.has_discovery(DISCOVERY), "Descubrimiento prematuro.")
		console.set("_choice", 0)
		console.call("_confirm_air")
		_expect(not bool(console.get("_prepared")), "No validar aeronave pesada.")
		console.set("_choice", 1)
		console.call("_confirm_air")
		_expect(bool(console.get("_prepared")), "No preparó vuelo con aire tenue.")
		console.set("_choice", 0)
		console.call("_confirm_rotors")
		_expect(not bool(console.get("_hovering")), "No validar rotores en igual sentido.")
		console.set("_choice", 1)
		console.call("_confirm_rotors")
		_expect(bool(console.get("_hovering")), "No inició vuelo controlado.")
		console.set("_choice", 0)
		console.call("_confirm_scout")
		_expect(not registry.has_discovery(DISCOVERY),
			"No afirmar que Ingenuity voló después del último vuelo.")
		console.set("_choice", 1)
		console.call("_confirm_scout")
		_expect(bool(console.get("_returned")), "Falta aterrizaje del vuelo didáctico.")
		_expect(bool(helicopter.call("is_grounded_after_scout")),
			"El helicóptero debe quedar en el suelo.")
		_expect(registry.has_discovery(DISCOVERY), "No registró Ingenuity.")

	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"Falta portal para regresar al taller.")
	var entry: Dictionary = registry.call("get_catalog_entry", DISCOVERY)
	_expect(int(entry.get("year", 0)) == 2024,
		"El catálogo debe mantener la fecha de último vuelo de 2024.")
	_expect(str(entry.get("history", "")).contains("2021"),
		"El catálogo debe incluir el primer vuelo de 2021.")
	_expect(str(entry.get("history", "")).contains("2024"),
		"El catálogo debe explicar el final de la misión.")
	_expect(str(entry.get("application_discovery_id", "")) == UPGRADE,
		"No se vinculó al explorador escolar.")

	project.call("_open_aerial_upgrade")
	project.set("_aerial_selection", 0)
	project.call("_confirm_aerial_upgrade")
	_expect(not registry.has_discovery(UPGRADE),
		"No equipar el rover terrestre con rotores improvisados.")
	project.set("_aerial_selection", 1)
	project.call("_confirm_aerial_upgrade")
	_expect(registry.has_discovery(UPGRADE), "No instaló explorador auxiliar.")
	var scout := project.get_node_or_null("AerialScoutUpgradeVisual") as Node3D
	var delivery := project.get_node_or_null("TouchdownReleaseUpgradeVisual") as Node3D
	var energy := project.get_node_or_null("PowerBudgetUpgradeVisual") as Node3D
	var slip := project.get_node_or_null("SlipSafetyUpgradeVisual") as Node3D
	_expect(scout != null and scout.visible, "No se ve explorador auxiliar.")
	_expect(delivery != null and delivery.visible, "Se perdió Sky Crane.")
	_expect(energy != null and energy.visible, "Se perdió Opportunity.")
	_expect(slip != null and slip.visible, "Se perdió Spirit.")
	for key in PREVIOUS:
		_expect(registry.has_discovery(key), "Se perdió avance anterior: " + key)
	if failures.is_empty():
		print("PASS: Sky Crane -> obstáculo -> abuelo -> Ingenuity -> Archivo -> explorador aéreo.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
