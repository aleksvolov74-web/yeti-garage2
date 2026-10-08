extends VBoxContainer

signal replacement_requested(part_id: String, part_name: String)
signal history_requested(part_id: String, part_name: String)
signal repair_requested(part_id: String, part_name: String)
signal diagnostic_requested(part_id: String, part_name: String)
signal manual_requested(part_id: String, part_name: String)
signal diagnostic_flow_requested(flow_id: String, title: String)

const TechnicalCatalog = preload("res://services/technical_catalog_service.gd")
const PartCatalog = preload("res://services/part_catalog_service.gd")
const DiagramCanvasScript = preload("res://scenes/technical_catalog/technical_diagram_canvas.gd")

const TEXT := Color("edf8fa")
const MUTED := Color("8da4b1")
const CYAN := Color("20e7eb")
const BORDER := Color("184955")
const MIN_SECTION_CARD_WIDTH := 264.0
const SECTION_GRID_SEPARATION := 8.0

var current_section_id := ""
var current_path: Array[String] = []
var selected_part_id := ""
var marker_numbers_visible := true
var history_provider: Callable
var search_query := ""
var _search_edit: LineEdit
var _content: VBoxContainer
var _breadcrumb: HFlowContainer
var _title: Label
var _diagram: TechnicalDiagramCanvas
var _vehicle: Dictionary = {}
var _section_columns := 0
var _root_resize_queued := false
var _catalog_touch_index := -1
var _catalog_touch_start := Vector2.ZERO
var _catalog_scroll_start := 0.0
var _catalog_touch_scroll: ScrollContainer
var _catalog_touch_canvas: TechnicalDiagramCanvas
var _catalog_touch_button: BaseButton
var _catalog_touch_claimed := false
var _catalog_touch_count := 0
var _pending_diagram_state: Dictionary = {}
var _pending_scroll_position := -1
const CATALOG_SCROLL_THRESHOLD := 9.0

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_shell()
	_content.resized.connect(_on_content_resized)
	_render()

func set_history_provider(provider: Callable) -> void:
	history_provider = provider

func set_vehicle_profile(vehicle: Dictionary) -> void:
	_vehicle = vehicle.duplicate(true)
	if _content != null:
		_render()

func _build_shell() -> void:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	add_child(heading)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_theme_constant_override("separation", 2)
	heading.add_child(title_stack)
	_title = _label("Технический справочник", 23, TEXT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_stack.add_child(_title)
	var subtitle := _label("Škoda Yeti 5L · система → узел → деталь", 12, MUTED)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_stack.add_child(subtitle)
	_breadcrumb = HFlowContainer.new()
	_breadcrumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breadcrumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_breadcrumb.add_theme_constant_override("separation", 4)
	_breadcrumb.resized.connect(_update_breadcrumb_widths)
	add_child(_breadcrumb)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Поиск системы, узла, детали или симптома"
	_search_edit.custom_minimum_size.y = 48
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.mouse_filter = Control.MOUSE_FILTER_PASS
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_changed)
	_style_edit(_search_edit)
	add_child(_search_edit)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)

func _render() -> void:
	for child in _breadcrumb.get_children():
		child.queue_free()
	for child in _content.get_children():
		child.queue_free()
	_diagram = null
	if search_query.strip_edges() != "":
		_title.text = "Результаты поиска"
		_add_breadcrumb("Каталог", Callable(self, "_reset_catalog"))
		_render_search_results()
		_queue_minimum_refresh()
		return
	if selected_part_id != "" and (current_section_id == "" or current_path.is_empty()):
		_render_part_detail()
		_queue_minimum_refresh()
		return
	if current_section_id == "":
		_title.text = "Технический справочник"
		_add_breadcrumb("Системы", Callable(self, "_reset_catalog"))
		_render_sections()
		_queue_minimum_refresh()
		return
	var section := TechnicalCatalog.section(current_section_id, _vehicle)
	if section.is_empty():
		_reset_catalog()
		return
	_title.text = str(section.get("name", "Система"))
	_add_breadcrumb("‹ Каталог", Callable(self, "_reset_catalog"))
	_add_breadcrumb(str(section.get("name", "Система")), Callable(self, "_open_section_root"))
	if current_path.is_empty():
		var default_node := _default_diagram_node(section)
		if not default_node.is_empty():
			_open_node(str(default_node.get("id", "")))
			return
	_render_node(section, _current_node())
	_queue_minimum_refresh()

func _render_sections() -> void:
	var intro := _muted_label("Выберите раздел автомобиля. Схемы без проверенного источника отмечены отдельно.")
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2 if _content.size.x >= MIN_SECTION_CARD_WIDTH * 2.0 + SECTION_GRID_SEPARATION else 1
	_section_columns = grid.columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", int(SECTION_GRID_SEPARATION))
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for section_value in TechnicalCatalog.sections(_vehicle):
		var section: Dictionary = section_value
		var button := _card_button()
		button.custom_minimum_size.y = 64
		grid.add_child(button)
		var margin := _card_margin(button)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		var icon_path := "res://assets/ui/icons/cube.svg"
		var section_id := str(section.get("id", ""))
		if section_id.contains("engine") or section_id.contains("timing") or section_id.contains("fuel"):
			icon_path = "res://assets/ui/icons/engine.svg"
		elif section_id.contains("service") or section_id.contains("brake") or section_id.contains("abs"):
			icon_path = "res://assets/ui/icons/diagnostic.svg"
		row.add_child(_centered_icon(icon_path, 28, MUTED))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_theme_constant_override("separation", 4)
		row.add_child(copy)
		var name_label := _label(str(section.get("name", "Система")), 14, TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(name_label)
		var summary_label := _label(_section_summary(section), 10, MUTED)
		summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(summary_label)
		button.pressed.connect(_open_section.bind(str(section.get("id", ""))))
	if not _has_confirmed_awd():
		var note := _muted_label("Узлы 4×4 скрыты, пока привод автомобиля не подтверждён как AWD.")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(note)

func _render_section_nodes(section: Dictionary) -> void:
	var description := _muted_label(str(section.get("summary", "")))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(description)
	for node_value in TechnicalCatalog.nodes(section, _vehicle):
		var node: Dictionary = node_value
		var details := _node_part_ids(node).size()
		_content.add_child(_node_card(str(node.get("name", "Узел")), "%d позиций" % details, _open_node.bind(str(node.get("id", "")))))
	_add_unassigned_parts(section)

func _render_node(section: Dictionary, node: Dictionary) -> void:
	var diagram_data: Dictionary = node.get("diagram", {})
	_add_scheme_selector(section, node)
	var image_kind := str(diagram_data.get("image_type", ""))
	var kind_label := {"exploded_view":"Взрывная схема", "assembled_view":"Общий вид", "technical_illustration":"Техническая схема", "reference_card":"Справочная схема"}.get(image_kind, "Схема")
	_content.add_child(_muted_label(kind_label))
	if str(diagram_data.get("image", "")) == "":
		var summary := _muted_label(str(node.get("summary", section.get("summary", ""))))
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(summary)
	_add_diagram_view(diagram_data, _node_part_ids(node))
	if _diagram != null and str(node.get("variant_note", "")) != "":
		var variant := _muted_label(str(node.get("variant_note", "")))
		variant.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(variant)
	if selected_part_id != "":
		_render_selected_part_card()
	_add_part_list(_node_display_part_ids(node))
	_add_unmarked_parts(section)
	if current_path.size() > 1:
		_add_back_to_parent()

func _add_diagram_view(diagram_data: Dictionary, part_ids: Array) -> void:
	var image_path := str(diagram_data.get("image", ""))
	var source: Dictionary = diagram_data.get("source", {})
	var applicability: Dictionary = source.get("applicability", {})
	var texture: Texture2D
	var diagram_status := str(diagram_data.get("status", "missing"))
	var source_verified := diagram_status in ["verified", "available"] and str(source.get("author", "")) != "" and str(source.get("license", "")) != "" and not applicability.is_empty()
	if source_verified and TechnicalCatalog.is_compatible(applicability, _vehicle) and image_path.begins_with("res://") and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	if texture != null:
		var canvas := DiagramCanvasScript.new() as TechnicalDiagramCanvas
		canvas.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.48, 330.0, 520.0))
		canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		canvas.configure(texture, diagram_data.get("markers", []), selected_part_id, marker_numbers_visible)
		canvas.marker_selected.connect(_select_part)
		_content.add_child(canvas)
		if not _pending_diagram_state.is_empty():
			canvas.set_view_state(_pending_diagram_state)
			_pending_diagram_state.clear()
		_diagram = canvas
		var controls := HFlowContainer.new()
		controls.add_theme_constant_override("separation", 8)
		_content.add_child(controls)
		controls.add_child(_action_button("Показать целиком", func(): canvas.reset_view()))
		controls.add_child(_action_button("Скрыть номера" if marker_numbers_visible else "Показать номера", _toggle_markers))
		controls.add_child(_action_button("На весь экран", func(): _show_fullscreen_diagram()))
		_add_visual_audit_note()
		return
	var empty := PanelContainer.new()
	empty.add_theme_stylebox_override("panel", _panel_style(Color("091b25"), 16, BORDER))
	empty.custom_minimum_size.y = 142
	_content.add_child(empty)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 6)
	empty.add_child(copy)
	var confidence := str(diagram_data.get("verification_level", "REFERENCE_ONLY"))
	var label_text := "Конструкция узла подтверждена" if confidence == "VERIFIED_ARCHITECTURE" else "Технический материал для сверки"
	var label := _label(label_text, 16, TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(label)
	var source_note_text := "Для точной детали используйте указанный источник; PR-код влияет только на вариант исполнения." if not str(node_variant_note()).is_empty() else "Схема не встроена: доступен внешний технический источник и список деталей узла."
	var source_note := _muted_label(source_note_text)
	source_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(source_note)
	var source_url := str(source.get("url", ""))
	if source_url.begins_with("https://"):
		copy.add_child(_action_button("Открыть технический источник", func(): OS.shell_open(source_url)))
	for related_value in source.get("related_references", []):
		var related: Dictionary = related_value
		var related_url := str(related.get("url", ""))
		if related_url.begins_with("https://"):
			var related_title := str(related.get("title", "Дополнительный источник"))
			copy.add_child(_action_button(related_title, func(): OS.shell_open(related_url)))
	var variant_note := str(node_variant_note())
	if variant_note != "":
		var variant_label := _muted_label(variant_note)
		variant_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(variant_label)
	var toggle := _action_button("Скрыть номера" if marker_numbers_visible else "Показать номера", _toggle_markers)
	toggle.disabled = diagram_data.get("markers", []).is_empty()
	_content.add_child(toggle)

func node_variant_note() -> String:
	if current_path.is_empty():
		return ""
	return str(_current_node().get("variant_note", ""))

func _add_part_list(part_ids: Array) -> void:
	if part_ids.is_empty():
		return
	var heading := _label("Детали узла", 17, TEXT)
	_content.add_child(heading)
	var index := 1
	for part_id_value in part_ids:
		var part_id := str(part_id_value)
		var part := PartCatalog.get_part(part_id)
		if part.is_empty():
			continue
		_content.add_child(_part_card(index, str(part.get("name", part_id)), part_id))
		index += 1

func _render_part_detail() -> void:
	var part := PartCatalog.get_part(selected_part_id)
	if part.is_empty():
		selected_part_id = ""
		_render()
		return
	var section := TechnicalCatalog.section(current_section_id, _vehicle)
	var path: Array = []
	for depth in range(current_path.size()):
		path.append(_node_at_path(depth))
	var node: Dictionary = path.back() if not path.is_empty() else {"name":str(part.get("group", "Узел"))}
	_title.text = str(part.get("name", selected_part_id))
	_add_breadcrumb("Каталог", Callable(self, "_reset_catalog"))
	_add_breadcrumb(str(section.get("name", "Система")), func():
		selected_part_id = ""
		current_section_id = str(section.get("id", ""))
		current_path.clear()
		_render()
	)
	for row_value in path:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == str(node.get("id", "")):
			_add_breadcrumb(str(row.get("name", "Узел")), func(): selected_part_id = ""; _render())
			break
	var hero := PanelContainer.new()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_theme_stylebox_override("panel", _panel_style(Color("091f29"), 18, BORDER))
	_content.add_child(hero)
	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 14)
	hero_margin.add_theme_constant_override("margin_right", 14)
	hero_margin.add_theme_constant_override("margin_top", 12)
	hero_margin.add_theme_constant_override("margin_bottom", 12)
	hero_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_margin)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 8)
	hero_margin.add_child(text)
	text.add_child(_label(str(part.get("name", selected_part_id)), 20, TEXT))
	text.add_child(_muted_label("%s · %s" % [str(section.get("name", part.get("group", "Система"))), str(node.get("name", part.get("group", "Узел")))]))
	var description := str(part.get("description", ""))
	if description == "":
		description = "Деталь внесена в каталог. Технические сведения для этой модификации пока не подтверждены источником."
	var body := _muted_label(description)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(body)
	var note := _muted_label("Оригинальный номер, процедура проверки и снятия появятся только после сверки с документацией для этой комплектации.")
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(note)
	var primary := _action_button("Проверка / ремонт", func(): repair_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	primary.add_theme_color_override("font_color", CYAN)
	_content.add_child(primary)
	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	_content.add_child(actions)
	_add_action(actions, "Диагностика", func(): diagnostic_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Руководство", func(): manual_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "История", func(): history_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_content.add_child(_action_button("Записать замену", func(): replacement_requested.emit(selected_part_id, str(part.get("name", selected_part_id)))))
	if history_provider.is_valid():
		var history := _muted_label(str(history_provider.call(selected_part_id)))
		history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(history)
	_content.add_child(_action_button("Назад к схеме", func(): selected_part_id = ""; _render()))

func _render_selected_part_card() -> void:
	var part := PartCatalog.get_part(selected_part_id)
	if part.is_empty(): return
	var number := 0
	for marker in _current_node().get("diagram", {}).get("markers", []):
		if str(marker.get("part_id", "")) == selected_part_id: number = int(marker.get("number", 0))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("091f29"), 14, CYAN))
	_content.add_child(card)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 8)
	card.add_child(copy)
	copy.add_child(_label("№%d · %s" % [number, str(part.get("name", selected_part_id))], 18, TEXT))
	var description := str(part.get("description", "Деталь выбрана. Исполнение сверяется по комплектации."))
	copy.add_child(_muted_label(description))
	var audit := _visual_audit_entry()
	for marker in audit.get("markers", []):
		if str(marker.get("part_id", "")) == selected_part_id and str(marker.get("visual_status", "")) in ["FAIL_MARKER", "NEEDS_REVIEW"]:
			copy.add_child(_label("Расположение не подтверждено: " + str(marker.get("finding_ru", "")), 13, Color("ffd07b")))
	var primary := _action_button("Проверка / ремонт", func(): repair_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	primary.add_theme_color_override("font_color", CYAN)
	copy.add_child(primary)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	copy.add_child(actions)
	_add_action(actions, "Диагностика", func(): diagnostic_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Руководство", func(): manual_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "История", func(): history_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Снять выделение", func(): selected_part_id = ""; _render())
	var extra := _action_button("Записать замену", func(): replacement_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	extra.add_theme_color_override("font_color", MUTED)
	copy.add_child(extra)

func _visual_audit_entry() -> Dictionary:
	var file := FileAccess.open("res://data/technical_visual_audit.json", FileAccess.READ)
	if file == null: return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary: return {}
	return value.get("nodes", {}).get(str(_current_node().get("id", "")), {})

func _add_visual_audit_note() -> void:
	var audit := _visual_audit_entry()
	if audit.is_empty(): return
	var status := str(audit.get("architecture_status", "NEEDS_REVIEW"))
	var text_value := "Справочная визуализация · точное исполнение не подтверждено"
	if status == "FAIL_ARCHITECTURE": text_value = "Несоответствие конструкции · FAIL_ARCHITECTURE"
	elif status == "NEEDS_REVIEW": text_value = "Схема требует проверки · NEEDS_REVIEW"
	elif status == "NOT_APPLICABLE_FWD": text_value = "Не применяется к переднему приводу"
	_content.add_child(_label(text_value, 13, Color("ffd07b")))
	_content.add_child(_muted_label(str(audit.get("finding_ru", ""))))

func _render_search_results() -> void:
	var matches := TechnicalCatalog.search(search_query, _vehicle)
	if matches.is_empty():
		_content.add_child(_muted_label("Совпадений не найдено. По симптомам показываются только возможные связанные разделы, не диагноз."))
		return
	for result_value in matches:
		var result: Dictionary = result_value
		var button := _card_button()
		button.custom_minimum_size.y = 58
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s" % [str(result.get("name", "Материал")), str(result.get("subtitle", "Каталог"))]
		button.pressed.connect(_open_search_result.bind(result))
		_content.add_child(button)

func _open_search_result(result: Dictionary) -> void:
	search_query = ""
	_search_edit.text = ""
	if str(result.get("kind", "")) == "diagnostic":
		diagnostic_flow_requested.emit(str(result.get("flow_id", "")), str(result.get("name", "Диагностика")))
		return
	var part_id := str(result.get("part_id", ""))
	if part_id != "":
		focus_part(part_id)
		return
	current_section_id = str(result.get("section_id", result.get("id", "")))
	current_path.clear()
	var ids: Array = []
	for row_value in result.get("path", []):
		var row: Dictionary = row_value
		ids.append(str(row.get("id", "")))
	if str(result.get("kind", "")) == "node" and (ids.is_empty() or str(ids.back()) != str(result.get("id", ""))):
		ids.append(str(result.get("id", "")))
	for id_value in ids:
		if str(id_value) != "":
			current_path.append(str(id_value))
	_render()

func open_catalog_result(result: Dictionary) -> void:
	_open_search_result(result)

func _on_search_changed(value: String) -> void:
	search_query = value.strip_edges()
	_render()

func _open_section(section_id: String) -> void:
	current_section_id = section_id
	current_path.clear()
	selected_part_id = ""
	search_query = ""
	var section := TechnicalCatalog.section(section_id, _vehicle)
	var default_node := _default_diagram_node(section)
	if not default_node.is_empty():
		_open_node(str(default_node.get("id", "")))
		return
	_render()

func _all_diagram_nodes(parent: Dictionary) -> Array:
	var found: Array = []
	for child_value in TechnicalCatalog.nodes(parent, _vehicle):
		var child: Dictionary = child_value
		var diagram: Dictionary = child.get("diagram", {})
		if str(diagram.get("image", "")) != "":
			found.append(child)
		found.append_array(_all_diagram_nodes(child))
	return found

func _default_diagram_node(section: Dictionary) -> Dictionary:
	var diagrams := _all_diagram_nodes(section)
	for preferred in ["overview", "complete", "assembly"]:
		for row_value in diagrams:
			var row: Dictionary = row_value
			var key := str(row.get("id", "")).to_lower() + " " + str(row.get("name", "")).to_lower()
			if key.contains(preferred):
				return row
	return diagrams[0] if not diagrams.is_empty() else {}

func _add_scheme_selector(section: Dictionary, selected: Dictionary) -> void:
	var rows := _all_diagram_nodes(section)
	if rows.size() <= 1:
		return
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	_content.add_child(bar)
	bar.add_child(_label("Схемы", 14, TEXT))
	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.custom_minimum_size.y = 48
	selector.fit_to_longest_item = false
	selector.clip_text = true
	selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selector.set_meta("scheme_selector", true)
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		selector.add_item("%d / %d · %s" % [i + 1, rows.size(), str(row.get("name", "Узел"))], i)
		if str(row.get("id", "")) == str(selected.get("id", "")):
			selector.select(i)
	selector.item_selected.connect(func(index: int): _open_node(str(rows[index].get("id", ""))))
	bar.add_child(selector)
	selector.get_popup().about_to_popup.connect(func(): _bound_scheme_popup(selector, rows))

func _bound_scheme_popup(selector: OptionButton, rows: Array) -> void:
	var popup := selector.get_popup()
	var width_limit := maxf(180.0, get_viewport_rect().size.x - 24.0)
	var font := selector.get_theme_font("font")
	var font_size := selector.get_theme_font_size("font_size")
	for i in range(rows.size()):
		var full := "%d / %d · %s" % [i + 1, rows.size(), str(rows[i].get("name", "Узел"))]
		var shown := full
		while shown.length() > 5 and font.get_string_size(shown + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width_limit - 56.0:
			shown = shown.left(shown.length() - 1)
		popup.set_item_text(i, shown + "…" if shown != full else full)
		popup.set_item_tooltip(i, full)
	popup.max_size = Vector2i(int(width_limit), int(get_viewport_rect().size.y * 0.65))
	popup.size = Vector2i(int(width_limit), mini(popup.size.y, popup.max_size.y))

func _open_section_root() -> void:
	current_path.clear()
	selected_part_id = ""
	_render()

func _open_node(node_id: String) -> void:
	var section := TechnicalCatalog.section(current_section_id, _vehicle)
	var path := _find_node_path(TechnicalCatalog.nodes(section, _vehicle), node_id, [])
	if not path.is_empty():
		current_path.clear()
		for row_value in path:
			var row: Dictionary = row_value
			current_path.append(str(row.get("id", "")))
	selected_part_id = ""
	_render()

func focus_node(node_id: String) -> void:
	var section: Dictionary = {}
	for section_value in TechnicalCatalog.sections(_vehicle):
		var candidate: Dictionary = section_value
		if not _find_node_path(TechnicalCatalog.nodes(candidate, _vehicle), node_id, []).is_empty():
			section = candidate
			break
	if section.is_empty(): return
	current_section_id = str(section.get("id", ""))
	_open_node(node_id)

func _show_fullscreen_diagram() -> void:
	if _diagram == null: return
	var popup := PopupPanel.new()
	popup.transparent_bg = true
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x - 12.0, 700.0), get_viewport_rect().size.y - 30.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("061018"), 12, BORDER))
	popup.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)
	var canvas := _diagram
	var original_index := _content.get_children().find(canvas)
	_content.remove_child(canvas)
	canvas.custom_minimum_size.y = 0
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(canvas)
	var controls := HFlowContainer.new()
	controls.add_child(_action_button("Показать целиком", func(): canvas.reset_view()))
	controls.add_child(_action_button("Скрыть номера" if marker_numbers_visible else "Показать номера", func():
		marker_numbers_visible = not marker_numbers_visible
		canvas.set_markers_visible(marker_numbers_visible)
		if _diagram != null: _diagram.set_markers_visible(marker_numbers_visible)
	))
	controls.add_child(_action_button("Закрыть", func(): popup.hide()))
	layout.add_child(controls)
	popup.popup_hide.connect(func():
		var restore_index := original_index
		if is_instance_valid(_diagram) and _diagram != canvas and _diagram.get_parent() == _content:
			restore_index = _content.get_children().find(_diagram)
			_content.remove_child(_diagram)
			_diagram.queue_free()
		if canvas.get_parent() == layout:
			layout.remove_child(canvas)
		_content.add_child(canvas)
		_content.move_child(canvas, clampi(restore_index, 0, _content.get_child_count() - 1))
		canvas.set_selected_part(selected_part_id)
		canvas.set_markers_visible(marker_numbers_visible)
		canvas.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		canvas.custom_minimum_size.y = clampf(get_viewport_rect().size.y * 0.48, 330.0, 520.0)
		_diagram = canvas
		popup.queue_free()
	)
	add_child(popup)
	popup.popup_centered(Vector2i(int(panel.custom_minimum_size.x), int(panel.custom_minimum_size.y)))

func _find_node_path(nodes: Array, node_id: String, parent_path: Array) -> Array:
	for value in nodes:
		var node: Dictionary = value
		var path := parent_path.duplicate()
		path.append(node)
		if str(node.get("id", "")) == node_id:
			return path
		var result := _find_node_path(TechnicalCatalog.nodes(node, _vehicle), node_id, path)
		if not result.is_empty():
			return result
	return []

func _node_at_path(depth: int) -> Dictionary:
	var section := TechnicalCatalog.section(current_section_id, _vehicle)
	var rows: Array = TechnicalCatalog.nodes(section, _vehicle)
	var found: Dictionary = {}
	for index in range(current_path.size()):
		var wanted := current_path[index]
		found = {}
		for value in rows:
			var row: Dictionary = value
			if str(row.get("id", "")) == wanted:
				found = row
				break
		rows = TechnicalCatalog.nodes(found, _vehicle)
		if index == depth:
			return found
	return found

func _current_node() -> Dictionary:
	return _node_at_path(current_path.size() - 1)

func _node_part_ids(node: Dictionary) -> Array:
	var result: Array = []
	for part_id in node.get("part_ids", []):
		if PartCatalog.PARTS.has(str(part_id)) and str(part_id) not in result:
			result.append(str(part_id))
	for child_value in TechnicalCatalog.nodes(node, _vehicle):
		for nested_id in _node_part_ids(child_value):
			if nested_id not in result:
				result.append(nested_id)
	return result

func _node_display_part_ids(node: Dictionary) -> Array:
	var result: Array = []
	var diagram: Dictionary = node.get("diagram", {})
	for marker_value in diagram.get("markers", []):
		var marker: Dictionary = marker_value
		var part_id := str(marker.get("part_id", ""))
		if part_id != "" and PartCatalog.get_part(part_id).size() > 0 and part_id not in result:
			result.append(part_id)
	for part_id_value in node.get("part_ids", []):
		var part_id := str(part_id_value)
		if PartCatalog.get_part(part_id).size() > 0 and part_id not in result:
			result.append(part_id)
	return result

func _add_unassigned_parts(section: Dictionary) -> void:
	var assigned: Array = []
	for node_value in TechnicalCatalog.nodes(section, _vehicle):
		assigned.append_array(_node_part_ids(node_value))
	var fallback: Array = []
	for part_value in PartCatalog.parts_for_system(str(section.get("part_system", ""))):
		var part: Dictionary = part_value
		var id := str(part.get("id", ""))
		if id not in assigned:
			fallback.append(id)
	if fallback.is_empty():
		return
	_content.add_child(_muted_label("Другие компоненты раздела"))
	_add_part_list(fallback)

func _add_unmarked_parts(section: Dictionary) -> void:
	var assigned: Array = []
	var marked: Array = []
	_collect_part_ids(TechnicalCatalog.nodes(section, _vehicle), assigned, marked)
	var other: Array = []
	for value in assigned:
		var id := str(value)
		if id not in marked and id not in other:
			other.append(id)
	if other.is_empty(): return
	var heading := _muted_label("Другие компоненты · без отдельной схемы")
	heading.add_theme_font_size_override("font_size", 11)
	_content.add_child(heading)
	var index := 1
	for part_id in other:
		var part := PartCatalog.get_part(str(part_id))
		if not part.is_empty():
			_content.add_child(_part_card(index, str(part.get("name", part_id)), str(part_id)))
			index += 1

func _collect_part_ids(rows: Array, assigned: Array, marked: Array) -> void:
	for value in rows:
		var node: Dictionary = value
		for part_id in node.get("part_ids", []):
			if str(part_id) not in assigned: assigned.append(str(part_id))
		var diagram: Dictionary = node.get("diagram", {})
		for marker_value in diagram.get("markers", []):
			var marker: Dictionary = marker_value
			var part_id := str(marker.get("part_id", ""))
			if part_id != "" and part_id not in marked: marked.append(part_id)
		_collect_part_ids(TechnicalCatalog.nodes(node, _vehicle), assigned, marked)

func _add_back_to_parent() -> void:
	_content.add_child(_action_button("Назад к узлам", func():
		current_path.pop_back()
		_render()
	))

func _select_part(part_id: String) -> void:
	if PartCatalog.get_part(part_id).is_empty():
		return
	if _diagram != null:
		_diagram.set_selected_part(part_id)
		_pending_diagram_state = _diagram.get_view_state()
		var parent_node: Node = self
		while parent_node != null and not (parent_node is ScrollContainer):
			parent_node = parent_node.get_parent()
		if parent_node is ScrollContainer:
			_pending_scroll_position = (parent_node as ScrollContainer).scroll_vertical
	selected_part_id = part_id
	_render()
	if _pending_scroll_position >= 0:
		call_deferred("_restore_catalog_scroll")

func _restore_catalog_scroll() -> void:
	var parent_node: Node = self
	while parent_node != null and not (parent_node is ScrollContainer):
		parent_node = parent_node.get_parent()
	if parent_node is ScrollContainer:
		(parent_node as ScrollContainer).scroll_vertical = _pending_scroll_position
	_pending_scroll_position = -1

func focus_part(part_id: String) -> void:
	var part := PartCatalog.get_part(part_id)
	if part.is_empty():
		return
	var location := TechnicalCatalog.find_marker_location(part_id, _vehicle)
	if location.is_empty():
		location = TechnicalCatalog.find_part(part_id, _vehicle)
	var section: Dictionary = location.get("section", {})
	current_section_id = str(section.get("id", part.get("system", "")))
	current_path.clear()
	for row_value in location.get("path", []):
		var row: Dictionary = row_value
		current_path.append(str(row.get("id", "")))
	selected_part_id = part_id
	search_query = ""
	if _search_edit != null:
		_search_edit.text = ""
	_render()

func _reset_catalog() -> void:
	current_section_id = ""
	current_path.clear()
	selected_part_id = ""
	search_query = ""
	_search_edit.text = ""
	_render()

func _truncate_path(depth: int) -> void:
	while current_path.size() > depth + 1:
		current_path.pop_back()
	selected_part_id = ""
	_render()

func _toggle_markers() -> void:
	marker_numbers_visible = not marker_numbers_visible
	if _diagram != null:
		_diagram.set_markers_visible(marker_numbers_visible)
	else:
		_render()

func _add_breadcrumb(text_value: String, action: Callable) -> void:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var available_width := _breadcrumb.size.x if _breadcrumb.size.x > 0.0 else size.x
	var item_width := maxf(84.0, minf(available_width * 0.48, 220.0))
	button.custom_minimum_size.x = item_width
	var max_chars := maxi(12, int((item_width - 28.0) / 7.0))
	button.text = text_value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if text_value.length() <= max_chars else text_value.substr(0, max_chars - 1) + "…"
	button.set_meta("full_breadcrumb_text", text_value)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", CYAN if _breadcrumb.get_child_count() == 0 else MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(Color("071820d8"), 11, BORDER))
	button.pressed.connect(action)
	if _breadcrumb.get_child_count() > 0:
		var separator := _label("›", 13, MUTED)
		_breadcrumb.add_child(separator)
	_breadcrumb.add_child(button)
	call_deferred("_update_breadcrumb_widths")

func _add_action(container: GridContainer, title: String, action: Callable) -> void:
	container.add_child(_action_button(title, action))

func _action_button(text_value: String, action: Callable) -> Button:
	var button := _card_button()
	button.custom_minimum_size.y = 48
	button.text = text_value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(action)
	return button

func _card_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color("091b25f5"), 15, BORDER))
	button.add_theme_stylebox_override("hover", _panel_style(Color("0b2933f5"), 15, Color("217581")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0b3039f5"), 15, CYAN))
	return button

func _card_margin(button: Button) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	return margin

func _node_card(title: String, subtitle: String, action: Callable) -> Button:
	var button := _card_button()
	button.custom_minimum_size.y = 70
	var margin := _card_margin(button)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 3)
	margin.add_child(copy)
	var title_label := _label(title + "   ›", 14, TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label := _label(subtitle, 10, MUTED)
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	button.pressed.connect(action)
	return button

func _part_card(number: int, title: String, part_id: String) -> Button:
	var button := _card_button()
	button.set_meta("part_id", part_id)
	button.custom_minimum_size.y = 66
	if part_id == selected_part_id:
		button.add_theme_stylebox_override("normal", _panel_style(Color("0b3039"), 15, CYAN))
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	var margin := _card_margin(button)
	margin.add_child(row)
	var number_label := _label("№%d" % number, 13, CYAN)
	number_label.custom_minimum_size.x = 38
	number_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(number_label)
	var title_label := _label(title, 13, TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title_label)
	button.pressed.connect(_select_part.bind(part_id))
	return button

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _centered_icon(path: String, icon_size: float, tint: Color = Color("ffffff")) -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(icon_size, icon_size)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = tint
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)
	return center

func _muted_label(value: String) -> Label:
	return _label(value, 12, MUTED)

func _style_edit(edit: LineEdit) -> void:
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_color_override("font_placeholder_color", MUTED)
	edit.add_theme_stylebox_override("normal", _panel_style(Color("091b25"), 13, BORDER))
	edit.add_theme_stylebox_override("focus", _panel_style(Color("091b25"), 13, CYAN))

func _panel_style(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _section_summary(section: Dictionary) -> String:
	var unique_parts: Dictionary = {}
	for node_value in TechnicalCatalog.nodes(section, _vehicle):
		for part_id in _node_part_ids(node_value):
			unique_parts[str(part_id)] = true
	return "%d схем · %d деталей" % [_all_diagram_nodes(section).size(), unique_parts.size()]

func _on_content_resized() -> void:
	if current_section_id != "" or search_query != "" or selected_part_id != "":
		return
	var desired_columns := 2 if _content.size.x >= MIN_SECTION_CARD_WIDTH * 2.0 + SECTION_GRID_SEPARATION else 1
	if desired_columns == _section_columns or _root_resize_queued:
		return
	_root_resize_queued = true
	call_deferred("_rerender_root_after_resize")

func _update_breadcrumb_widths() -> void:
	if not is_instance_valid(_breadcrumb) or _breadcrumb.size.x <= 0.0:
		return
	var item_width := maxf(84.0, minf(_breadcrumb.size.x * 0.48, 220.0))
	for child in _breadcrumb.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size.x = item_width
			var full_text := str(button.get_meta("full_breadcrumb_text", button.text))
			var max_chars := maxi(12, int((item_width - 28.0) / 7.0))
			button.text = full_text if full_text.length() <= max_chars else full_text.substr(0, max_chars - 1) + "…"

func _rerender_root_after_resize() -> void:
	_root_resize_queued = false
	if current_section_id == "" and search_query == "" and selected_part_id == "":
		_render()

func _queue_minimum_refresh() -> void:
	call_deferred("_refresh_minimum_sizes")

func _refresh_minimum_sizes() -> void:
	if not is_instance_valid(self) or not is_instance_valid(_content):
		return
	_content.update_minimum_size()
	update_minimum_size()

func _has_confirmed_awd() -> bool:
	return str(_vehicle.get("drivetrain", "")).to_upper() in ["AWD", "4WD", "4X4"]
