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

var current_section_id := ""
var current_path: Array[String] = []
var selected_part_id := ""
var marker_numbers_visible := true
var history_provider: Callable
var search_query := ""
var _search_edit: LineEdit
var _content: VBoxContainer
var _breadcrumb: HBoxContainer
var _title: Label
var _diagram: TechnicalDiagramCanvas
var _vehicle: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_shell()
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
	title_stack.add_theme_constant_override("separation", 2)
	heading.add_child(title_stack)
	_title = _label("Технический справочник", 23, TEXT)
	title_stack.add_child(_title)
	var subtitle := _label("Škoda Yeti 5L · система → узел → деталь", 12, MUTED)
	title_stack.add_child(subtitle)
	_breadcrumb = HBoxContainer.new()
	_breadcrumb.add_theme_constant_override("separation", 4)
	add_child(_breadcrumb)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Поиск системы, узла, детали или симптома"
	_search_edit.custom_minimum_size.y = 48
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_changed)
	_style_edit(_search_edit)
	add_child(_search_edit)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		return
	if selected_part_id != "" and (current_section_id == "" or current_path.is_empty()):
		_render_part_detail()
		return
	if current_section_id == "":
		_title.text = "Технический справочник"
		_add_breadcrumb("Системы", Callable(self, "_reset_catalog"))
		_render_sections()
		return
	var section := TechnicalCatalog.section(current_section_id, _vehicle)
	if section.is_empty():
		_reset_catalog()
		return
	_title.text = str(section.get("name", "Узел")) if current_path.is_empty() else str(_current_node().get("name", "Узел"))
	_add_breadcrumb("Каталог", Callable(self, "_reset_catalog"))
	_add_breadcrumb(str(section.get("name", "Система")), Callable(self, "_open_section_root"))
	for depth in range(current_path.size()):
		var node := _node_at_path(depth)
		var destination := depth
		_add_breadcrumb(str(node.get("name", "Узел")), func(): _truncate_path(destination))
	if current_path.is_empty():
		_render_section_nodes(section)
	else:
		_render_node(section, _current_node())

func _render_sections() -> void:
	_content.add_child(_muted_label("Выберите раздел автомобиля. Схемы без проверенного источника отмечены отдельно."))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for section_value in TechnicalCatalog.sections(_vehicle):
		var section: Dictionary = section_value
		var button := _card_button()
		button.custom_minimum_size.y = 82
		grid.add_child(button)
		var copy := VBoxContainer.new()
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_theme_constant_override("separation", 4)
		button.add_child(copy)
		var name_label := _label(str(section.get("name", "Система")), 14, TEXT)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(name_label)
		var summary_label := _label(_section_summary(section), 10, MUTED)
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
	if str(diagram_data.get("image", "")) == "":
		var summary := _muted_label(str(node.get("summary", section.get("summary", ""))))
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(summary)
	_add_diagram_view(diagram_data, _node_part_ids(node))
	if _diagram != null and str(node.get("variant_note", "")) != "":
		var variant := _muted_label(str(node.get("variant_note", "")))
		variant.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(variant)
	for child_value in TechnicalCatalog.nodes(node, _vehicle):
		var child: Dictionary = child_value
		_content.add_child(_node_card(str(child.get("name", "Подсистема")), "Открыть вложенный узел", _open_node.bind(str(child.get("id", "")))))
	if selected_part_id != "":
		_render_selected_part_card()
	_add_part_list(_node_part_ids(node))
	if current_path.size() > 1:
		_add_back_to_parent()

func _add_diagram_view(diagram_data: Dictionary, part_ids: Array) -> void:
	var image_path := str(diagram_data.get("image", ""))
	var source: Dictionary = diagram_data.get("source", {})
	var applicability: Dictionary = source.get("applicability", {})
	var texture: Texture2D
	var source_verified := str(diagram_data.get("status", "missing")) == "verified" and str(source.get("author", "")) != "" and str(source.get("license", "")) != "" and not applicability.is_empty()
	if source_verified and TechnicalCatalog.is_compatible(applicability, _vehicle) and image_path.begins_with("res://") and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	if texture != null:
		var canvas := DiagramCanvasScript.new() as TechnicalDiagramCanvas
		canvas.custom_minimum_size = Vector2(0, 320)
		canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		canvas.configure(texture, diagram_data.get("markers", []), selected_part_id, marker_numbers_visible)
		canvas.marker_selected.connect(_select_part)
		_content.add_child(canvas)
		_diagram = canvas
		var controls := HBoxContainer.new()
		controls.add_theme_constant_override("separation", 8)
		_content.add_child(controls)
		controls.add_child(_action_button("Сбросить масштаб", func(): canvas.reset_view()))
		controls.add_child(_action_button("Скрыть номера" if marker_numbers_visible else "Показать номера", _toggle_markers))
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
	hero.add_theme_stylebox_override("panel", _panel_style(Color("091f29"), 18, BORDER))
	_content.add_child(hero)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 8)
	hero.add_child(text)
	text.add_child(_label(str(part.get("name", selected_part_id)), 20, TEXT))
	text.add_child(_muted_label("%s · %s" % [str(section.get("name", part.get("group", "Система"))), str(node.get("name", part.get("group", "Узел")))]))
	var description := str(part.get("description", ""))
	if description == "":
		description = "Деталь внесена в каталог. Технические сведения для этой модификации пока не подтверждены источником."
	var body := _muted_label(description)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(body)
	var note := _muted_label("Оригинальный номер, процедура проверки и снятия появятся только после сверки с документацией для этой комплектации.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(note)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	_content.add_child(actions)
	_add_action(actions, "Диагностика", func(): diagnostic_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Проверка / ремонт", func(): repair_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Руководство", func(): manual_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "История детали", func(): history_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Записать замену", func(): replacement_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	if history_provider.is_valid():
		var history := _muted_label(str(history_provider.call(selected_part_id)))
		history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(history)
	_content.add_child(_action_button("Назад к схеме", func(): selected_part_id = ""; _render()))

func _render_selected_part_card() -> void:
	var part := PartCatalog.get_part(selected_part_id)
	if part.is_empty():
		return
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("091f29"), 16, CYAN))
	_content.add_child(card)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 7)
	card.add_child(copy)
	copy.add_child(_label(str(part.get("name", selected_part_id)), 18, TEXT))
	var description := str(part.get("description", ""))
	if description == "":
		description = "Деталь выделена на схеме. Точное исполнение зависит от комплектации автомобиля."
	var body := _muted_label(description)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(body)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	_content.add_child(actions)
	_add_action(actions, "Диагностика", func(): diagnostic_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Проверка / ремонт", func(): repair_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Руководство", func(): manual_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "История детали", func(): history_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_add_action(actions, "Записать замену", func(): replacement_requested.emit(selected_part_id, str(part.get("name", selected_part_id))))
	_content.add_child(_action_button("Снять выделение", func(): selected_part_id = ""; _render()))

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
	_render()

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

func _add_back_to_parent() -> void:
	_content.add_child(_action_button("Назад к узлам", func():
		current_path.pop_back()
		_render()
	))

func _select_part(part_id: String) -> void:
	if PartCatalog.get_part(part_id).is_empty():
		return
	selected_part_id = part_id
	_render()

func focus_part(part_id: String) -> void:
	var part := PartCatalog.get_part(part_id)
	if part.is_empty():
		return
	var location := TechnicalCatalog.find_part(part_id, _vehicle)
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
	button.text = text_value
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", CYAN if _breadcrumb.get_child_count() == 0 else MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(Color("071820d8"), 11, BORDER))
	button.pressed.connect(action)
	_breadcrumb.add_child(button)
	if _breadcrumb.get_child_count() > 1:
		var separator := _label("›", 13, MUTED)
		_breadcrumb.move_child(button, _breadcrumb.get_child_count() - 1)
		_breadcrumb.add_child(separator)
		_breadcrumb.move_child(separator, _breadcrumb.get_child_count() - 2)

func _add_action(container: GridContainer, title: String, action: Callable) -> void:
	container.add_child(_action_button(title, action))

func _action_button(text_value: String, action: Callable) -> Button:
	var button := _card_button()
	button.custom_minimum_size.y = 48
	button.text = text_value
	button.pressed.connect(action)
	return button

func _card_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color("091b25f5"), 15, BORDER))
	button.add_theme_stylebox_override("hover", _panel_style(Color("0b2933f5"), 15, Color("217581")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0b3039f5"), 15, CYAN))
	return button

func _node_card(title: String, subtitle: String, action: Callable) -> Button:
	var button := _card_button()
	button.custom_minimum_size.y = 62
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 3)
	button.add_child(copy)
	var title_label := _label(title + "   ›", 14, TEXT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label := _label(subtitle, 10, MUTED)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	button.pressed.connect(action)
	return button

func _part_card(number: int, title: String, part_id: String) -> Button:
	var button := _card_button()
	button.set_meta("part_id", part_id)
	button.custom_minimum_size.y = 50
	if part_id == selected_part_id:
		button.add_theme_stylebox_override("normal", _panel_style(Color("0b3039"), 15, CYAN))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	button.add_child(row)
	row.add_child(_label("№%d" % number, 13, CYAN))
	var title_label := _label(title, 13, TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title_label)
	button.pressed.connect(_select_part.bind(part_id))
	return button

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

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
	return "%d узлов · %d компонентов" % [TechnicalCatalog.nodes(section, _vehicle).size(), unique_parts.size()]

func _has_confirmed_awd() -> bool:
	return str(_vehicle.get("drivetrain", "")).to_upper() in ["AWD", "4WD", "4X4"]
