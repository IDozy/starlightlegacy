extends SceneTree
## Confirm K opens most RECENTLY discovered card, not the last visual entry.
## godot --headless --path . --script res://tests/archive_recency_smoke.gd

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(ok: bool, explanation: String) -> void:
	if not ok:
		failures.append(explanation)


func _selected_id(ui: Node) -> String:
	var entries: Array = ui.get("_timeline_entries")
	var index: int = ui.call("_find_latest_discovered_index")
	if index < 0 or index >= entries.size():
		return ""
	return str(entries[index].get("id", ""))


func _run() -> void:
	var registry := root.get_node_or_null("KnowledgeRegistry")
	var ui := root.get_node_or_null("KnowledgeUI")
	if registry == null or ui == null:
		printerr("FAIL: Knowledge registry or UI autoload missing")
		quit(1)
		return
	# Add project then historical NASA: NASA must win regardless of appended
	# visual project cards.
	registry.call("register_discovery", "rescue_rover_impact_problem",
		"Problema de impacto", "Proyecto del niño", "Prueba en taller")
	registry.call("register_discovery", "mars_pathfinder_lander",
		"Mars Pathfinder", "NASA", "1997")
	ui.call("_refresh_archive")
	_expect(_selected_id(ui) == "mars_pathfinder_lander",
		"Most recent NASA memory should be selected over older project card")

	# Add a new project entry: it is NOW most recent.
	registry.call("register_discovery", "rescue_rover_airbag_upgrade",
		"Amortiguación", "Proyecto del niño", "Mejora")
	ui.call("_refresh_archive")
	_expect(_selected_id(ui) == "rescue_rover_airbag_upgrade",
		"New project upgrade must be selected as newest")

	# After optional InSight, it must be the selected history card.
	registry.call("unlock_catalog_discovery", "insight")
	ui.call("_refresh_archive")
	_expect(_selected_id(ui) == "insight",
		"Optional InSight should be selected when registered last")
	var timeline: Array = registry.call("get_timeline_entries")
	var found_project := false
	for entry in timeline:
		if str(entry.get("id", "")) == "rescue_rover_airbag_upgrade":
			found_project = str(entry.get("archive_kind", "")) == "project"
	_expect(found_project, "Non-catalog project discovery disappeared from archive")
	if failures.is_empty():
		print("PASS: NASA/project/optional discovery recency and project cards")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
