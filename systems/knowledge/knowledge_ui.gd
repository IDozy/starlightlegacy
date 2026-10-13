extends CanvasLayer

const SECTION_HISTORY := 0
const SECTION_ENGINEERING := 1
const SECTION_PROJECT := 2

var _archive_overlay: ColorRect
var _archive_card: ColorRect
var _archive_title: Label
var _archive_subtitle: Label
var _timeline_scroll: ScrollContainer
var _timeline_row: HBoxContainer
var _detail_title: Label
var _detail_meta: Label
var _detail_body: Label
var _section_buttons: Array[Button] = []
var _archive_hint: Label

var _toast: ColorRect
var _toast_title: Label
var _toast_text: Label
var _toast_tween: Tween

var _archive_open := false
var _timeline_entries: Array = []
var _timeline_buttons: Array[Button] = []
var _selected_index := 0
var _section_index := SECTION_HISTORY
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_archive()
	_build_toast()

	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null:
		registry.connect("discovery_added", Callable(self, "_on_discovery_added"))
		if registry.has_signal("archive_updated"):
			registry.connect("archive_updated", Callable(self, "_on_archive_updated"))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	if not _archive_open:
		if event.keycode == KEY_K:
			open_archive()
			get_viewport().set_input_as_handled()
		return

		return

	if event.keycode == KEY_K or event.keycode == KEY_ESCAPE:
		_close_archive()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_A or event.keycode == KEY_LEFT:
		_select_entry(_selected_index - 1)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_D or event.keycode == KEY_RIGHT:
		_select_entry(_selected_index + 1)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_1:
		_set_section(SECTION_HISTORY)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_2:
		_set_section(SECTION_ENGINEERING)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_3:
		_set_section(SECTION_PROJECT)
		get_viewport().set_input_as_handled()


func _build_archive() -> void:
	_archive_overlay = ColorRect.new()
	_archive_overlay.name = "NASAArchive"
	add_child(_archive_overlay)
	_archive_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_archive_overlay.color = Color(0.012, 0.018, 0.028, 0.96)
	_archive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_archive_overlay.visible = false

	_archive_card = ColorRect.new()
	_archive_card.name = "ArchiveCard"
	_archive_overlay.add_child(_archive_card)
	_archive_card.anchor_left = 0.045
	_archive_card.anchor_top = 0.055
	_archive_card.anchor_right = 0.955
	_archive_card.anchor_bottom = 0.945
	_archive_card.color = Color(0.045, 0.058, 0.075, 0.985)

	_archive_title = Label.new()
	_archive_card.add_child(_archive_title)
	_archive_title.anchor_left = 0.035
	_archive_title.anchor_top = 0.025
	_archive_title.anchor_right = 0.965
	_archive_title.anchor_bottom = 0.09
	_archive_title.text = "ARCHIVO NASA · HISTORIAS RECUPERADAS"
	_archive_title.add_theme_font_size_override("font_size", 27)
	_archive_title.add_theme_color_override("font_color", Color(0.96, 0.72, 0.30))

	_archive_subtitle = Label.new()
	_archive_card.add_child(_archive_subtitle)
	_archive_subtitle.anchor_left = 0.035
	_archive_subtitle.anchor_top = 0.09
	_archive_subtitle.anchor_right = 0.965
	_archive_subtitle.anchor_bottom = 0.14
	_archive_subtitle.text = "La aventura puede saltar en el tiempo. Aquí, cada pieza vuelve a ocupar su lugar en la historia."
	_archive_subtitle.add_theme_font_size_override("font_size", 15)
	_archive_subtitle.add_theme_color_override("font_color", Color(0.70, 0.75, 0.81))

	_timeline_scroll = ScrollContainer.new()
	_timeline_scroll.name = "TimelineScroll"
	_archive_card.add_child(_timeline_scroll)
	_timeline_scroll.anchor_left = 0.035
	_timeline_scroll.anchor_top = 0.16
	_timeline_scroll.anchor_right = 0.965
	_timeline_scroll.anchor_bottom = 0.36
	_timeline_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_timeline_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_timeline_row = HBoxContainer.new()
	_timeline_row.name = "Timeline"
	_timeline_scroll.add_child(_timeline_row)
	_timeline_row.add_theme_constant_override("separation", 10)

	var detail_panel := ColorRect.new()
	detail_panel.name = "DetailPanel"
	_archive_card.add_child(detail_panel)
	detail_panel.anchor_left = 0.035
	detail_panel.anchor_top = 0.39
	detail_panel.anchor_right = 0.965
	detail_panel.anchor_bottom = 0.89
	detail_panel.color = Color(0.025, 0.034, 0.047, 0.96)

	_detail_title = Label.new()
	detail_panel.add_child(_detail_title)
	_detail_title.anchor_left = 0.035
	_detail_title.anchor_top = 0.045
	_detail_title.anchor_right = 0.965
	_detail_title.anchor_bottom = 0.13
	_detail_title.add_theme_font_size_override("font_size", 25)
	_detail_title.add_theme_color_override("font_color", Color(0.95, 0.91, 0.83))

	_detail_meta = Label.new()
	detail_panel.add_child(_detail_meta)
	_detail_meta.anchor_left = 0.035
	_detail_meta.anchor_top = 0.13
	_detail_meta.anchor_right = 0.965
	_detail_meta.anchor_bottom = 0.20
	_detail_meta.add_theme_font_size_override("font_size", 15)
	_detail_meta.add_theme_color_override("font_color", Color(0.92, 0.67, 0.28))

	var tabs := HBoxContainer.new()
	detail_panel.add_child(tabs)
	tabs.anchor_left = 0.035
	tabs.anchor_top = 0.225
	tabs.anchor_right = 0.965
	tabs.anchor_bottom = 0.32
	tabs.add_theme_constant_override("separation", 12)

	for tab_data in [
		["1 · HISTORIA", SECTION_HISTORY],
		["2 · INGENIERÍA", SECTION_ENGINEERING],
		["3 · TU PROYECTO", SECTION_PROJECT]
	]:
		var button := Button.new()
		button.text = str(tab_data[0])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(190.0, 42.0)
		button.pressed.connect(Callable(self, "_set_section").bind(int(tab_data[1])))
		tabs.add_child(button)
		_section_buttons.append(button)

	_detail_body = Label.new()
	detail_panel.add_child(_detail_body)
	_detail_body.anchor_left = 0.035
	_detail_body.anchor_top = 0.35
	_detail_body.anchor_right = 0.965
	_detail_body.anchor_bottom = 0.94
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail_body.add_theme_font_size_override("font_size", 18)
	_detail_body.add_theme_color_override("font_color", Color(0.89, 0.92, 0.95))

	_archive_hint = Label.new()
	_archive_card.add_child(_archive_hint)
	_archive_hint.anchor_left = 0.035
	_archive_hint.anchor_top = 0.91
	_archive_hint.anchor_right = 0.965
	_archive_hint.anchor_bottom = 0.975
	_archive_hint.text = "A / D · Línea temporal    1 · Historia    2 · Ingeniería    3 · Tu proyecto    K / Esc · Cerrar"
	_archive_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_archive_hint.add_theme_font_size_override("font_size", 14)
	_archive_hint.add_theme_color_override("font_color", Color(0.62, 0.68, 0.75))


func _build_toast() -> void:
	_toast = ColorRect.new()
	_toast.name = "DiscoveryToast"
	add_child(_toast)
	_toast.anchor_left = 0.66
	_toast.anchor_top = 0.06
	_toast.anchor_right = 0.97
	_toast.anchor_bottom = 0.20
	_toast.color = Color(0.05, 0.07, 0.09, 0.96)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0

	_toast_title = Label.new()
	_toast.add_child(_toast_title)
	_toast_title.anchor_left = 0.06
	_toast_title.anchor_top = 0.12
	_toast_title.anchor_right = 0.94
	_toast_title.anchor_bottom = 0.42
	_toast_title.text = "NUEVO DESCUBRIMIENTO"
	_toast_title.add_theme_font_size_override("font_size", 16)
	_toast_title.add_theme_color_override("font_color", Color(0.94, 0.76, 0.40))

	_toast_text = Label.new()
	_toast.add_child(_toast_text)
	_toast_text.anchor_left = 0.06
	_toast_text.anchor_top = 0.44
	_toast_text.anchor_right = 0.94
	_toast_text.anchor_bottom = 0.88
	_toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_text.add_theme_font_size_override("font_size", 17)
	_toast_text.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))


func open_archive(discovery_id: String = "", section_index: int = SECTION_HISTORY) -> bool:
	if _archive_open:
		if not discovery_id.is_empty():
			_select_discovery(discovery_id)
		_set_section(section_index)
		return true

	var player := _get_player()
	if player == null:
		return false

	if player.has_method("can_open_knowledge") and not bool(player.call("can_open_knowledge")):
		return false

	_previous_mouse_mode = Input.mouse_mode
	if player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_archive_open = true
	_archive_overlay.visible = true
	_section_index = clampi(section_index, SECTION_HISTORY, SECTION_PROJECT)
	_refresh_archive(discovery_id)
	return true


func _close_archive() -> void:
	if not _archive_open:
		return

	_archive_open = false
	_archive_overlay.visible = false

	var player := _get_player()
	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", false)

	Input.set_mouse_mode(_previous_mouse_mode)


func _refresh_archive(preferred_discovery_id: String = "") -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("get_timeline_entries"):
		_detail_title.text = "ARCHIVO NO DISPONIBLE"
		_detail_meta.text = ""
		_detail_body.text = "El registro de descubrimientos todavía no está disponible."
		return

	_timeline_entries = registry.call("get_timeline_entries")
	_rebuild_timeline_buttons()

	if _timeline_entries.is_empty():
		_detail_title.text = "SIN ARTÍCULOS"
		_detail_meta.text = ""
		_detail_body.text = ""
		return

	if not preferred_discovery_id.is_empty():
		for index in range(_timeline_entries.size()):
			if str(_timeline_entries[index].get("id", "")) == preferred_discovery_id:
				_selected_index = index
				break
	else:
		_selected_index = _find_latest_discovered_index()

	_selected_index = clampi(_selected_index, 0, _timeline_entries.size() - 1)
	_refresh_selection()


func _rebuild_timeline_buttons() -> void:
	for child in _timeline_row.get_children():
		child.queue_free()

	_timeline_buttons.clear()

	for index in range(_timeline_entries.size()):
		var entry: Dictionary = _timeline_entries[index]
		var discovered := bool(entry.get("discovered", false))
		var year := int(entry.get("year", 0))
		var title := str(entry.get("title", "???"))
		var archive_kind := str(entry.get("archive_kind", "nasa"))

		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(138.0, 100.0)

		if archive_kind == "project":
			button.text = "PROYECTO\n◆\n%s" % title
		else:
			button.text = "%d\n%s\n%s" % [
				year,
				"◆" if discovered else "◼",
				title if discovered else "???"
			]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(Callable(self, "_select_entry").bind(index))

		if discovered:
			button.add_theme_color_override("font_color", Color(0.96, 0.79, 0.42))
			button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.62))
		else:
			button.add_theme_color_override("font_color", Color(0.28, 0.32, 0.38))
			button.add_theme_color_override("font_hover_color", Color(0.48, 0.52, 0.58))

		_timeline_row.add_child(button)
		_timeline_buttons.append(button)


func _find_latest_discovered_index() -> int:
	var latest := 0

	for index in range(_timeline_entries.size()):
		if bool(_timeline_entries[index].get("discovered", false)):
			latest = index

	return latest


func _select_discovery(discovery_id: String) -> void:
	for index in range(_timeline_entries.size()):
		if str(_timeline_entries[index].get("id", "")) == discovery_id:
			_select_entry(index)
			return


func _select_entry(index: int) -> void:
	if _timeline_entries.is_empty():
		return

	_selected_index = wrapi(index, 0, _timeline_entries.size())
	_refresh_selection()


func _refresh_selection() -> void:
	if _timeline_entries.is_empty():
		return

	for index in range(_timeline_buttons.size()):
		var button := _timeline_buttons[index]
		button.button_pressed = index == _selected_index

	var selected_button := _timeline_buttons[_selected_index]
	_timeline_scroll.ensure_control_visible(selected_button)
	_refresh_detail()


func _set_section(section_index: int) -> void:
	_section_index = clampi(section_index, SECTION_HISTORY, SECTION_PROJECT)
	_refresh_detail()


func _refresh_detail() -> void:
	if _timeline_entries.is_empty():
		return

	var entry: Dictionary = _timeline_entries[_selected_index]
	var discovered := bool(entry.get("discovered", false))
	var year := int(entry.get("year", 0))

	for index in range(_section_buttons.size()):
		_section_buttons[index].button_pressed = index == _section_index
		_section_buttons[index].disabled = not discovered

	if not discovered:
		_detail_title.text = "???"
		_detail_meta.text = "%d · SILUETA NO IDENTIFICADA" % year
		_detail_body.text = "Este artículo todavía no forma parte de tus historias recuperadas.\n\nSigue construyendo el rover y explora los recuerdos del abuelo. Algunos artículos solo aparecen cuando decides SABER MÁS."
		return

	var title := str(entry.get("title", "Descubrimiento"))
	var category := str(entry.get("category", "Conocimiento"))
	var optional := bool(entry.get("optional", false))
	var archive_kind := str(entry.get("archive_kind", "nasa"))

	_detail_title.text = title
	if archive_kind == "project":
		_detail_meta.text = "PROYECTO DEL NIÑO · %s" % category
	else:
		_detail_meta.text = "%d · %s%s" % [
			year,
			category,
			" · DESCUBRIMIENTO OPCIONAL" if optional else ""
		]

	match _section_index:
		SECTION_HISTORY:
			_detail_body.text = "HISTORIA\n\n%s\n\nVoz del abuelo · narración prevista para la versión final." % str(entry.get("history", entry.get("summary", "")))
		SECTION_ENGINEERING:
			_detail_body.text = "INGENIERÍA\n\n%s" % str(entry.get("engineering", "Información técnica pendiente."))
		SECTION_PROJECT:
			var project_text := str(entry.get("project", "Todavía no se ha aplicado este conocimiento al proyecto."))
			var application_id := str(entry.get("application_discovery_id", ""))
			var status := "ESTADO · CONOCIMIENTO RECUPERADO"

			if not application_id.is_empty():
				var registry := get_node_or_null("/root/KnowledgeRegistry")
				if registry != null and registry.has_method("has_discovery"):
					if bool(registry.call("has_discovery", application_id)):
						status = "ESTADO · APLICADO AL VEHÍCULO ✓"
					else:
						status = "ESTADO · LISTO PARA APLICAR"

			_detail_body.text = "TU PROYECTO\n\n%s\n\n%s" % [project_text, status]


func _on_discovery_added(discovery: Dictionary) -> void:
	_toast_text.text = "%s\nK · Abrir Archivo NASA" % str(discovery.get("title", "Descubrimiento"))

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.32)

	if _archive_open:
		_refresh_archive(str(discovery.get("id", "")))


func _on_archive_updated() -> void:
	if _archive_open:
		_refresh_archive()


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player_controller")
