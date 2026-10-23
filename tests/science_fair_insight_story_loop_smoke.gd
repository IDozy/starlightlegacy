extends SceneTree
## Acceptance contract: science fair finale and optional InSight; NOT EXECUTED.
## godot --headless --path . --script res://tests/science_fair_insight_story_loop_smoke.gd

const REQUIRED := [
	"rescue_rover_airbag_upgrade", "rescue_rover_solar_upgrade",
	"rescue_rover_orientation_upgrade", "rescue_rover_modular_release_upgrade",
	"rescue_rover_traction_upgrade", "rescue_rover_science_verification_upgrade",
	"rescue_rover_slip_guard_upgrade", "rescue_rover_power_budget_upgrade",
	"rescue_rover_touchdown_release_upgrade", "rescue_rover_aerial_scout_upgrade"
]
const FAIR := "rescue_rover_science_fair_completed"
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	if registry == null:
		printerr("FAIL: KnowledgeRegistry autoload missing")
		quit(1)
		return
	var fair_scene := load("res://levels/science_fair/science_fair.tscn") as PackedScene
	var insight_scene := load("res://levels/insight/insight_memory.tscn") as PackedScene
	if fair_scene == null or insight_scene == null:
		printerr("FAIL: final scenes missing")
		quit(1)
		return

	var fair := fair_scene.instantiate() as Node3D
	root.add_child(fair)
	await process_frame
	var kiosk := fair.get_node_or_null("FinalPresentationKiosk") as StaticBody3D
	_check(kiosk != null, "Missing final presentation kiosk")
	_check(not registry.has_discovery(FAIR), "Fair premature")
	if kiosk != null:
		_check(not bool(kiosk.call("is_ready_for_fair")), "Missing upgrades must block fair")
		kiosk.set("_choice", 1)
		kiosk.call("_confirm_safety")
		_check(int(kiosk.get("_step")) == 0, "Cannot bypass required upgrades")
		for id in REQUIRED:
			registry.call("register_discovery", id, id, "Prueba", "Mejora")
		_check(bool(kiosk.call("is_ready_for_fair")), "Fair not ready after upgrades")
		for method in ["_confirm_safety", "_confirm_power", "_confirm_delivery", "_confirm_scout"]:
			kiosk.set("_choice", 0)
			kiosk.call(method)
			_check(not registry.has_discovery(FAIR), "Incorrect option completed fair")
			kiosk.set("_choice", 1)
			kiosk.call(method)
		_check(registry.has_discovery(FAIR), "Final presentation not registered")
		_check(not registry.has_discovery("insight"), "Optional InSight must not auto-register")
		_check(fair.get_node_or_null("OptionalInSightPortal") != null, "Optional portal missing after fair")
		_check(fair.get_node_or_null("ReturnToWorkshop") != null, "Cannot revisit workshop")
	var memory := insight_scene.instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	var lander := memory.get_node_or_null("InSightStationaryLander") as Node3D
	var console := memory.get_node_or_null("InSightSEISConsole") as StaticBody3D
	_check(lander != null and console != null, "Missing InSight model or console")
	if lander != null and console != null:
		_check(not bool(lander.call("check_environmental_noise")), "Cannot shield before placement")
		_check(not registry.has_discovery("insight"), "Optional article registered too early")
		console.set("_choice", 0)
		console.call("_confirm_placement")
		_check(not bool(console.get("_placed")), "Incorrect placement accepted")
		console.set("_choice", 1)
		console.call("_confirm_placement")
		_check(bool(console.get("_placed")), "SEIS placement not registered")
		console.set("_choice", 0)
		console.call("_confirm_noise")
		_check(not bool(console.get("_noise_checked")), "Noise filter bypass")
		console.set("_choice", 1)
		console.call("_confirm_noise")
		_check(bool(console.get("_noise_checked")), "Noise protection missing")
		console.set("_choice", 0)
		console.call("_confirm_history")
		_check(not registry.has_discovery("insight"), "Invented mission continuation")
		console.set("_choice", 1)
		console.call("_confirm_history")
		_check(registry.has_discovery("insight"), "Optional article missing")
		_check(bool(lander.call("instrument_is_protected")), "SEIS not protected")
		_check(memory.get_node_or_null("ReturnToScienceFair") != null, "No return to fair")
		_check(registry.has_discovery(FAIR), "Optional mission changed fair completion")
		var catalog: Dictionary = registry.call("get_catalog_entry", "insight")
		_check(bool(catalog.get("optional", false)), "InSight not marked optional")
		_check(int(catalog.get("year", 0)) == 2022, "InSight final year incorrect")
	for id in REQUIRED:
		_check(registry.has_discovery(id), "Lost improvement: " + id)
	if errors.is_empty():
		print("PASS: Required fair, completion, optional InSight, returns, and history")
		quit(0)
	else:
		for err in errors:
			printerr("FAIL: ", err)
		quit(1)
