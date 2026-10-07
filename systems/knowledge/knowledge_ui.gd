extends CanvasLayer

var _journal_overlay: ColorRect
var _journal_card: ColorRect
var _journal_title: Label
var _journal_content: Label
var _journal_hint: Label
var _toast: ColorRect
var _toast_title: Label
var _toast_text: Label
var _toast_tween: Tween
var _journal_open := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_journal()
	_build_toast()

	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry != null:
		registry.connect("discovery_added", Callable(self, "_on_discovery_added"))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo or event.keycode != KEY_K:
		return

	if _journal_open:
		_close_journal()
	else:
		_open_journal()

	get_viewport().set_input_as_handled()


func _build_journal() -> void:
	_journal_overlay = ColorRect.new()
	_journal_overlay.name = "KnowledgeJournal"
	add_child(_journal_overlay)
	_journal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_journal_overlay.color = Color(0.015, 0.022, 0.032, 0.92)
	_journal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_journal_overlay.visible = false

	_journal_card = ColorRect.new()
	_journal_card.name = "Card"
	_journal_overlay.add_child(_journal_card)
	_journal_card.anchor_left = 0.12
	_journal_card.anchor_top = 0.10
	_journal_card.anchor_right = 0.88
	_journal_card.anchor_bottom = 0.90
	_journal_card.color = Color(0.055, 0.07, 0.09, 0.98)
	_journal_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_journal_title = Label.new()
	_journal_card.add_child(_journal_title)
	_journal_title.anchor_left = 0.05
	_journal_title.anchor_top = 0.05
	_journal_title.anchor_right = 0.95
	_journal_title.anchor_bottom = 0.16
	_journal_title.text = "CUADERNO DE CONOCIMIENTO"
	_journal_title.add_theme_font_size_override("font_size", 28)
	_journal_title.add_theme_color_override("font_color", Color(0.94, 0.76, 0.40))

	_journal_content = Label.new()
	_journal_card.add_child(_journal_content)
	_journal_content.anchor_left = 0.05
	_journal_content.anchor_top = 0.20
	_journal_content.anchor_right = 0.95
	_journal_content.anchor_bottom = 0.84
	_journal_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_content.add_theme_font_size_override("font_size", 19)
	_journal_content.add_theme_color_override("font_color", Color(0.90, 0.92, 0.94))

	_journal_hint = Label.new()
	_journal_card.add_child(_journal_hint)
	_journal_hint.anchor_left = 0.05
	_journal_hint.anchor_top = 0.87
	_journal_hint.anchor_right = 0.95
	_journal_hint.anchor_bottom = 0.96
	_journal_hint.text = "K · Cerrar cuaderno"
	_journal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_journal_hint.add_theme_font_size_override("font_size", 16)
	_journal_hint.add_theme_color_override("font_color", Color(0.65, 0.70, 0.76))


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


func _open_journal() -> void:
	var player := _get_player()
	if player == null:
		return

	if player.has_method("can_open_knowledge"):
		if not bool(player.call("can_open_knowledge")):
			return

	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", true)

	_refresh_journal()
	_journal_open = true
	_journal_overlay.visible = true


func _close_journal() -> void:
	_journal_open = false
	_journal_overlay.visible = false

	var player := _get_player()
	if player != null and player.has_method("set_control_locked"):
		player.call("set_control_locked", false)


func _refresh_journal() -> void:
	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("get_discoveries"):
		_journal_content.text = "El cuaderno todavía no está disponible."
		return

	var discoveries: Array = registry.call("get_discoveries")
	var content := ""

	if discoveries.is_empty():
		content = "Aún no has registrado ningún descubrimiento.\n\nExplora el taller y examina objetos para aprender cómo funcionan."
	else:
		for index in range(discoveries.size()):
			var discovery = discoveries[index]

			if index > 0:
				content += "\n\n"

			content += "%d. %s  ·  %s\n%s" % [
				index + 1,
				str(discovery.get("title", "Descubrimiento")),
				str(discovery.get("category", "Conocimiento")),
				str(discovery.get("summary", ""))
			]

	_journal_title.text = "CUADERNO DE CONOCIMIENTO  ·  %d DESCUBRIMIENTO(S)" % discoveries.size()
	_journal_content.text = content


func _on_discovery_added(discovery: Dictionary) -> void:
	_toast_text.text = "%s\nK · Abrir cuaderno" % str(discovery.get("title", "Descubrimiento"))

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.32)


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player_controller")
