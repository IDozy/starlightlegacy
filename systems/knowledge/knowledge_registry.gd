extends Node

signal discovery_added(discovery: Dictionary)

var _discoveries: Dictionary = {}
var _discovery_order: Array[String] = []


func register_discovery(
	discovery_id: String,
	title: String,
	category: String,
	summary: String
) -> bool:
	var normalized_id := discovery_id.strip_edges()
	if normalized_id.is_empty() or _discoveries.has(normalized_id):
		return false

	var discovery := {
		"id": normalized_id,
		"title": title.strip_edges(),
		"category": category.strip_edges(),
		"summary": summary.strip_edges()
	}

	_discoveries[normalized_id] = discovery
	_discovery_order.append(normalized_id)
	discovery_added.emit(discovery.duplicate(true))
	return true


func has_discovery(discovery_id: String) -> bool:
	return _discoveries.has(discovery_id.strip_edges())


func get_discoveries() -> Array:
	var result: Array = []

	for discovery_id in _discovery_order:
		if _discoveries.has(discovery_id):
			result.append(_discoveries[discovery_id].duplicate(true))

	return result


func get_discovery_count() -> int:
	return _discovery_order.size()
