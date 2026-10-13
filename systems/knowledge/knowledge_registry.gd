extends Node

signal discovery_added(discovery: Dictionary)
signal archive_updated

# The game route can jump through time. The archive itself always stays chronological.
# Unknown entries are rendered as silhouettes until their discovery is registered.
const TIMELINE_CATALOG: Array[Dictionary] = [
	{
		"id": "vanguard_1",
		"year": 1958,
		"title": "Vanguard 1",
		"category": "Prólogo de la era espacial",
		"optional": false,
		"history": "Uno de los primeros satélites artificiales de Estados Unidos. En el juego funciona como prólogo histórico anterior a la creación de NASA.",
		"engineering": "Su historia permite introducir energía eléctrica y el uso temprano de celdas solares para extender la vida de un satélite.",
		"project": "Pendiente · Futuro reto de energía del Vehículo Explorador."
	},
	{
		"id": "surveyor_1",
		"year": 1966,
		"title": "Surveyor 1",
		"category": "Hardware lunar",
		"optional": false,
		"history": "Primer alunizaje suave exitoso de Estados Unidos. Su artículo se habilitará cuando el jugador llegue al reto correspondiente.",
		"engineering": "Pendiente de cerrar con fuentes NASA antes de implementar el nivel.",
		"project": "Pendiente · Futuro reto de orientación y energía."
	},
	{
		"id": "apollo_11_descent_stage",
		"year": 1969,
		"title": "Etapa de descenso · Apollo 11",
		"category": "Hardware lunar",
		"optional": false,
		"history": "La etapa de descenso del módulo lunar quedó en la superficie después de servir como plataforma de alunizaje.",
		"engineering": "Pendiente de cerrar con fuentes NASA antes de implementar el nivel.",
		"project": "Pendiente · Futuro reto de masa y separación."
	},
	{
		"id": "apollo_15_lrv",
		"year": 1971,
		"title": "Lunar Roving Vehicle · Apollo 15",
		"category": "Movilidad lunar",
		"optional": false,
		"history": "Vehículo lunar utilizado por la tripulación de Apollo 15 y dejado en la superficie al terminar la misión.",
		"engineering": "Pendiente de cerrar con fuentes NASA antes de implementar el nivel.",
		"project": "Pendiente · Futuro reto de tracción."
	},
	{
		"id": "viking_1",
		"year": 1976,
		"title": "Viking 1",
		"category": "Hardware en Marte",
		"optional": false,
		"history": "Viking 1 llevó a Marte una plataforma científica que permaneció en la superficie después de finalizar sus operaciones.",
		"engineering": "Pendiente de cerrar con fuentes NASA antes de implementar el nivel.",
		"project": "Pendiente · Futuro reto de descenso."
	},
	{
		"id": "pathfinder_backshell",
		"year": 1997,
		"title": "Backshell + paracaídas · Pathfinder",
		"category": "Saber más · Hardware en Marte",
		"optional": true,
		"history": "Durante el descenso de Mars Pathfinder, el lander con sus airbags se separó del backshell. El backshell y el paracaídas quedaron sobre Marte, separados de la estación principal.",
		"engineering": "El backshell alojaba tres motores cohete sólidos. Estos frenaron el descenso antes de que el lander, ya envuelto en airbags, fuera liberado para caer y rebotar sobre la superficie.",
		"project": "Conocimiento complementario · Muestra que un sistema de aterrizaje puede dividir el problema entre varias etapas."
	},
	{
		"id": "mars_pathfinder_lander",
		"year": 1997,
		"title": "Mars Pathfinder",
		"category": "Hardware en Marte",
		"optional": false,
		"history": "Mars Pathfinder aterrizó en Ares Vallis el 4 de julio de 1997. Después del aterrizaje abrió sus pétalos y operó como estación base para Sojourner.",
		"engineering": "El sistema combinó protección atmosférica, paracaídas, retrocohetes y airbags. Los airbags absorbieron el impacto final y permitieron que el lander sobreviviera a los rebotes.",
		"project": "Aplicación · Estructura elástica de amortiguación para proteger el Vehículo Explorador en una caída.",
		"application_discovery_id": "rescue_rover_airbag_upgrade"
	},
	{
		"id": "sojourner_apxs",
		"year": 1997,
		"title": "Sojourner",
		"category": "Rover en Marte",
		"optional": false,
		"history": "Sojourner fue el primer vehículo con ruedas utilizado en otro planeta y exploró el entorno inmediato de Mars Pathfinder.",
		"engineering": "Seis ruedas y una suspensión preparada para terreno irregular permitieron experimentar con movilidad robótica. Su APXS analizó la composición de rocas y suelo.",
		"project": "Conocimiento recuperado · La movilidad y el análisis científico quedarán disponibles para futuros retos del rover."
	},
	{
		"id": "spirit",
		"year": 2010,
		"title": "Spirit",
		"category": "Rover en Marte",
		"optional": false,
		"history": "Artículo aún no recuperado.",
		"engineering": "Pendiente · Reto de ruedas, hundimiento, fricción y energía.",
		"project": "Pendiente."
	},
	{
		"id": "opportunity",
		"year": 2018,
		"title": "Opportunity",
		"category": "Rover en Marte",
		"optional": false,
		"history": "Artículo aún no recuperado.",
		"engineering": "Pendiente · Reto de energía y entorno.",
		"project": "Pendiente."
	},
	{
		"id": "perseverance_sky_crane",
		"year": 2021,
		"title": "Sky Crane · Perseverance",
		"category": "Sistema de descenso",
		"optional": false,
		"history": "Artículo aún no recuperado.",
		"engineering": "Pendiente · Separación segura, empuje e inercia.",
		"project": "Pendiente."
	},
	{
		"id": "insight",
		"year": 2022,
		"title": "InSight",
		"category": "Saber más · Hardware en Marte",
		"optional": true,
		"history": "Artículo opcional aún no recuperado.",
		"engineering": "Pendiente de diseñar como contenido complementario.",
		"project": "Conocimiento opcional."
	},
	{
		"id": "ingenuity",
		"year": 2024,
		"title": "Ingenuity",
		"category": "Aeronave en Marte",
		"optional": false,
		"history": "Artículo aún no recuperado.",
		"engineering": "Pendiente · Sustentación y vuelo en una atmósfera muy delgada.",
		"project": "Pendiente."
	}
]

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

	var catalog_entry := get_catalog_entry(normalized_id)
	if not catalog_entry.is_empty():
		for key in ["year", "optional", "history", "engineering", "project", "application_discovery_id"]:
			if catalog_entry.has(key):
				discovery[key] = catalog_entry[key]

	_discoveries[normalized_id] = discovery
	_discovery_order.append(normalized_id)
	discovery_added.emit(discovery.duplicate(true))
	archive_updated.emit()
	return true


func unlock_catalog_discovery(discovery_id: String) -> bool:
	var entry := get_catalog_entry(discovery_id)
	if entry.is_empty():
		return false

	return register_discovery(
		discovery_id,
		str(entry.get("title", "Descubrimiento")),
		str(entry.get("category", "Conocimiento")),
		str(entry.get("history", ""))
	)


func has_discovery(discovery_id: String) -> bool:
	return _discoveries.has(discovery_id.strip_edges())


func get_discovery(discovery_id: String) -> Dictionary:
	var normalized_id := discovery_id.strip_edges()
	if not _discoveries.has(normalized_id):
		return {}

	return _discoveries[normalized_id].duplicate(true)


func get_discoveries() -> Array:
	var result: Array = []

	for discovery_id in _discovery_order:
		if _discoveries.has(discovery_id):
			result.append(_discoveries[discovery_id].duplicate(true))

	return result


func get_discovery_count() -> int:
	return _discovery_order.size()


func get_timeline_entries() -> Array:
	var result: Array = []
	var catalog_ids: Dictionary = {}

	for source_entry in TIMELINE_CATALOG:
		var entry := source_entry.duplicate(true)
		var discovery_id := str(entry.get("id", ""))
		catalog_ids[discovery_id] = true
		entry["archive_kind"] = "nasa"
		entry["discovered"] = has_discovery(discovery_id)

		if entry["discovered"]:
			var registered := get_discovery(discovery_id)
			for key in registered.keys():
				entry[key] = registered[key]

		result.append(entry)

	# Project discoveries are not historical NASA artifacts, but they must remain
	# visible in the archive because the previous knowledge journal exposed them.
	# They are appended after the chronological NASA timeline as PROJECT cards.
	for discovery_id in _discovery_order:
		if catalog_ids.has(discovery_id):
			continue

		var registered := get_discovery(discovery_id)
		if registered.is_empty():
			continue

		var summary := str(registered.get("summary", ""))
		result.append({
			"id": discovery_id,
			"year": 0,
			"title": str(registered.get("title", "Registro del proyecto")),
			"category": str(registered.get("category", "Proyecto")),
			"optional": false,
			"archive_kind": "project",
			"discovered": true,
			"history": "Registro del proceso de construcción del Vehículo Explorador de Rescate.",
			"engineering": summary,
			"project": summary
		})

	return result


func get_catalog_entry(discovery_id: String) -> Dictionary:
	var normalized_id := discovery_id.strip_edges()

	for entry in TIMELINE_CATALOG:
		if str(entry.get("id", "")) == normalized_id:
			return entry.duplicate(true)

	return {}
