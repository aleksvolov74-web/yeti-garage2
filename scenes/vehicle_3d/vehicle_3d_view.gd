extends VBoxContainer

signal replacement_requested(part_id: String, part_name: String)
signal history_requested(part_id: String, part_name: String)
signal repair_requested(part_id: String, part_name: String)
signal diagnostic_requested(part_id: String, part_name: String)
signal manual_requested(part_id: String, part_name: String)

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const TechnicalCatalog = preload("res://services/technical_catalog_service.gd")
var _vehicle: Dictionary = {}

const ViewerScene = preload("res://scenes/vehicle_3d/vehicle_part_viewer.tscn")

const TEXT := Color("edf8fa")
const MUTED := Color("8da4b1")
const CYAN := Color("20e7eb")
const BORDER := Color("184955")
const SYSTEM_SUMMARIES := {
	"engine":"Двигатель и его основные агрегаты",
	"cooling":"Радиатор, насос и контур охлаждения",
	"fuel_intake":"Подача топлива и воздуха",
	"exhaust":"Выпуск и очистка отработавших газов",
	"transmission":"Коробка передач и сцепление",
	"drive":"Валы, ШРУСы и ступицы",
	"suspension":"Передняя и задняя подвеска",
	"steering":"Рулевой механизм и колонка",
	"brakes":"Тормозные механизмы и гидравлика",
	"electrical":"Питание, запуск и управление двигателем",
	"body":"Панели и внешние элементы кузова",
	"interior":"Органы управления и элементы салона",
	"climate":"Отопление, вентиляция и кондиционер",
	"lighting":"Передняя и задняя светотехника",
	"safety":"Подушки, ремни и датчики удара",
	"wipers_glass":"Стеклоочистители и омыватели"
}
const SYSTEM_ICONS := {
	"engine":"engine.svg", "cooling":"oil.svg", "fuel_intake":"oil.svg", "exhaust":"cube.svg",
	"transmission":"cube.svg", "drive":"car.svg", "suspension":"car.svg", "steering":"car.svg",
	"brakes":"diagnostic.svg", "electrical":"diagnostic.svg", "body":"car.svg", "interior":"car.svg",
	"climate":"oil.svg", "lighting":"cube.svg", "safety":"diagnostic.svg", "wipers_glass":"cube.svg"
}
const PART_DESCRIPTIONS := {
	"engine_block":"Несущая основа двигателя с цилиндрами и каналами охлаждения и смазки.",
	"cylinder_head":"Головка блока закрывает цилиндры и содержит газораспределительный механизм.",
	"valve_cover":"Крышка закрывает верхнюю часть головки блока и элементы газораспределительного механизма.",
	"turbocharger":"Турбокомпрессор использует энергию отработавших газов для наддува воздуха во впуске.",
	"alternator":"Генератор вырабатывает электроэнергию при работающем двигателе и заряжает аккумулятор.",
	"accessory_belt_drive":"Ременной привод передаёт вращение от двигателя к навесным агрегатам. Показан схематично.",
	"timing_drive":"Цепной привод синхронизирует работу коленчатого и распределительного валов на двигателе EA111.",
	"flywheel":"Маховик сглаживает неравномерность вращения коленчатого вала и передаёт момент сцеплению.",
	"wheel":"Колесо передаёт усилие автомобиля на дорогу и закрывает тормозной узел.",
	"brake_disc":"Диск вращается вместе с колесом. При торможении колодки сжимают его с двух сторон.",
	"brake_caliper":"Суппорт прижимает тормозные колодки к диску. Проверяют направляющие, поршень и отсутствие утечек.",
	"brake_pads":"Фрикционные накладки прижимаются к тормозному диску; для замены в приложении есть отдельное пошаговое руководство.",
	"brake_hose":"Гибкий тормозной шланг подаёт давление к суппорту и должен оставаться герметичным при ходе подвески и повороте колеса.",
	"hub":"Ступица соединяет колесо с поворотным узлом и вращается вместе с колесом.",
	"wheel_bearing":"Ступичный подшипник позволяет ступице вращаться и воспринимает нагрузку от колеса.",
	"strut":"Амортизационная стойка гасит колебания подвески и помогает колесу сохранять контакт с дорогой.",
	"spring":"Пружина держит вес автомобиля и позволяет подвеске перемещаться вверх и вниз.",
	"control_arm":"Нижний рычаг задаёт положение колеса относительно кузова и соединяет поворотный узел с подрамником.",
	"ball_joint":"Шаровая опора соединяет рычаг с поворотным узлом, позволяя подвеске двигаться, а колесу — поворачиваться.",
	"stabilizer_link":"Стойка стабилизатора передаёт усилие между стабилизатором и подвеской; износ может проявляться стуком.",
	"tie_rod_end":"Рулевой наконечник передаёт движение рулевой тяги на поворотный кулак.",
	"steering_tie_rod":"Рулевая тяга передаёт движение от рулевого механизма к наконечнику.",
	"steering_rack":"Рулевой механизм преобразует вращение руля в продольное движение рулевых тяг.",
	"cv_joint_outer":"Наружный ШРУС передаёт крутящий момент на колесо при повороте и ходе подвески.",
	"cv_joint_inner":"Внутренний ШРУС компенсирует изменение длины привода при работе подвески.",
	"drive_shaft":"Приводной вал передаёт крутящий момент от коробки передач к ступичному узлу."
}

var page_header: HBoxContainer
var title_label: Label
var count_label: Label
var breadcrumb: HBoxContainer
var content: VBoxContainer
var selected_system := ""
var selected_assembly := ""
var selected_part := ""
var level := "systems"
var viewer: VehiclePartViewer
var history_provider: Callable
var page_scroll: ScrollContainer
var page_pointer_down := false
var page_drag_distance := 0.0
var touch_start := Vector2.ZERO

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_shell()
	_render()
	call_deferred("_prepare_page_touch_routing")

func _build_shell() -> void:
	page_header = HBoxContainer.new()
	page_header.add_theme_constant_override("separation", 10)
	add_child(page_header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 2)
	page_header.add_child(heading)
	title_label = Label.new()
	title_label.text = "Каталог систем"
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", TEXT)
	heading.add_child(title_label)
	var subtitle := Label.new()
	subtitle.text = "Система автомобиля → узел → деталь"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", MUTED)
	heading.add_child(subtitle)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(70, 48)
	badge.add_theme_stylebox_override("panel", _panel_style(Color("082b35e8"), 14, Color("16717b")))
	page_header.add_child(badge)
	count_label = Label.new()
	count_label.text = "%d систем\n%d деталей" % [PartCatalogService.SYSTEMS.size(), PartCatalogService.PARTS.size()]
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color("bceff1"))
	badge.add_child(count_label)
	breadcrumb = HBoxContainer.new()
	breadcrumb.add_theme_constant_override("separation", 6)
	add_child(breadcrumb)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	add_child(content)

func _render() -> void:
	for child in breadcrumb.get_children():
		child.queue_free()
	var keep_viewer := selected_assembly == "engine_front" and level in ["node", "part"]
	if viewer != null and is_instance_valid(viewer):
		if keep_viewer and viewer.get_parent() == content:
			content.remove_child(viewer)
		elif not keep_viewer:
			viewer.queue_free()
			viewer = null
	for child in content.get_children():
		if child != viewer:
			child.queue_free()
	if level == "systems":
		title_label.text = "Каталог систем"
		_add_breadcrumb_action("Системы", "systems")
		_render_systems()
	elif level == "assemblies":
		var system: Dictionary = PartCatalogService.SYSTEMS.get(selected_system, {})
		title_label.text = str(system.get("name", "Система"))
		_add_breadcrumb_action("Системы", "systems")
		_render_assemblies()
	elif level == "node":
		var sys: Dictionary = PartCatalogService.SYSTEMS.get(selected_system, {})
		var assembly := _get_assembly(selected_system, selected_assembly)
		title_label.text = str(assembly.get("name", "Узел"))
		_add_breadcrumb_action("Системы", "systems")
		_add_breadcrumb_action(str(sys.get("name", "Система")), "assemblies")
		_render_node(assembly)
	else:
		var parent_system: Dictionary = PartCatalogService.SYSTEMS.get(selected_system, {})
		var parent_assembly := _get_assembly(selected_system, selected_assembly)
		var part: Dictionary = PartCatalogService.get_part(selected_part)
		title_label.text = str(part.get("name", "Деталь"))
		_add_breadcrumb_action("Системы", "systems")
		_add_breadcrumb_action(str(parent_system.get("name", "Система")), "assemblies")
		_add_breadcrumb_action(str(parent_assembly.get("name", "Узел")), "node")
		_render_part(part, parent_system, parent_assembly)
	call_deferred("_prepare_page_touch_routing")

func _render_systems() -> void:
	var intro := _muted_label("Выбери систему, чтобы открыть её узлы и связанные компоненты.")
	content.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	content.add_child(grid)
	for system_value in PartCatalogService.all_systems():
		var system: Dictionary = system_value
		var id := str(system.get("id", ""))
		var button := _card_button()
		button.custom_minimum_size = Vector2(0, 102)
		grid.add_child(button)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var icon_shell := PanelContainer.new()
		icon_shell.custom_minimum_size = Vector2(42, 42)
		icon_shell.add_theme_stylebox_override("panel", _panel_style(Color("0a313a"), 13, Color("236872")))
		icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_shell)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/icons/" + str(SYSTEM_ICONS.get(id, "cube.svg")))
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = CYAN
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_shell.add_child(icon)
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.alignment = BoxContainer.ALIGNMENT_CENTER
		text_box.add_theme_constant_override("separation", 3)
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text_box)
		var name := _label(str(system.get("name", "Система")), 15, TEXT)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(name)
		var parts := PartCatalogService.parts_for_system(id).filter(func(part: Dictionary): return TechnicalCatalog.is_compatible(part, _vehicle))
		var count := _label("%d деталей · %s" % [parts.size(), str(SYSTEM_SUMMARIES.get(id, "Узлы автомобиля"))], 10, MUTED)
		count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(count)
		button.pressed.connect(_select_system.bind(id))

func _render_assemblies() -> void:
	var system: Dictionary = PartCatalogService.SYSTEMS.get(selected_system, {})
	content.add_child(_muted_label(str(SYSTEM_SUMMARIES.get(selected_system, system.get("name", "Узлы системы")))))
	for assembly_value in PartCatalogService.assemblies_for_system(selected_system):
		var assembly: Dictionary = assembly_value
		var parts: Array = _compatible_part_ids(assembly.get("parts", []))
		if parts.is_empty(): continue
		var button := _card_button()
		button.custom_minimum_size.y = 72
		var copy := VBoxContainer.new()
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_theme_constant_override("separation", 4)
		button.add_child(copy)
		copy.add_child(_label(str(assembly.get("name", "Узел")), 16, TEXT))
		copy.add_child(_muted_label("%d компонентов" % parts.size()))
		button.pressed.connect(_select_assembly.bind(str(assembly.get("id", ""))))
		content.add_child(button)

func _render_node(assembly: Dictionary) -> void:
	var part_ids: Array = _compatible_part_ids(assembly.get("parts", []))
	var count := _muted_label("%d деталей в узле. Выбери строку или нажми на компонент модели." % part_ids.size())
	content.add_child(count)
	if str(assembly.get("id", "")) == "engine_front":
		var note := _muted_label("Схематичное представление агрегатов двигателя EA111, не масштабный заводской чертёж.")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(note)
		_ensure_engine_viewer()
		content.add_child(viewer)
		viewer.load_assembly(assembly)
		if not selected_part.is_empty():
			viewer.focus_part(selected_part)
		var gesture := _muted_label("Перетаскивание — вращение · два пальца — масштаб · короткий тап — компонент")
		gesture.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(gesture)
		content.add_child(_action_button("Сбросить вид", func(): viewer.reset_view()))
	for part_id_value in part_ids:
		var part_id := str(part_id_value)
		var part := PartCatalogService.get_part(part_id)
		if part.is_empty() or not TechnicalCatalog.is_compatible(part, _vehicle):
			continue
		var button := _card_button()
		button.custom_minimum_size.y = 58
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = str(part.get("name", part_id)) + "   ›"
		button.pressed.connect(_select_part.bind(part_id))
		content.add_child(button)
	var back := _action_button("Все узлы системы", func(): _open_level("assemblies"))
	content.add_child(back)

func _render_part(part: Dictionary, system: Dictionary, assembly: Dictionary) -> void:
	if str(part.get("requires_drivetrain", "")) == "AWD":
		content.add_child(_muted_label("REFERENCE_ONLY · Справочный компонент полного привода."))
	var id := str(part.get("id", selected_part))
	content.add_child(_muted_label("%s · %s" % [str(system.get("name", "Система")), str(assembly.get("name", "Узел"))]))
	if str(assembly.get("id", "")) == "engine_front":
		var note := _muted_label("Схематичное представление агрегатов двигателя EA111.")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(note)
		_ensure_engine_viewer()
		content.add_child(viewer)
		viewer.load_assembly(assembly)
		viewer.call_deferred("focus_part", id)
		content.add_child(_action_button("Сбросить вид", func(): viewer.reset_view()))
	var description := str(PART_DESCRIPTIONS.get(id, "Деталь расположена в этой области автомобиля."))
	var description_panel := PanelContainer.new()
	description_panel.add_theme_stylebox_override("panel", _panel_style(Color("091f29f4"), 18, BORDER))
	content.add_child(description_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	description_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	var title := _label(str(part.get("name", id)), 20, TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title)
	var body := _muted_label(description)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	if id in ["engine_block", "cylinder_head", "valve_cover", "turbocharger", "alternator", "accessory_belt_drive"]:
		stack.add_child(_muted_label("На схеме показана область выбранного компонента."))
	var history := _history_text(id)
	var history_label := _muted_label(history)
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(history_label)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_add_action(actions, "Проверка", func(): diagnostic_requested.emit(id, str(part.get("name", id))))
	_add_action(actions, "Пошаговый ремонт", func(): repair_requested.emit(id, str(part.get("name", id))))
	_add_action(actions, "История детали", func(): history_requested.emit(id, str(part.get("name", id))))
	_add_action(actions, "Руководство", func(): manual_requested.emit(id, str(part.get("name", id))))
	_add_action(actions, "Записать замену", func(): replacement_requested.emit(id, str(part.get("name", id))))
	if viewer != null and is_instance_valid(viewer):
		viewer.focus_part(id)
	content.add_child(_action_button("Назад к узлу", func(): _open_level("node")))

func _add_breadcrumb_action(text_value: String, target_level: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", CYAN if target_level == level else MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(Color("071820d8"), 12, BORDER))
	button.pressed.connect(_open_level.bind(target_level))
	breadcrumb.add_child(button)
	if target_level != level:
		var separator := Label.new()
		separator.text = "›"
		separator.add_theme_color_override("font_color", MUTED)
		breadcrumb.add_child(separator)

func _select_system(system_id: String) -> void:
	selected_system = system_id
	selected_assembly = ""
	selected_part = ""
	level = "assemblies"
	_render()

func _select_assembly(assembly_id: String) -> void:
	selected_assembly = assembly_id
	selected_part = ""
	level = "node"
	_render()

func _select_part(part_id: String) -> void:
	if PartCatalogService.get_part(part_id).is_empty() or not TechnicalCatalog.is_compatible(PartCatalogService.get_part(part_id), _vehicle):
		return
	selected_part = part_id
	level = "part"
	if viewer != null and is_instance_valid(viewer):
		viewer.select_part(part_id)
	_render()

func _open_level(target: String) -> void:
	if target == "systems":
		selected_system = ""
		selected_assembly = ""
		selected_part = ""
		level = "systems"
	elif target == "assemblies" and not selected_system.is_empty():
		selected_assembly = ""
		selected_part = ""
		level = "assemblies"
	elif target == "node" and not selected_assembly.is_empty():
		selected_part = ""
		level = "node"
	_render()

func _get_assembly(system_id: String, assembly_id: String) -> Dictionary:
	for row_value in PartCatalogService.assemblies_for_system(system_id):
		var row: Dictionary = row_value
		if str(row.get("id", "")) == assembly_id:
			return row
	return {}

func _ensure_engine_viewer() -> void:
	if viewer != null and is_instance_valid(viewer):
		return
	viewer = ViewerScene.instantiate() as VehiclePartViewer
	viewer.custom_minimum_size = Vector2(0, 300)
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.part_selected.connect(_select_part)

func _card_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _panel_style(Color("091b25f5"), 16, BORDER))
	button.add_theme_stylebox_override("hover", _panel_style(Color("0b2933f5"), 16, Color("217581")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0b3039f5"), 16, CYAN))
	return button

func _action_button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color("0a2832"), 14, BORDER))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0b3039"), 14, CYAN))
	button.pressed.connect(action)
	return button

func _add_action(container: GridContainer, title: String, action: Callable) -> void:
	container.add_child(_action_button(title, action))

func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _muted_label(text_value: String) -> Label:
	var label := _label(text_value, 12, MUTED)
	return label

func _panel_style(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _history_text(part_id: String) -> String:
	if history_provider.is_valid():
		return str(history_provider.call(part_id))
	return "История детали доступна через карточку истории."

func set_vehicle_profile(vehicle: Dictionary) -> void:
	if vehicle == _vehicle:
		return
	_vehicle = vehicle.duplicate(true)
	if not selected_part.is_empty() and not TechnicalCatalog.is_compatible(PartCatalogService.get_part(selected_part), _vehicle):
		selected_part = ""
		level = "systems"
	if is_inside_tree():
		_render()

func _compatible_part_ids(ids: Array) -> Array:
	var result: Array = []
	for part_id in ids:
		var part := PartCatalogService.get_part(str(part_id))
		if not part.is_empty() and TechnicalCatalog.is_compatible(part, _vehicle):
			result.append(part_id)
	return result

func set_history_provider(provider: Callable) -> void:
	history_provider = provider

func focus_part(part_id: String) -> void:
	var part := PartCatalogService.get_part(part_id)
	if part.is_empty() or not TechnicalCatalog.is_compatible(part, _vehicle):
		return
	selected_part = part_id
	selected_system = str(part.get("system", ""))
	selected_assembly = ""
	for row_value in PartCatalogService.assemblies_for_system(selected_system):
		var row: Dictionary = row_value
		if part_id in row.get("parts", []):
			selected_assembly = str(row.get("id", ""))
			break
	if selected_assembly.is_empty():
		var assemblies := PartCatalogService.assemblies_for_system(selected_system)
		if not assemblies.is_empty():
			selected_assembly = str(assemblies[0].get("id", ""))
	level = "part"
	_render()

func _prepare_page_touch_routing() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null and not ancestor is ScrollContainer:
		ancestor = ancestor.get_parent()
	if ancestor == null:
		return
	page_scroll = ancestor as ScrollContainer
	page_scroll.scroll_deadzone = 8
	page_scroll.follow_focus = false
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.set_meta("preserve_scroll_modes", true)
	if not page_scroll.gui_input.is_connected(_on_page_scroll_input):
		page_scroll.gui_input.connect(_on_page_scroll_input)
	_set_non_viewport_mouse_filter(self)

func _set_non_viewport_mouse_filter(node: Node) -> void:
	if viewer != null and is_instance_valid(viewer) and node == viewer.subviewport_container:
		return
	if viewer != null and is_instance_valid(viewer) and viewer.subviewport_container.is_ancestor_of(node):
		return
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_non_viewport_mouse_filter(child)

func _on_page_scroll_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			page_pointer_down = true
			page_drag_distance = 0.0
			touch_start = touch.position
		else:
			if page_pointer_down and page_drag_distance < 12.0:
				_activate_control_at(page_scroll.to_global(touch.position))
			page_pointer_down = false
		return
	if event is InputEventScreenDrag and page_pointer_down:
		var drag := event as InputEventScreenDrag
		page_drag_distance += drag.relative.length()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			page_pointer_down = true
			page_drag_distance = 0.0
		else:
			if page_pointer_down and page_drag_distance < 7.0:
				_activate_control_at(page_scroll.to_global(mouse.position))
			page_pointer_down = false
		return
	if event is InputEventMouseMotion and page_pointer_down:
		page_drag_distance += (event as InputEventMouseMotion).relative.length()

func _activate_control_at(global_position: Vector2) -> void:
	var button := _find_button_at(self, global_position)
	if button != null and not button.disabled and button.visible:
		button.emit_signal("pressed")

func _find_button_at(node: Node, global_position: Vector2) -> Button:
	if viewer != null and is_instance_valid(viewer) and (node == viewer.subviewport_container or viewer.subviewport_container.is_ancestor_of(node)):
		return null
	var children := node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found := _find_button_at(children[index], global_position)
		if found != null:
			return found
	if node is Button:
		var button := node as Button
		if button.visible and button.get_global_rect().has_point(global_position):
			return button
	return null
