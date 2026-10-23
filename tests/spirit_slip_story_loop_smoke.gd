extends SceneTree
## Contrato Spirit, pendiente de ejecutar en Godot Desktop/Web.
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/spirit_slip_story_loop_smoke.gd

const PREVIOUS := [
	"rescue_rover_airbag_upgrade",
	"rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade",
	"rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade",
	"rescue_rover_science_verification_upgrade",
	"viking_1"
]
const SLIP_PROBLEM := "rescue_rover_slip_problem"
const SPIRIT := "spirit"
const SLIP_UPGRADE := "rescue_rover_slip_guard_upgrade"

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
	var memory_scene := load("res://levels/spirit/spirit_memory.tscn") as PackedScene
	if project_scene == null or grandfather_scene == null or memory_scene == null:
		printerr("FAIL: faltan escenas Spirit.")
		quit(1)
		return
	var project := project_scene.instantiate() as StaticBody3D
	root.add_child(project)
	await process_frame
	_expect(str(project.call("get_interaction_prompt")).contains("deslizamiento"),
		"Tras Viking no se ofrece la prueba de patinaje.")
	_expect(not registry.has_discovery(SLIP_PROBLEM),
		"El fallo no debe registrarse antes de la prueba.")
	project.call("_record_slip_failure")
	_expect(registry.has_discovery(SLIP_PROBLEM), "Falta registrar el fallo.")
	var grandfather := grandfather_scene.instantiate() as StaticBody3D
	root.add_child(grandfather)
	await process_frame
	_expect(str(grandfather.call("get_interaction_prompt")).contains("Spirit"),
		"El abuelo no reconoce el siguiente recuerdo.")
	var memory := memory_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var rover := memory.get_node_or_null("SpiritMarsRover") as Node3D
	var console := memory.get_node_or_null("SpiritSlipConsole") as StaticBody3D
	_expect(rover != null, "Falta modelo greybox Spirit.")
	_expect(console != null, "Falta consola de seguridad.")
	if rover != null and console != null:
		_expect(bool(rover.call("has_six_wheels")), "Spirit debe tener seis ruedas.")
		_expect(rover.get_node_or_null("SpiritHardware/SolarPanel_L") != null,
			"Faltan paneles solares en Spirit.")
		_expect(rover.get_node_or_null("SpiritHardware/CameraMast") != null,
			"Falta el mástil de cámaras.")
		_expect(not registry.has_discovery(SPIRIT), "Descubrimiento prematuro.")
		console.set("_choice", 0)
		console.call("_confirm_detection")
		_expect(not bool(console.get("_stopped")),
			"Acelerar en terreno blando no puede aprobar.")
		console.set("_choice", 1)
		console.call("_confirm_detection")
		_expect(bool(console.get("_stopped")), "Falta parada segura.")
		console.set("_choice", 0)
		console.call("_confirm_assessment")
		_expect(not bool(console.get("_risk_checked")), "Forzar ruedas no es evaluación.")
		console.set("_choice", 1)
		console.call("_confirm_assessment")
		_expect(bool(console.get("_risk_checked")), "Falta comprobación de riesgo.")
		console.set("_choice", 0)
		console.call("_confirm_decision")
		_expect(not registry.has_discovery(SPIRIT),
			"No se debe afirmar que Spirit salió de Troy.")
		console.set("_choice", 1)
		console.call("_confirm_decision")
		_expect(bool(console.get("_science_prioritized")), "No priorizó ciencia.")
		_expect(registry.has_discovery(SPIRIT), "Spirit no figura en Archivo NASA.")
		_expect(bool(rover.get("_stationary_science")), "No se refleja plataforma fija.")
	_expect(memory.get_node_or_null("ReturnToWorkshop") != null,
		"Portal de regreso bloqueado tras completar el recuerdo.")
	var entry: Dictionary = registry.call("get_catalog_entry", SPIRIT)
	_expect(int(entry.get("year", 0)) == 2009, "El recuerdo Troy es de 2009.")
	_expect(str(entry.get("application_discovery_id", "")) == SLIP_UPGRADE,
		"La ficha NASA no enlaza con la mejora.")
	_expect(str(entry.get("history", "")).contains("no logró"),
		"No se explica que Spirit nunca escapó de Troy.")
	project.call("_open_slip_upgrade")
	project.set("_slip_selection", 0)
	project.call("_confirm_slip_upgrade")
	_expect(not registry.has_discovery(SLIP_UPGRADE),
		"Insistir con ruedas no debe autorizar mejora.")
	project.set("_slip_selection", 1)
	project.call("_confirm_slip_upgrade")
	_expect(registry.has_discovery(SLIP_UPGRADE), "Falta aplicar detector de patinaje.")
	var safety := project.get_node_or_null("SlipSafetyUpgradeVisual") as Node3D
	_expect(safety != null and safety.visible, "No se ve telemetría de patinaje.")
	var science := project.get_node_or_null("ScienceVerificationUpgradeVisual") as Node3D
	var traction := project.get_node_or_null("TractionWheelUpgradeVisual") as Node3D
	var airbags := project.get_node_or_null("UpgradeVisual") as Node3D
	_expect(science != null and science.visible, "La mejora Viking se perdió.")
	_expect(traction != null and traction.visible, "La mejora Apollo 15 se perdió.")
	_expect(airbags != null and airbags.visible, "La amortiguación anterior se perdió.")
	for key in PREVIOUS:
		_expect(registry.has_discovery(key), "Se perdió: " + key)
	if failures.is_empty():
		print("PASS: Viking -> fallo de patinaje -> abuelo -> Spirit -> Archivo -> seguridad.")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
