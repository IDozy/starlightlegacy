extends SceneTree
## Run only during later Godot verification:
## godot --headless --editor --path . --quit
## godot --headless --path . --script res://tests/chapter1_persistence_smoke.gd

const REGISTRY_SCRIPT := preload("res://systems/knowledge/knowledge_registry.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _run() -> void:
	# Isolated user:// test file: never mutate the player's default save.
	var path := "user://starlight_chapter1_test_%d.json" % Time.get_ticks_usec()
	var a := REGISTRY_SCRIPT.new() as Node
	root.add_child(a)
	await process_frame
	a.call("configure_persistence", path, true)
	_check(not bool(a.call("load_progress")), "New test slot should be empty")
	a.call("register_discovery", "rescue_rover_airbag_upgrade",
		"Protección", "Proyecto del niño", "Protección de impacto.")
	a.call("register_discovery", "ingenuity",
		"Ingenuity", "Aeronave en Marte", "Recuerdo completado.")
	a.call("register_discovery", "rescue_rover_aerial_scout_upgrade",
		"Explorador", "Proyecto del niño", "Vuelo auxiliar.")
	a.call("register_discovery", "rescue_rover_science_fair_completed",
		"Capítulo I completado", "Proyecto escolar", "Feria completada.")
	_check(bool(a.call("save_now")), "Saving should succeed")
	_check(FileAccess.file_exists(path), "Snapshot missing")

	var b := REGISTRY_SCRIPT.new() as Node
	root.add_child(b)
	await process_frame
	b.call("configure_persistence", path, true)
	_check(bool(b.call("load_progress")), "Fresh registry failed to load")
	for id in ["rescue_rover_airbag_upgrade", "ingenuity",
		"rescue_rover_aerial_scout_upgrade", "rescue_rover_science_fair_completed"]:
		_check(bool(b.call("has_discovery", id)), "Lost progress: " + id)
	_check(not bool(b.call("has_discovery", "insight")), "Optional InSight unlocked by reload")
	_check(int(b.call("get_catalog_entry", "ingenuity").get("year", 0)) == 2024,
		"NASA catalog metadata lost")
	var count: int = b.call("get_discovery_count")
	_check(count == 4, "Wrong discovery count after reload")
	_check(not bool(b.call("register_discovery", "ingenuity", "Dup", "NASA", "Dup")),
		"Duplicate discovery allowed")
	_check(int(b.call("get_discovery_count")) == count,
		"Duplicate changed history")
	_check(b.call("get_timeline_entries").size() > count, "NASA silhouettes disappeared")

	# Simulate a truncated/corrupt current file; loader must use valid .bak.
	_check(bool(b.call("save_now")), "Backup trigger failed")
	var bad := FileAccess.open(path, FileAccess.WRITE)
	_check(bad != null, "Unable to simulate truncated save")
	if bad != null:
		bad.store_string("{\"version\":1,\"discoveries\":[")
		bad.close()
	var c := REGISTRY_SCRIPT.new() as Node
	root.add_child(c)
	await process_frame
	c.call("configure_persistence", path, true)
	_check(bool(c.call("load_progress")), "Backup was not recovered")
	_check(bool(c.call("has_discovery", "rescue_rover_science_fair_completed")),
		"Victory lost on backup recovery")

	for extension in ["", ".bak", ".tmp"]:
		var entry_path := ProjectSettings.globalize_path(path + extension)
		if FileAccess.file_exists(path + extension):
			DirAccess.remove_absolute(entry_path)
	a.queue_free()
	b.queue_free()
	c.queue_free()
	if failures.is_empty():
		print("PASS: chapter I progress round-trip, NASA catalog, backup and optional discovery")
		quit(0)
	else:
		for reason in failures:
			printerr("FAIL: ", reason)
		quit(1)
