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
		"history": "El programa Vanguard del Naval Research Laboratory lanzó Vanguard 1 el 17 de marzo de 1958, antes del inicio de operaciones de NASA. El satélite esférico utilizó pequeñas células solares; dejó de transmitir en 1964.",
		"engineering": "Sus células solares convertían la luz en electricidad para un transmisor. En la sombra no producen energía: es útil conservar reserva eléctrica. La simulación del recuerdo no representa telemetría real.",
		"project": "Aplicación · Panel solar pequeño y modo de ahorro energético para extender la autonomía del Vehículo Explorador de Rescate.",
		"application_discovery_id": "rescue_rover_solar_upgrade"
	},
	{
		"id": "surveyor_1",
		"year": 1966,
		"title": "Surveyor 1",
		"category": "Hardware lunar",
		"optional": false,
		"history": "Surveyor 1 fue lanzado el 30 de mayo de 1966 y alunizó suavemente en Oceanus Procellarum el 2 de junio. Fue el primer alunizaje suave estadounidense. Transmitió 11.240 imágenes de televisión y ayudó a preparar futuras exploraciones lunares.",
		"engineering": "Su estructura de tres patas sostenía equipos, una cámara de televisión y un panel solar. Desde estaciones terrestres se enviaban comandos para operar la cámara y ajustar el panel. Los ángulos del recuerdo son una analogía jugable, no telemetría histórica.",
		"project": "Aplicación · Soportes regulables del panel solar y la cámara para orientar la luz y observar el objetivo del Vehículo Explorador de Rescate.",
		"application_discovery_id": "rescue_rover_orientation_upgrade"
	},
	{
		"id": "apollo_11_descent_stage",
		"year": 1969,
		"title": "Etapa de descenso · Apollo 11",
		"category": "Hardware lunar",
		"optional": false,
		"history": "El módulo lunar Eagle alunizó en el Mar de la Tranquilidad el 20 de julio de 1969. El 21 de julio Armstrong y Aldrin despegaron a bordo de la etapa de ascenso, usando la etapa de descenso como plataforma. Esta quedó en la superficie lunar.",
		"engineering": "Dos etapas con funciones diferentes: la etapa de descenso incluía las patas y el motor para alunizar; la etapa de ascenso contenía la cabina y el motor que devolvió a la tripulación a órbita lunar. El ejercicio de separación es una adaptación educativa, no un procedimiento real de cabina.",
		"project": "Aplicación · Mecanismo liberable para dejar atrás la base auxiliar de transporte del Vehículo Explorador de Rescate y continuar con sus sistemas principales.",
		"application_discovery_id": "rescue_rover_modular_release_upgrade"
	},
	{
		"id": "apollo_15_lrv",
		"year": 1971,
		"title": "Lunar Roving Vehicle · Apollo 15",
		"category": "Movilidad lunar",
		"optional": false,
		"history": "Apollo 15 fue la primera misión en utilizar el Lunar Roving Vehicle sobre la Luna el 31 de julio de 1971, en la región Hadley-Apennine. David Scott y James Irwin lo condujeron durante tres recorridos; el vehículo quedó en la Luna.",
		"engineering": "El LRV era eléctrico, de cuatro ruedas y dos asientos, con equipo científico y una estructura plegable para viajar en el módulo lunar. Sus ruedas de malla metálica flexible incorporaban bandas para mejorar el agarre. La selección de ruta y reparto de carga en el juego son analogías educativas.",
		"project": "Aplicación · Ruedas con bandas de agarre y carga distribuida en el Vehículo Explorador de Rescate; inspiración de movilidad, no una copia literal de las ruedas del LRV.",
		"application_discovery_id": "rescue_rover_traction_upgrade"
	},
	{
		"id": "viking_1",
		"year": 1976,
		"title": "Viking 1",
		"category": "Hardware en Marte",
		"optional": false,
		"history": "Viking 1 aterrizó en Chryse Planitia, Marte, el 20 de julio de 1976. Su brazo recolector analizó muestras de suelo y sus instrumentos buscaron señales de vida. La misión terminó en noviembre de 1982. La plataforma no fue recuperada y se fotografió desde órbita.",
		"engineering": "Su aterrizador hexagonal, de tres patas, disponía de dos cámaras escaneadoras, brazo recolector, laboratorio químico/biológico, antenas y dos generadores de radioisótopos (RTG), no paneles solares. Los experimentos produjeron actividad química interesante pero NO pruebas definitivas de vida. El ejercicio es una simulación de método científico y no telemetría de Viking.",
		"project": "Aplicación · Bandejas de comparación y registro para verificar lecturas del sensor antes de declarar hallazgos en el Vehículo Explorador de Rescate.",
		"application_discovery_id": "rescue_rover_science_verification_upgrade"
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
		"year": 2009,
		"title": "Spirit · Troy",
		"category": "Rover en Marte",
		"optional": false,
		"history": "Spirit exploró Gusev desde enero de 2004. En 2009 quedó atascado en suelo blando en Troy y no logró liberarse. En enero de 2010 NASA lo convirtió en plataforma científica estacionaria. La última comunicación fue el 22 de marzo de 2010; la misión concluyó en 2011. Spirit permanece en Marte.",
		"engineering": "El rover tenía seis ruedas, paneles solares, mástil de cámaras y brazo con instrumentos. Durante el atasco, los equipos analizaron deslizamiento, hundimiento, inclinación y energía, y ensayaron maniobras. Las decisiones del minijuego son analogías educativas, no comandos históricos ni una recuperación exitosa.",
		"project": "Aplicación · Monitor escolar de patinaje, inclinación y detención preventiva para el Vehículo Explorador de Rescate. No representa un rescate real de Spirit.",
		"application_discovery_id": "rescue_rover_slip_guard_upgrade"
	},
	{
		"id": "opportunity",
		"year": 2018,
		"title": "Opportunity · Perseverance Valley",
		"category": "Rover en Marte",
		"optional": false,
		"history": "Opportunity aterrizó en Marte el 24 de enero de 2004 (hora de California). Diseñado para 90 soles, recorrió 45,16 km. Durante la tormenta de polvo en Perseverance Valley llegó su última señal el 10 de junio de 2018. NASA declaró terminada la misión el 13 de febrero de 2019. Nunca recuperó el contacto; el rover permanece en Marte.",
		"engineering": "Rover solar gemelo de Spirit, con seis ruedas, cámaras y brazo de instrumentos. El polvo atmosférico redujo la luz que recibían los paneles. Las decisiones del minijuego son ejercicios educativos de presupuesto energético, no telemetría ni órdenes reales de la NASA.",
		"project": "Aplicación · Monitor de luz y reserva eléctrica más control de cargas no esenciales para el Vehículo Explorador de Rescate. No representa recuperación de Opportunity.",
		"application_discovery_id": "rescue_rover_power_budget_upgrade"
	},
	{
		"id": "perseverance_sky_crane",
		"year": 2021,
		"title": "Sky Crane · Perseverance",
		"category": "Sistema de descenso en Marte",
		"optional": false,
		"history": "El 18 de febrero de 2021 NASA logró aterrizar Perseverance en el cráter Jezero. Tras la entrada atmosférica, paracaídas, escudo y navegación relativa al terreno, su etapa de descenso con motores redujo la velocidad. La maniobra Sky Crane bajó el rover suspendido en cables; al detectar el contacto de las ruedas con Marte se cortaron los cables y la etapa se alejó antes de caer a distancia. La etapa de descenso no quedó junto al rover.",
		"engineering": "La navegación relativa al terreno permitía elegir un punto seguro. La plataforma propulsada estabilizaba el descenso; bajaba el rover por cables y este desplegaba sus ruedas. El contacto con el suelo precedía al corte de cables y al alejamiento de la etapa. Fue una maniobra autónoma, no controlada en tiempo real desde la Tierra. La interacción educativa omite física y telemetría reales.",
		"project": "Aplicación · Protocolo de confirmación de apoyo antes de liberar un soporte de entrega del vehículo escolar. No lleva cohetes y no equivale al sistema real de NASA.",
		"application_discovery_id": "rescue_rover_touchdown_release_upgrade"
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
		"title": "Ingenuity · Helicóptero de Marte",
		"category": "Aeronave de exploración",
		"optional": false,
		"history": "Ingenuity llegó a Marte con Perseverance en febrero de 2021. El 19 de abril de 2021 logró el primer vuelo motorizado y controlado en otro planeta. Proyectado para hasta cinco vuelos de prueba, completó 72. Durante el último vuelo, el 18 de enero de 2024, resultó dañado al menos uno de sus rotores y dejó de poder volar. NASA anunció el final de la misión el 25 de enero de 2024. Permanece en Marte.",
		"engineering": "Marte tiene una atmósfera muy tenue, aproximadamente un 1% de la presión superficial de la Tierra; se necesita una aeronave de baja masa y rotores capaces de mover suficiente aire. Ingenuity utilizaba dos rotores coaxiales contrarrotativos de 1,2 m de diámetro, con panel solar y navegación autónoma. Su función inicial fue demostrar el vuelo, y más adelante ayudó a explorar el terreno. La maqueta no simula fuerzas ni telemetría de vuelo reales.",
		"project": "Aplicación · Explorador aéreo escolar independiente del rover terrestre, para reconocer obstáculos. Muestra de sustentación, masa y control; no supone que el rover vuele ni que Ingenuity real pueda volver a despegar.",
		"application_discovery_id": "rescue_rover_aerial_scout_upgrade"
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
