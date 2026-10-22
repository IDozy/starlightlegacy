class_name DialogueController
extends Node

signal dialogue_active_changed(active: bool)
signal dialogue_finished(dialogue_id: String)

@export var player_path: NodePath
@export var dialogue_panel_path: NodePath
@export var speaker_label_path: NodePath
@export var text_label_path: NodePath
@export var hint_label_path: NodePath

@onready var player = get_node(player_path)
@onready var _dialogue_panel := get_node(dialogue_panel_path) as Control
@onready var speaker_label := get_node(speaker_label_path) as Label
@onready var text_label := get_node(text_label_path) as Label
@onready var hint_label := get_node(hint_label_path) as Label

var _dialogue_id := ""
var _speaker := ""
var _lines: PackedStringArray = PackedStringArray()
var _line_index := 0
var _active := false
var _started_frame := -1


func _ready() -> void:
	add_to_group("dialogue_controller")
	_dialogue_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if Engine.get_process_frames() == _started_frame:
		return

	var advance := false

	if event is InputEventKey and event.pressed and not event.echo:
		advance = event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE
	elif event is InputEventMouseButton and event.pressed:
		advance = event.button_index == MOUSE_BUTTON_LEFT

	if advance:
		advance_dialogue()
		get_viewport().set_input_as_handled()


func start_dialogue_by_id(
	dialogue_id: String,
	speaker: String,
	source_player: Node = null
) -> bool:
	var lines := _get_dialogue_lines(dialogue_id)
	if lines.is_empty():
		return false

	return _start_dialogue(dialogue_id, speaker, lines, source_player)


func _start_dialogue(
	dialogue_id: String,
	speaker: String,
	lines: PackedStringArray,
	source_player: Node = null
) -> bool:
	if _active:
		return false

	if source_player != null:
		player = source_player

	_dialogue_id = dialogue_id
	_speaker = speaker
	_lines = lines.duplicate()
	_line_index = 0
	_active = true
	_started_frame = Engine.get_process_frames()

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	_dialogue_panel.visible = true
	hint_label.text = "E / Enter / clic · Continuar"
	dialogue_active_changed.emit(true)
	_show_current_line()
	return true


func advance_dialogue() -> void:
	if not _active:
		return

	_line_index += 1

	if _line_index >= _lines.size():
		_finish_dialogue()
		return

	_show_current_line()


func is_dialogue_active() -> bool:
	return _active


func _get_dialogue_lines(dialogue_id: String) -> PackedStringArray:
	match dialogue_id:
		"grandfather_intro":
			return PackedStringArray([
				"Veo lo que pasó en la prueba. El vehículo llegó al suelo, pero el golpe soltó todo por dentro.",
				"En 1997 tuvimos un problema parecido con Mars Pathfinder. Frenar la caída no bastaba: también había que sobrevivir al contacto con Marte.",
				"Usamos paracaídas y retrocohetes para reducir la velocidad, y unos enormes airbags para absorber el impacto final.",
				"Ven. Quiero mostrarte dónde terminó aquella máquina y qué aprendimos de ella."
			])
		"grandfather_vanguard_1":
			return PackedStringArray([
				"¡La amortiguación funcionó! Pero las luces y los motores agotaron tu batería antes de completar el rescate.",
				"En 1958, antes de que la NASA comenzara sus operaciones, el programa Vanguard lanzó un satélite muy pequeño: Vanguard 1.",
				"Usaba células solares para proporcionar energía a un transmisor. En la oscuridad, la reserva eléctrica seguía siendo importante.",
				"Ven, veamos cómo un sistema de energía puede durar más tiempo si aprovechamos la luz y administramos el consumo."
			])
		"grandfather_surveyor_1":
			return PackedStringArray([
				"¡Ahora el vehículo tiene energía! Pero cuando la luz llega de lado, el panel carga peor, y la cámara no consigue ver el objeto.",
				"En 1966 una nave de la NASA aterrizó suavemente en la Luna por primera vez para Estados Unidos: Surveyor 1.",
				"Los equipos de Tierra enviaban órdenes para operar su cámara y orientar el panel solar. No hacía falta que la máquina adivinara todo por sí sola.",
				"En el Océano de las Tormentas transmitió miles de imágenes. Vamos a practicar cómo orientar la luz y la observación con órdenes precisas."
			])
		"grandfather_apollo_11":
			return PackedStringArray([
				"¡Ya tienes ruedas, energía y cámara orientable! Pero la base de transporte aún está unida al vehículo. Así no puede comenzar la misión de rescate.",
				"Eso me recuerda al módulo lunar Eagle de Apollo 11. Armstrong y Aldrin aterrizaron en la Luna el 20 de julio de 1969.",
				"El Eagle tenía dos partes: la etapa inferior sirvió para aterrizar y luego como plataforma. El 21 de julio la etapa superior despegó desde ella, y la inferior quedó en la Luna.",
				"Nuestro rover no necesita despegar como una nave, pero sí puede aprender a separarse de una base que ya terminó su trabajo. Ven, veámoslo."
			])
		"grandfather_apollo_15":
			return PackedStringArray([
				"¡La base ya se libera! Pero sobre la arena y las piedras las ruedas patinan. Parece que el problema ya no es la potencia del motor.",
				"En 1971, los astronautas David Scott y James Irwin exploraron la Luna con un vehículo eléctrico de cuatro ruedas: el Lunar Roving Vehicle de Apollo 15.",
				"Sus ruedas no tenían cámaras de aire: utilizaban malla metálica flexible y bandas para mejorar el contacto con el suelo. Además transportaba a los astronautas y sus instrumentos.",
				"Vamos al recuerdo de Hadley-Apennine. Aprenderemos a elegir ruedas y distribuir la carga; nuestro vehículo escolar usará una adaptación diferente."
			])
		"grandfather_sky_crane":
			return PackedStringArray([
				"Ahora tu rover está protegido y conoce su consumo de energía, pero la base de entrega se separa antes de que las ruedas toquen el suelo.",
				"Perseverance aterrizó en el cráter Jezero de Marte el 18 de febrero de 2021. Durante su descenso usó navegación relativa al terreno para escoger un lugar seguro.",
				"Una etapa con motores descendió y lo bajó por cables hasta que sus ruedas hicieron contacto. Solo entonces cortó las conexiones y la etapa salió volando para caer lejos del rover.",
				"Esto no fue como Apollo 11: la etapa no quedó de plataforma en el mismo sitio. Nuestra maqueta aprenderá el orden: escoger terreno, bajar, detectar apoyo y liberar."
			])
		"grandfather_opportunity":
			return PackedStringArray([
				"Tu rover funciona, pero el panel ya no recibe la luz suficiente. Una tormenta artificial ha oscurecido la zona de pruebas.",
				"Opportunity llegó a Marte en enero de 2004. Era gemelo de Spirit, fue diseñado para 90 soles y recorrió más de 45 kilómetros en casi quince años.",
				"En junio de 2018 una gran tormenta de polvo oscureció Perseverance Valley. La última comunicación llegó el 10 de junio. Tras numerosos intentos sin éxito, NASA declaró terminada su misión el 13 de febrero de 2019.",
				"No diremos que Opportunity volvió a despertar. Aprenderemos a calcular un presupuesto energético en tu propio rover escolar."
			])
		"grandfather_spirit":
			return PackedStringArray([
				"Tu rover ya registra datos, pero al cruzar polvo fino las ruedas giran sin avanzar. Si insistimos, puede hundirse aún más.",
				"Spirit aterrizó en Marte en 2004 con seis ruedas y paneles solares. En 2009 quedó atrapado en suelo muy blando en un lugar llamado Troy.",
				"La NASA estudió el hundimiento y la inclinación, probó maniobras en la Tierra, pero no consiguió liberarlo. En enero de 2010 decidió utilizarlo como una plataforma científica estacionaria.",
				"No vamos a fingir que Spirit escapó. Aprenderemos a detectar cuándo debemos parar, cuidar la energía y continuar investigando de otra manera."
			])
		"grandfather_viking_1":
			return PackedStringArray([
				"¡El vehículo ya puede avanzar! Pero ahora el sensor ha marcado una reacción y casi anunciamos que encontramos vida, sin comprobar el resultado.",
				"En 1976, Viking 1 aterrizó en Marte, en Chryse Planitia, con un laboratorio y un brazo capaz de recoger muestras de suelo.",
				"Sus experimentos detectaron actividad química desconcertante. Sin embargo, no aportaron pruebas definitivas de vida. Una señal interesante no basta por sí sola.",
				"Viking 1 quedó en Marte y aún puede verse desde órbita. Vamos a descubrir cómo observar, comparar y explicar resultados con cuidado."
			])
		_:
			return PackedStringArray()


func _show_current_line() -> void:
	speaker_label.text = _speaker
	text_label.text = _lines[_line_index]


func _finish_dialogue() -> void:
	var finished_id := _dialogue_id

	_active = false
	_dialogue_panel.visible = false
	_lines.clear()
	_line_index = 0
	_dialogue_id = ""

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", false)

	dialogue_active_changed.emit(false)
	dialogue_finished.emit(finished_id)

