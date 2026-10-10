extends Control

# Yeti Garage: maintenance, diagnostics, and a vehicle technical catalog.

const MileageService = preload("res://services/mileage_service.gd")
const ServiceHistoryService = preload("res://services/service_history_service.gd")
const MaintenanceService = preload("res://services/maintenance_service.gd")
const MobileTechnicalCatalogView = preload("res://scenes/technical_catalog/technical_catalog_view.gd")
const VehicleService = preload("res://services/vehicle_service.gd")
const ReminderService = preload("res://services/reminder_service.gd")
const DiagnosticService = preload("res://services/diagnostic_service.gd")
const RepairService = preload("res://services/repair_service.gd")
const PartCatalogService = preload("res://services/part_catalog_service.gd")
const TechnicalCatalogService = preload("res://services/technical_catalog_service.gd")
const ManualSearchService = preload("res://services/manual_search_service.gd")
const FaultCatalog = preload("res://services/fault_catalog_service.gd")
const ScrollGesture = preload("res://services/mobile_scroll_gesture.gd")
const GlobalSearchLayout = preload("res://scenes/app/global_search_layout.gd")

const OFFICIAL_MANUAL_TOTAL_PAGES := 246
const OFFICIAL_MANUAL_SECTIONS := [
    {"title":"Введение", "page":1},
    {"title":"Содержание и сокращения", "page":4},
    {"title":"Управление", "page":9},
    {"title":"Безопасность", "page":140},
    {"title":"Правила вождения", "page":162},
    {"title":"Указания по использованию", "page":177},
    {"title":"Самостоятельные действия", "page":207},
    {"title":"Технические характеристики", "page":226},
    {"title":"Алфавитный указатель", "page":238}
]

var pages: TabContainer
var overview_box: VBoxContainer
var history_box: VBoxContainer
var maintenance_box: VBoxContainer
var reminders_box: VBoxContainer
var reminders_dynamic_box: VBoxContainer
var diagnostics_box: VBoxContainer
var vehicle_3d_box: VBoxContainer
var repair_box: VBoxContainer
var vehicle_3d_view
var mobile_technical_catalog := false

var header_title: Label
var header_accent: Label
var header_subtitle: Label
var vehicle_name_label: Label
var vehicle_vin_label: Label
var mileage_value: Label
var mileage_caption: Label
var engine_value: Label
var engine_caption: Label
var next_service_value: Label
var total_cost_value: Label
var recent_box: VBoxContainer
var fault_home_box: VBoxContainer
var active_saved_fault_id := ""
var reminders_summary_value: Label
var data_mode_value: Label
var notification_status_value: Label
var notification_enabled_toggle: CheckBox
var notification_controls_box: VBoxContainer
var bottom_nav: HBoxContainer
var nav_items: Array[Dictionary] = []

var event_dialog: PopupPanel
var event_dialog_title: Label
var event_dialog_scroll: ScrollContainer
var event_id_edit: LineEdit
var event_type: OptionButton
var event_title: LineEdit
var event_date: LineEdit
var event_date_unknown: CheckBox
var event_mileage: SpinBox
var event_mileage_unknown: CheckBox
var event_cost: SpinBox
var event_labor_cost: SpinBox
var event_notes: TextEdit
var engine_code: LineEdit
var engine_initial_mileage: SpinBox
var engine_initial_mileage_unknown: CheckBox
var engine_code_label: Label
var engine_initial_mileage_label: Label
var event_editing_id := ""
var event_part_id := ""

var diagnostic_flow_id: String = ""
var diagnostic_node_id: String = ""
var diagnostic_history: Array[String] = []
var diagnostic_content: VBoxContainer
var diagnostic_context_part_name: String = ""

var repair_guide_id: String = ""
var repair_step_index: int = 0
var repair_title: Label
var repair_progress: Label
var repair_part_label: Label
var repair_scope_label: Label
var repair_step_title: Label
var repair_step_body: Label
var repair_tool_label: Label
var repair_warning_label: Label
var repair_back_button: Button
var repair_next_button: Button
var repair_finish_box: VBoxContainer

func _ready() -> void:
    _build_ui()
    resized.connect(_update_nav_styles)
    _connect_signals()
    _refresh_all()
    Storage.persistence_failed.connect(_on_persistence_failed)
    if not Storage.storage_writable:
        _on_persistence_failed("Файл данных и автоматическая копия не читаются. Исходные файлы сохранены. Запись заблокирована; восстановите проверенную локальную резервную копию в настройках.")

func _on_persistence_failed(message: String) -> void:
    # Services may finish their UI update before opening the error dialog.
    _show_info_dialog.call_deferred("Ошибка сохранения", message)

func _build_ui() -> void:
    var app_theme := Theme.new()
    app_theme.default_font_size = 16
    app_theme.set_color("font_color", "Label", Color("edf6fa"))
    theme = app_theme

    var bg := ColorRect.new()
    bg.color = Color("061018")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    # One adaptive shell controls the dashboard gutters on every Android width.
    # This avoids the edge-hugging layout that appeared after enabling stretch/aspect=expand.
    var app_margin := MarginContainer.new()
    app_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    app_margin.add_theme_constant_override("margin_left", 14)
    app_margin.add_theme_constant_override("margin_right", 14)
    app_margin.add_theme_constant_override("margin_top", 4)
    app_margin.add_theme_constant_override("margin_bottom", 10)
    add_child(app_margin)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 7)
    app_margin.add_child(root)

    var header := HBoxContainer.new()
    # Header actions were removed, so keep the header tight instead of reserving
    # the old action-button height. This pulls the hero upward without shrinking it.
    header.custom_minimum_size.y = 54
    header.add_theme_constant_override("separation", 8)
    root.add_child(header)

    var header_text := VBoxContainer.new()
    header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_text.add_theme_constant_override("separation", -2)
    header.add_child(header_text)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 6)
    header_text.add_child(title_row)
    header_title = Label.new()
    header_title.text = "Yeti"
    header_title.add_theme_font_size_override("font_size", 31)
    header_title.add_theme_color_override("font_color", Color("f6fbfd"))
    title_row.add_child(header_title)
    header_accent = Label.new()
    header_accent.text = "Garage"
    header_accent.add_theme_font_size_override("font_size", 31)
    header_accent.add_theme_color_override("font_color", Color("18e4e8"))
    title_row.add_child(header_accent)

    header_subtitle = Label.new()
    header_subtitle.add_theme_font_size_override("font_size", 15)
    header_subtitle.add_theme_color_override("font_color", Color("94a9b6"))
    header_text.add_child(header_subtitle)

    # Header actions intentionally omitted: reminders are available from the
    # dashboard card, and vehicle data from the contextual pencil on the hero.
    # Keeping only one entry point per action makes the dashboard calmer.

    pages = TabContainer.new()
    pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
    pages.tabs_visible = false
    pages.clip_contents = true
    root.add_child(pages)

    overview_box = _make_scroll_page("Машина")
    history_box = _make_scroll_page("История")
    maintenance_box = _make_scroll_page("ТО")
    reminders_box = _make_scroll_page("Напом.")
    diagnostics_box = _make_scroll_page("Диагн.")
    mobile_technical_catalog = _is_mobile_runtime()
    vehicle_3d_box = _make_scroll_page("Техсправочник" if mobile_technical_catalog else "3D")
    repair_box = _make_scroll_page("Ремонт")

    _build_overview()
    _build_history_page()
    _build_maintenance_page()
    _build_reminders_page()
    _build_diagnostics_page()
    _build_3d_page()
    _build_repair_page()
    _build_event_dialog()
    _build_bottom_navigation(root)
    _apply_touch_targets(self)
    _update_nav_styles()

func _make_scroll_page(title: String) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.name = title
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.scroll_deadzone = 10
    scroll.follow_focus = true
    pages.add_child(scroll)
    ScrollGesture.attach(scroll)
    # Long sections keep swipe scrolling, but never expose scrollbars.
    # Scrollable sections hide their bars; the technical catalog remains in this
    # same outer scroll area while its diagram canvas handles zoomed image gestures.
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    var vbar := scroll.get_v_scroll_bar()
    if vbar != null:
        vbar.modulate = Color(1, 1, 1, 0)
        vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbar.custom_minimum_size.x = 0
    var hbar := scroll.get_h_scroll_bar()
    if hbar != null:
        hbar.modulate = Color(1, 1, 1, 0)
        hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hbar.custom_minimum_size.y = 0
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 10)
    box.mouse_filter = Control.MOUSE_FILTER_PASS
    scroll.add_child(box)
    return box

func _is_mobile_runtime() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or ProjectSettings.get_setting("application/testing/mobile_ui", false)

func _build_bottom_navigation(root: VBoxContainer) -> void:
    var shell := PanelContainer.new()
    shell.custom_minimum_size.y = 82
    shell.add_theme_stylebox_override("panel", _style_box(Color("07131be8"), 26, Color("173845"), 1, Color("00e5e51f"), 3))
    root.add_child(shell)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 5)
    margin.add_theme_constant_override("margin_right", 5)
    margin.add_theme_constant_override("margin_top", 5)
    margin.add_theme_constant_override("margin_bottom", 4)
    shell.add_child(margin)

    bottom_nav = HBoxContainer.new()
    bottom_nav.add_theme_constant_override("separation", 1)
    margin.add_child(bottom_nav)
    nav_items.clear()

    _add_nav_button("Машина", "res://assets/ui/icons/car.svg", overview_box)
    _add_nav_button("Диагностика", "res://assets/ui/icons/diagnostic.svg", diagnostics_box)
    _add_nav_button("Справочник" if mobile_technical_catalog else "3D", "res://assets/ui/icons/book.svg" if mobile_technical_catalog else "res://assets/ui/icons/cube.svg", vehicle_3d_box)
    _add_nav_button("История", "res://assets/ui/icons/history.svg", history_box)
    _add_nav_button("Ещё", "res://assets/ui/icons/more.svg", null, _open_more_menu)

func _add_nav_button(label_text: String, icon_path: String, target_box: VBoxContainer, custom_action: Callable = Callable()) -> void:
    var item := Panel.new()
    item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item.custom_minimum_size = Vector2(0, 68)
    item.mouse_filter = Control.MOUSE_FILTER_PASS
    bottom_nav.add_child(item)

    var stack := VBoxContainer.new()
    stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    stack.offset_top = 5
    stack.offset_bottom = -6
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 2)
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    item.add_child(stack)

    var icon_shell := PanelContainer.new()
    icon_shell.custom_minimum_size = Vector2(42, 34)
    icon_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_shell.add_theme_stylebox_override("panel", _style_box(Color("00000000"), 17))
    stack.add_child(icon_shell)

    var icon_center := _centered_icon(icon_path, 27, Color("91a6b2"))
    icon_shell.add_child(icon_center)
    var icon := icon_center.get_child(0) as TextureRect

    var label := Label.new()
    label.text = label_text
    label.set_meta("nav_label", label_text)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color("91a6b2"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(label)

    var line := ColorRect.new()
    line.color = Color("19edf0")
    line.custom_minimum_size = Vector2(42, 2)
    line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    line.visible = false
    stack.add_child(line)

    var button := Button.new()
    button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_stylebox_override("normal", _style_box(Color("00000000"), 18))
    button.add_theme_stylebox_override("hover", _style_box(Color("09283266"), 18, Color("14758366"), 1))
    button.add_theme_stylebox_override("pressed", _style_box(Color("07323b88"), 18, Color("17e9ec88"), 1))
    item.add_child(button)

    var target := -1
    if target_box != null:
        target = _tab_index_for_box(target_box)
        button.pressed.connect(_switch_to_page.bind(target_box))
    elif custom_action.is_valid():
        button.pressed.connect(custom_action)

    nav_items.append({"panel": item, "icon_shell": icon_shell, "icon": icon, "label": label, "line": line, "target": target})

func _switch_to_page(target_box: VBoxContainer) -> void:
    var tab_index := _tab_index_for_box(target_box)
    if tab_index < 0:
        return
    pages.current_tab = tab_index
    _update_nav_styles()

func _tab_index_for_box(target_box: VBoxContainer) -> int:
    if target_box == null or pages == null:
        return -1
    var parent := target_box.get_parent()
    if parent == pages:
        return target_box.get_index()
    if parent != null and parent.get_parent() == pages:
        return parent.get_index()
    return -1

func _update_nav_styles() -> void:
    if pages == null:
        return
    var current := pages.current_tab
    for item_value in nav_items:
        var item: Dictionary = item_value
        var target := int(item.get("target", -1))
        var active := target == current
        if target == 5 and current == 6:
            active = true
        if target == -1:
            active = current in [2, 3]
        var panel := item.get("panel") as Panel
        var icon_shell := item.get("icon_shell") as PanelContainer
        var icon := item.get("icon") as TextureRect
        var label := item.get("label") as Label
        var line := item.get("line") as ColorRect
        if panel != null:
            panel.add_theme_stylebox_override("panel", _style_box(Color("06171f35") if active else Color("00000000"), 18))
        if icon_shell != null:
            icon_shell.add_theme_stylebox_override("panel", _style_box(
                Color("07343dc4") if active else Color("00000000"),
                17,
                Color("20f4f0a0") if active else Color("00000000"),
                1 if active else 0,
                Color("00f5f542") if active else Color("00000000"),
                4 if active else 0
            ))
        if icon != null:
            icon.modulate = Color("16edf0") if active else Color("91a6b2")
        if label != null:
            var full_label := str(label.get_meta("nav_label", label.text))
            label.text = {"Диагностика":"Диагн.", "Справочник":"Каталог"}.get(full_label, full_label) if get_viewport_rect().size.x < 400.0 else full_label
            label.add_theme_color_override("font_color", Color("16edf0") if active else Color("91a6b2"))
        if line != null:
            line.visible = active

func _open_more_menu() -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(330, 370)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df2"), 24, Color("1d5862"), 1, Color("12dfe928"), 4))
    popup.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    box.add_child(title_row)
    var title := Label.new()
    title.text = "Ещё"
    title.add_theme_font_size_override("font_size", 24)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(title)
    var close_more := _popup_close_button()
    close_more.pressed.connect(func(): popup.hide())
    title_row.add_child(close_more)
    _add_more_action(box, "Полное руководство", func():
        popup.hide()
        _open_manual_hub()
    )
    _add_more_action(box, "Копировать данные для переноса", func():
        popup.hide()
        _copy_backup_to_clipboard()
    )
    _add_more_action(box, "Импортировать данные из буфера", func():
        popup.hide()
        _confirm_import_from_clipboard()
    )
    _add_more_action(box, "Локальная резервная копия", func():
        _create_manual_backup()
        popup.hide()
    )
    _add_more_action(box, "Восстановить локальную копию", func():
        _confirm_restore_manual_backup()
        popup.hide()
    )
    _apply_touch_targets(popup)
    popup.popup_centered(_mobile_dialog_size(Vector2i(350, 410)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _add_more_action(box: VBoxContainer, text_value: String, action: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size.y = 48
    button.add_theme_stylebox_override("normal", _style_box(Color("0b2029"), 15, Color("174451"), 1))
    button.add_theme_stylebox_override("hover", _style_box(Color("0c3038"), 15, Color("12dfe9"), 1))
    button.pressed.connect(action)
    box.add_child(button)

func _open_manual_hub() -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(330, 0)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df2"), 24, Color("1d5862"), 1, Color("12dfe928"), 4))
    popup.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    box.add_child(title_row)
    var title := Label.new()
    title.text = "Полное руководство"
    title.add_theme_font_size_override("font_size", 22)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    var hint := Label.new()
    hint.text = "Официальное руководство ŠKODA Yeti и инструменты Yeti Garage — в одном месте."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_font_size_override("font_size", 12)
    hint.add_theme_color_override("font_color", Color("91a9b5"))
    box.add_child(hint)

    _add_more_action(box, "Руководство ŠKODA Yeti", func():
        popup.hide()
        _open_official_manual()
    )
    _add_more_action(box, "Найти деталь или проблему", func():
        popup.hide()
        _open_global_search()
    )
    _add_more_action(box, "Диагностика по симптомам", func():
        popup.hide()
        _switch_to_page(diagnostics_box)
    )
    _add_more_action(box, "Технический справочник" if mobile_technical_catalog else "3D-схема автомобиля", func():
        popup.hide()
        _switch_to_page(vehicle_3d_box)
    )

    _apply_touch_targets(popup)
    popup.popup_centered(_mobile_dialog_size(Vector2i(350, 380)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _open_official_manual(start_page: int = 0) -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    # Popup defaults to wrap_controls=true. In the manual this is dangerous: a tall
    # page can increase the popup minimum height and push the bottom edge off-screen.
    # The popup owns the viewport-sized frame; the ScrollContainer owns overflow.
    popup.wrap_controls = false
    add_child(popup)

    var panel := PanelContainer.new()
    # IMPORTANT: with wrap_controls=false a Control child of Window is NOT sized
    # from the popup automatically. If left at its content minimum, the whole VBox
    # becomes taller than the window, gets clipped by the popup, and the inner
    # ScrollContainer believes it already has enough height -> max scroll = 0.
    # Pin the frame to the actual popup rect so only the reading area can overflow.
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(390), 0)
    panel.clip_contents = true
    panel.add_theme_stylebox_override("panel", _style_box(Color("06131bf8"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    root.add_child(title_row)
    var title := Label.new()
    title.text = "Руководство ŠKODA Yeti"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color("f3fbfc"))
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    # The manual opens straight into a clean chapter list. While reading, this row
    # becomes a compact way back to chapters; there is no second/nested popup.
    var nav_row := HBoxContainer.new()
    nav_row.add_theme_constant_override("separation", 8)
    root.add_child(nav_row)

    var chapters_button := Button.new()
    chapters_button.text = "Главы"
    chapters_button.custom_minimum_size = Vector2(72, 40)
    chapters_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapters_button.add_theme_font_size_override("font_size", 13)
    nav_row.add_child(chapters_button)

    var page_label := Label.new()
    page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    page_label.add_theme_font_size_override("font_size", 12)
    page_label.add_theme_color_override("font_color", Color("b8cbd4"))
    nav_row.add_child(page_label)

    var prev := Button.new()
    prev.text = "‹"
    prev.tooltip_text = "Предыдущая страница"
    prev.custom_minimum_size = Vector2(40, 40)
    prev.set_meta("compact_icon_button", true)
    prev.add_theme_font_size_override("font_size", 23)
    nav_row.add_child(prev)

    var next := Button.new()
    next.text = "›"
    next.tooltip_text = "Следующая страница"
    next.custom_minimum_size = Vector2(40, 40)
    next.set_meta("compact_icon_button", true)
    next.add_theme_font_size_override("font_size", 23)
    nav_row.add_child(next)

    var content_panel := PanelContainer.new()
    content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_panel.size_flags_stretch_ratio = 1.0
    content_panel.add_theme_stylebox_override("panel", _style_box(Color("071a23d9"), 18, Color("163e49"), 1))
    root.add_child(content_panel)

    var content_scroll := ScrollContainer.new()
    content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    content_scroll.scroll_deadzone = 8
    content_scroll.follow_focus = false
    content_scroll.set_meta("preserve_scroll_modes", true)
    content_panel.add_child(content_scroll)

    var content_margin := MarginContainer.new()
    content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    content_margin.add_theme_constant_override("margin_left", 14)
    content_margin.add_theme_constant_override("margin_right", 14)
    content_margin.add_theme_constant_override("margin_top", 14)
    # Keep only a normal reading gutter. Older builds stacked several large
    # bottom reserves here and in the page tail, which could influence popup sizing.
    content_margin.add_theme_constant_override("margin_bottom", 18)
    content_scroll.add_child(content_margin)

    var content_box := VBoxContainer.new()
    content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    content_box.add_theme_constant_override("separation", 10)
    content_margin.add_child(content_box)

    var requested_page := 1 if start_page <= 0 else clampi(start_page, 1, OFFICIAL_MANUAL_TOTAL_PAGES)
    var manual_state := {
        "page": requested_page,
        "chapters": start_page <= 0
    }

    var refresh_holder: Dictionary = {}
    var refresh_page: Callable
    refresh_page = func():
        # A new manual page must start with a clean layout. Height from the previous
        # page is intentionally discarded before any wrapped labels are measured.
        content_box.custom_minimum_size.y = 0.0
        content_margin.custom_minimum_size.y = 0.0
        content_scroll.scroll_vertical = 0
        content_scroll.scroll_horizontal = 0
        if bool(manual_state["chapters"]):
            _render_manual_chapter_list(content_box, int(manual_state["page"]), manual_state, refresh_holder)
            nav_row.visible = false
            _apply_touch_targets(content_box)
            _settle_manual_scroll_extent(content_scroll, content_margin, content_box, true)
            return

        manual_state["page"] = clampi(int(manual_state["page"]), 1, OFFICIAL_MANUAL_TOTAL_PAGES)
        var page := int(manual_state["page"])
        var entry := ManualSearchService.page_entry(page)
        _render_native_manual_page(content_box, entry, page, popup)
        nav_row.visible = true
        chapters_button.visible = true
        page_label.text = _manual_page_reference(entry, page)
        prev.disabled = page <= 1
        next.disabled = page >= OFFICIAL_MANUAL_TOTAL_PAGES
        _apply_touch_targets(content_box)
        _settle_manual_scroll_extent(content_scroll, content_margin, content_box, true)

    refresh_holder["call"] = refresh_page

    # Wrapped labels change their height only after Godot knows the final phone width.
    # Recalculate the scrollable extent after layout, and again on viewport resize.
    content_scroll.resized.connect(func():
        _settle_manual_scroll_extent(content_scroll, content_margin, content_box, false)
    )

    chapters_button.pressed.connect(func():
        manual_state["chapters"] = true
        refresh_page.call()
    )
    prev.pressed.connect(func():
        manual_state["chapters"] = false
        manual_state["page"] = _manual_neighbor_page(int(manual_state["page"]), -1)
        refresh_page.call()
    )
    next.pressed.connect(func():
        manual_state["chapters"] = false
        manual_state["page"] = _manual_neighbor_page(int(manual_state["page"]), 1)
        refresh_page.call()
    )

    # Keep vertical reading intact, but treat a deliberate horizontal gesture as
    # page turning. Text/figure children pass the gesture up to this ScrollContainer.
    var swipe_state := {"active": false, "dx": 0.0, "dy": 0.0}
    content_scroll.gui_input.connect(func(event: InputEvent):
        if bool(manual_state["chapters"]):
            return
        if event is InputEventScreenTouch:
            var touch := event as InputEventScreenTouch
            if touch.pressed:
                swipe_state["active"] = true
                swipe_state["dx"] = 0.0
                swipe_state["dy"] = 0.0
            elif bool(swipe_state["active"]):
                var dx := float(swipe_state["dx"])
                var dy := float(swipe_state["dy"])
                swipe_state["active"] = false
                if absf(dx) >= 72.0 and absf(dx) > absf(dy) * 1.20:
                    var direction := 1 if dx < 0.0 else -1
                    manual_state["page"] = _manual_neighbor_page(int(manual_state["page"]), direction)
                    refresh_page.call()
        elif event is InputEventScreenDrag and bool(swipe_state["active"]):
            var drag := event as InputEventScreenDrag
            swipe_state["dx"] = float(swipe_state["dx"]) + drag.relative.x
            swipe_state["dy"] = float(swipe_state["dy"]) + drag.relative.y
        elif event is InputEventMouseButton:
            var mouse_button := event as InputEventMouseButton
            if mouse_button.button_index == MOUSE_BUTTON_LEFT:
                if mouse_button.pressed:
                    swipe_state["active"] = true
                    swipe_state["dx"] = 0.0
                    swipe_state["dy"] = 0.0
                elif bool(swipe_state["active"]):
                    var mouse_dx := float(swipe_state["dx"])
                    var mouse_dy := float(swipe_state["dy"])
                    swipe_state["active"] = false
                    if absf(mouse_dx) >= 72.0 and absf(mouse_dx) > absf(mouse_dy) * 1.20:
                        var mouse_direction := 1 if mouse_dx < 0.0 else -1
                        manual_state["page"] = _manual_neighbor_page(int(manual_state["page"]), mouse_direction)
                        refresh_page.call()
        elif event is InputEventMouseMotion and bool(swipe_state["active"]):
            var motion := event as InputEventMouseMotion
            if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                swipe_state["dx"] = float(swipe_state["dx"]) + motion.relative.x
                swipe_state["dy"] = float(swipe_state["dy"]) + motion.relative.y
    )

    refresh_page.call()
    _apply_touch_targets(popup)
    var manual_popup_size := _mobile_dialog_size(Vector2i(400, 780))
    # Clamped centering is a second guard against Android/system-bar edge cases.
    popup.popup_centered_clamped(manual_popup_size, 0.96)
    # Re-assert a zero-offset full-rect frame after Window receives its final size.
    # This is deliberately deferred because Android reports the popup dimensions
    # only after the native window/layout pass.
    await get_tree().process_frame
    if is_instance_valid(popup) and is_instance_valid(panel):
        panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        panel.position = Vector2.ZERO
        panel.size = Vector2(popup.size)
        panel.set_meta("manual_popup_size", popup.size)
        _settle_manual_scroll_extent(content_scroll, content_margin, content_box, false)
    popup.popup_hide.connect(func(): popup.queue_free())

func _manual_descendant_bottom(root: Control, node: Node) -> float:
    # Measure what is actually drawn, not only a container's cached minimum size.
    # This matters for Android autowrapped labels inside notice/figure cards.
    var bottom := 0.0
    for child in node.get_children():
        if child is Control:
            var control := child as Control
            if not control.visible:
                continue
            var relative_bottom := control.get_global_rect().end.y - root.get_global_rect().position.y
            bottom = maxf(bottom, relative_bottom)
            bottom = maxf(bottom, _manual_descendant_bottom(root, control))
    return bottom

func _settle_manual_scroll_extent(scroll: ScrollContainer, content_margin: MarginContainer, content_box: VBoxContainer, reset_to_top: bool = false) -> void:
    if not is_instance_valid(scroll) or not is_instance_valid(content_margin) or not is_instance_valid(content_box):
        return

    # Every render gets its own generation. An older coroutine must never resize a
    # page that the user has already left.
    var generation := int(scroll.get_meta("manual_layout_generation", 0)) + 1
    scroll.set_meta("manual_layout_generation", generation)

    # call_deferred() can run several times before a real Android layout frame.
    # Waiting for actual process frames lets Label autowrap, notice cards and images
    # obtain their final on-screen height before the scroll range is locked in.
    for _frame_index in range(8):
        await get_tree().process_frame
        if not is_instance_valid(scroll) or not is_instance_valid(content_margin) or not is_instance_valid(content_box):
            return
        if int(scroll.get_meta("manual_layout_generation", 0)) != generation:
            return

        var viewport_width := maxf(1.0, scroll.size.x)
        content_margin.custom_minimum_size.x = viewport_width
        content_box.custom_minimum_size.x = maxf(1.0, viewport_width - 28.0)
        content_box.update_minimum_size()
        content_margin.update_minimum_size()
        if reset_to_top:
            scroll.scroll_vertical = 0
            var settling_bar := scroll.get_v_scroll_bar()
            if settling_bar != null:
                settling_bar.value = 0.0

    # The old reader trusted only VBoxContainer.size/minimum_size. On Android that
    # value can be shorter than the visible wrapped text inside nested warning and
    # note cards. The video repro shows the scroll hitting its limit while text is
    # still visible below the viewport. Measure every drawn descendant instead.
    var actual_bottom := _manual_descendant_bottom(content_box, content_box)
    actual_bottom = maxf(actual_bottom, content_box.get_combined_minimum_size().y)

    # Give the real content a bottom runway inside the *scroll child itself*.
    # This makes the last line, warning card or figure fully lift above Android's
    # navigation area instead of stopping half-hidden at the lower edge.
    var bottom_runway := 32.0
    content_box.custom_minimum_size.y = ceilf(actual_bottom + bottom_runway)
    content_box.update_minimum_size()
    content_margin.update_minimum_size()

    # Allow the ScrollContainer to rebuild max_value from the new child height.
    await get_tree().process_frame
    if not is_instance_valid(scroll) or int(scroll.get_meta("manual_layout_generation", 0)) != generation:
        return
    if reset_to_top:
        scroll.scroll_vertical = 0
        var final_bar := scroll.get_v_scroll_bar()
        if final_bar != null:
            final_bar.value = 0.0


func _render_manual_chapter_list(container: VBoxContainer, current_page: int, manual_state: Dictionary, refresh_holder: Dictionary) -> void:
    _clear_children(container)
    container.add_theme_constant_override("separation", 8)

    for section_value in OFFICIAL_MANUAL_SECTIONS:
        var section: Dictionary = section_value
        var section_page := int(section.get("page", 1))
        var selected := _manual_section_title_for_page(current_page) == str(section.get("title", ""))
        var row := Button.new()
        row.text = str(section.get("title", "Раздел"))
        row.alignment = HORIZONTAL_ALIGNMENT_LEFT
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.custom_minimum_size.y = 52
        row.focus_mode = Control.FOCUS_NONE
        row.add_theme_font_size_override("font_size", 14)
        row.add_theme_color_override("font_color", Color("55e7ea") if selected else Color("e7f5f8"))

        var normal_style := _style_box(Color("0b2831ed") if selected else Color("081b24e8"), 14, Color("2b9ca7") if selected else Color("18434e"), 1)
        normal_style.content_margin_left = 18.0
        normal_style.content_margin_right = 14.0
        normal_style.content_margin_top = 11.0
        normal_style.content_margin_bottom = 11.0
        row.add_theme_stylebox_override("normal", normal_style)

        var hover_style := _style_box(Color("0b313bee"), 14, Color("29cbd2"), 1)
        hover_style.content_margin_left = 18.0
        hover_style.content_margin_right = 14.0
        hover_style.content_margin_top = 11.0
        hover_style.content_margin_bottom = 11.0
        row.add_theme_stylebox_override("hover", hover_style)

        var pressed_style := _style_box(Color("0a343dee"), 14, Color("36e3e7"), 1)
        pressed_style.content_margin_left = 18.0
        pressed_style.content_margin_right = 14.0
        pressed_style.content_margin_top = 11.0
        pressed_style.content_margin_bottom = 11.0
        row.add_theme_stylebox_override("pressed", pressed_style)

        row.pressed.connect(_manual_select_chapter.bind(manual_state, refresh_holder, section_page))
        container.add_child(row)

    var bottom_space := Control.new()
    bottom_space.custom_minimum_size.y = 28
    bottom_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(bottom_space)

func _manual_select_chapter(manual_state: Dictionary, refresh_holder: Dictionary, page: int) -> void:
    manual_state["page"] = clampi(page, 1, OFFICIAL_MANUAL_TOTAL_PAGES)
    manual_state["chapters"] = false
    var callback_value: Variant = refresh_holder.get("call", null)
    if callback_value is Callable:
        var callback: Callable = callback_value
        if callback.is_valid():
            callback.call()

func _manual_section_title_for_page(page: int) -> String:
    var result := "Руководство"
    for section_value in OFFICIAL_MANUAL_SECTIONS:
        var section: Dictionary = section_value
        if int(section.get("page", 1)) <= page:
            result = str(section.get("title", result))
    return result

func _manual_neighbor_page(current_page: int, direction: int) -> int:
    var step: int = -1 if direction < 0 else 1
    var candidate: int = clampi(current_page + step, 1, OFFICIAL_MANUAL_TOTAL_PAGES)
    while candidate >= 1 and candidate <= OFFICIAL_MANUAL_TOTAL_PAGES:
        var entry: Dictionary = ManualSearchService.page_entry(candidate)
        var blocks_value: Variant = entry.get("blocks", [])
        var has_blocks: bool = false
        if blocks_value is Array:
            has_blocks = not (blocks_value as Array).is_empty()
        if has_blocks or str(entry.get("text", "")).strip_edges() != "":
            return candidate
        candidate += step
    return current_page

func _manual_page_reference(entry: Dictionary, document_page: int) -> String:
    var manual_page_value = entry.get("manual_page", null)
    if manual_page_value != null and int(manual_page_value) > 0:
        return "стр. %d" % int(manual_page_value)

    var source_document_page := int(entry.get("source_document_page", document_page))
    return "стр. документа %d" % source_document_page

func _manual_normalized_blocks(raw_value: Variant) -> Array:
    var source: Array = []
    if raw_value is Array:
        source = raw_value as Array
    var result: Array = []
    var i := 0
    while i < source.size():
        var current_value: Variant = source[i]
        if not (current_value is Dictionary):
            i += 1
            continue
        var current: Dictionary = (current_value as Dictionary).duplicate(true)
        var current_type := str(current.get("type", ""))
        if current_type == "bullet":
            var merged_text := str(current.get("text", "")).strip_edges()
            while i + 1 < source.size():
                var next_value: Variant = source[i + 1]
                if not (next_value is Dictionary):
                    break
                var next_block: Dictionary = next_value as Dictionary
                if str(next_block.get("type", "")) != "paragraph":
                    break
                var next_text := str(next_block.get("text", "")).strip_edges()
                if not _manual_is_continuation(merged_text, next_text):
                    break
                merged_text = (merged_text + " " + next_text).strip_edges()
                i += 1
            current["text"] = merged_text
        elif current_type == "paragraph":
            var paragraph_text := str(current.get("text", "")).strip_edges()
            while i + 1 < source.size():
                var next_value: Variant = source[i + 1]
                if not (next_value is Dictionary):
                    break
                var next_block: Dictionary = next_value as Dictionary
                if str(next_block.get("type", "")) != "paragraph":
                    break
                var next_text := str(next_block.get("text", "")).strip_edges()
                if not _manual_is_continuation(paragraph_text, next_text):
                    break
                paragraph_text = (paragraph_text + " " + next_text).strip_edges()
                i += 1
            current["text"] = paragraph_text
        elif current_type in ["warning", "note", "caution", "eco"]:
            var notice_text := str(current.get("text", "")).strip_edges()
            while i + 1 < source.size():
                var next_value: Variant = source[i + 1]
                if not (next_value is Dictionary):
                    break
                var next_block: Dictionary = next_value as Dictionary
                var next_title := str(next_block.get("title", ""))
                if str(next_block.get("type", "")) != current_type or not next_title.to_lower().contains("продолжение"):
                    break
                notice_text = (notice_text + "\n\n" + str(next_block.get("text", "")).strip_edges()).strip_edges()
                i += 1
            current["text"] = notice_text
        result.append(current)
        i += 1
    return result

func _manual_is_continuation(current_text: String, next_text: String) -> bool:
    if current_text == "" or next_text == "":
        return false
    var ending := current_text.right(1)
    if ending in [".", "!", "?", ";", ":", "»", ")"]:
        return false
    var first := next_text.substr(0, 1)
    return first == first.to_lower() and first != first.to_upper()


func _render_native_manual_page(container: VBoxContainer, entry: Dictionary, document_page: int, manual_popup: PopupPanel) -> void:
    _clear_children(container)

    var chapter := Label.new()
    chapter.text = str(entry.get("chapter", "Руководство")).to_upper()
    chapter.add_theme_font_size_override("font_size", 11)
    chapter.add_theme_color_override("font_color", Color("42e3e6"))
    chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chapter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chapter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(chapter)

    var page_title := Label.new()
    page_title.text = str(entry.get("title", "Страница %d" % document_page))
    page_title.add_theme_font_size_override("font_size", 20)
    page_title.add_theme_color_override("font_color", Color("f2fafc"))
    page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    page_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(page_title)

    var source := Label.new()
    source.text = "Источник: Руководство по эксплуатации ŠKODA Yeti • %s" % _manual_page_reference(entry, document_page)
    source.add_theme_font_size_override("font_size", 10)
    source.add_theme_color_override("font_color", Color("76909b"))
    source.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    source.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(source)

    var divider := HSeparator.new()
    divider.modulate = Color("1d5862")
    container.add_child(divider)

    var blocks: Array = _manual_normalized_blocks(entry.get("blocks", []))
    if blocks.is_empty():
        var fallback := Label.new()
        fallback.text = str(entry.get("display_text", entry.get("text", "Текст этой страницы отсутствует.")))
        fallback.add_theme_font_size_override("font_size", 16)
        fallback.add_theme_color_override("font_color", Color("c9d9df"))
        fallback.add_theme_constant_override("line_spacing", 5)
        fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
        container.add_child(fallback)
        _add_manual_page_tail(container)
        return

    for block_value in blocks:
        if not (block_value is Dictionary):
            continue
        var block: Dictionary = block_value
        var block_type := str(block.get("type", "paragraph"))
        var text_value := str(block.get("text", "")).strip_edges()
        if text_value == "" and block_type not in ["warning", "caution", "note", "eco"]:
            continue
        match block_type:
            "heading":
                var heading := Label.new()
                heading.text = text_value
                heading.add_theme_font_size_override("font_size", 17)
                heading.add_theme_color_override("font_color", Color("eaf8fa"))
                heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
                container.add_child(heading)
            "bullet":
                var bullet_row := HBoxContainer.new()
                bullet_row.add_theme_constant_override("separation", 8)
                var dot := Label.new()
                dot.text = "•"
                dot.add_theme_font_size_override("font_size", 18)
                dot.add_theme_color_override("font_color", Color("35e5e8"))
                bullet_row.add_child(dot)
                var bullet_text := Label.new()
                bullet_text.text = text_value
                bullet_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                bullet_text.add_theme_font_size_override("font_size", 15)
                bullet_text.add_theme_color_override("font_color", Color("c9d9df"))
                bullet_text.add_theme_constant_override("line_spacing", 4)
                bullet_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                bullet_row.add_child(bullet_text)
                container.add_child(bullet_row)
            "warning", "caution", "note", "eco":
                _add_manual_notice(container, block_type, str(block.get("title", "")), text_value)
            "figure_ref":
                _add_manual_figure(container, block, text_value, manual_popup)
            _:
                var body := Label.new()
                body.text = text_value
                body.add_theme_font_size_override("font_size", 16)
                body.add_theme_color_override("font_color", Color("c9d9df"))
                body.add_theme_constant_override("line_spacing", 5)
                body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
                body.mouse_filter = Control.MOUSE_FILTER_IGNORE
                container.add_child(body)

    _add_manual_page_tail(container)

func _add_manual_figure(container: VBoxContainer, block: Dictionary, caption_text: String, manual_popup: PopupPanel) -> void:
    var image_path := str(block.get("image", ""))
    if image_path == "" or not ResourceLoader.exists(image_path):
        var missing := Label.new()
        missing.text = "Схема / иллюстрация: %s" % caption_text
        missing.add_theme_font_size_override("font_size", 12)
        missing.add_theme_color_override("font_color", Color("7f98a3"))
        missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        container.add_child(missing)
        return

    var texture := load(image_path) as Texture2D
    if texture == null:
        return

    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _style_box(Color("0a1c24ee"), 16, Color("1c515c"), 1))
    container.add_child(panel)

    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 7)
    margin.add_child(box)

    var source_w := maxf(1.0, float(block.get("image_width", texture.get_width())))
    var source_h := maxf(1.0, float(block.get("image_height", texture.get_height())))
    var display_w := minf(330.0, _mobile_dialog_content_width(360.0) - 42.0)
    var display_h := clampf(display_w * source_h / source_w, 108.0, 230.0)

    var image_button := Button.new()
    image_button.icon = texture
    image_button.expand_icon = true
    image_button.custom_minimum_size = Vector2(0, display_h)
    image_button.focus_mode = Control.FOCUS_NONE
    image_button.mouse_filter = Control.MOUSE_FILTER_PASS
    image_button.tooltip_text = "Открыть крупно"
    image_button.add_theme_stylebox_override("normal", _style_box(Color("d9dde0"), 10, Color("2a616b"), 1))
    image_button.add_theme_stylebox_override("hover", _style_box(Color("edf0f1"), 10, Color("36e3e7"), 1))
    image_button.add_theme_stylebox_override("pressed", _style_box(Color("cbd0d3"), 10, Color("36e3e7"), 1))
    image_button.pressed.connect(_open_manual_figure.bind(image_path, caption_text, manual_popup))
    box.add_child(image_button)

    var caption := Label.new()
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caption.text = caption_text
    caption.add_theme_font_size_override("font_size", 13)
    caption.add_theme_color_override("font_color", Color("d6e6eb"))
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(caption)

    var hint := Label.new()
    hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint.text = "Нажми на изображение, чтобы увеличить"
    hint.add_theme_font_size_override("font_size", 10)
    hint.add_theme_color_override("font_color", Color("6f909a"))
    box.add_child(hint)

func _open_manual_figure(image_path: String, caption_text: String, manual_popup: PopupPanel = null) -> void:
    if image_path == "" or not ResourceLoader.exists(image_path):
        return
    var texture := load(image_path) as Texture2D
    if texture == null:
        return

    # Keep the reader alive underneath the figure viewer. A sibling PopupPanel can
    # dismiss the manual on Android, so the viewer is attached to the manual window.
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    if manual_popup != null and is_instance_valid(manual_popup):
        manual_popup.add_child(popup)
    else:
        add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(0, 0)
    panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    panel.add_theme_stylebox_override("panel", _style_box(Color("051018fb"), 22, Color("1b4a55"), 1, Color("00dfe825"), 3))
    popup.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    root.add_child(title_row)

    var title := Label.new()
    title.text = "Схема из руководства"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color("f1fafc"))
    title_row.add_child(title)

    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    var caption := Label.new()
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caption.text = caption_text
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_font_size_override("font_size", 12)
    caption.add_theme_color_override("font_color", Color("a8bec7"))
    root.add_child(caption)

    # Three compact controls always fit on a phone: minus, current scale/reset, plus.
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 8)
    root.add_child(controls)

    var zoom_out := Button.new()
    zoom_out.text = "−"
    zoom_out.custom_minimum_size = Vector2(50, 44)
    zoom_out.add_theme_font_size_override("font_size", 22)
    controls.add_child(zoom_out)

    var zoom_reset := Button.new()
    zoom_reset.text = "100%"
    zoom_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    zoom_reset.custom_minimum_size.y = 44
    zoom_reset.add_theme_font_size_override("font_size", 13)
    controls.add_child(zoom_reset)

    var zoom_in := Button.new()
    zoom_in.text = "+"
    zoom_in.custom_minimum_size = Vector2(50, 44)
    zoom_in.add_theme_font_size_override("font_size", 22)
    controls.add_child(zoom_in)

    var zoom_hint := Label.new()
    zoom_hint.text = "Щипок двумя пальцами — масштаб • одним пальцем — двигать"
    zoom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    zoom_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    zoom_hint.add_theme_font_size_override("font_size", 10)
    zoom_hint.add_theme_color_override("font_color", Color("6f909a"))
    root.add_child(zoom_hint)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    scroll.scroll_deadzone = 4
    scroll.follow_focus = true
    scroll.set_meta("preserve_scroll_modes", true)
    var source_w := maxf(1.0, float(texture.get_width()))
    var source_h := maxf(1.0, float(texture.get_height()))
    var viewport_size := get_viewport_rect().size
    var max_image_w := minf(340.0, maxf(180.0, viewport_size.x - 80.0))
    var max_image_h := maxf(150.0, viewport_size.y * 0.48)
    var image_ratio := source_w / source_h
    var fit_size := Vector2(max_image_w, max_image_h)
    if image_ratio > max_image_w / max_image_h:
        fit_size.y = max_image_w / image_ratio
    else:
        fit_size.x = max_image_h * image_ratio
    fit_size.x = minf(fit_size.x, source_w)
    fit_size.y = minf(fit_size.y, source_h)
    fit_size.x = maxf(1.0, fit_size.x)
    fit_size.y = maxf(1.0, fit_size.y)
    scroll.custom_minimum_size = fit_size
    root.add_child(scroll)

    var canvas := Control.new()
    canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    scroll.add_child(canvas)

    var image_rect := TextureRect.new()
    image_rect.texture = texture
    image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(image_rect)

    var fit_w := fit_size.x
    var fit_h := fit_size.y
    var zoom_state := {"value": 1.0}

    var update_zoom := func():
        var zoom := clampf(float(zoom_state["value"]), 1.0, 5.0)
        zoom_state["value"] = zoom
        var target_size := Vector2(fit_w * zoom, fit_h * zoom)
        canvas.custom_minimum_size = target_size
        canvas.size = target_size
        image_rect.position = Vector2.ZERO
        image_rect.custom_minimum_size = target_size
        image_rect.size = target_size
        zoom_reset.text = "%d%%" % int(round(zoom * 100.0))
        zoom_out.disabled = zoom <= 1.01
        zoom_in.disabled = zoom >= 4.99

    zoom_out.pressed.connect(func():
        zoom_state["value"] = maxf(1.0, float(zoom_state["value"]) - 0.25)
        update_zoom.call()
    )
    zoom_in.pressed.connect(func():
        zoom_state["value"] = minf(5.0, float(zoom_state["value"]) + 0.25)
        update_zoom.call()
    )
    zoom_reset.pressed.connect(func():
        zoom_state["value"] = 1.0
        update_zoom.call()
        scroll.scroll_horizontal = 0
        scroll.scroll_vertical = 0
    )

    # Native two-finger pinch. ScrollContainer keeps one-finger panning, while
    # two active touch points change the real child size from 100% to 500%.
    var touch_points: Dictionary = {}
    var pinch_state := {"last_distance": 0.0}
    scroll.gui_input.connect(func(event: InputEvent):
        if event is InputEventScreenTouch:
            var touch := event as InputEventScreenTouch
            if touch.pressed:
                touch_points[touch.index] = touch.position
            else:
                touch_points.erase(touch.index)
            if touch_points.size() < 2:
                pinch_state["last_distance"] = 0.0
            else:
                var touch_keys := touch_points.keys()
                var first_point: Vector2 = touch_points[touch_keys[0]]
                var second_point: Vector2 = touch_points[touch_keys[1]]
                pinch_state["last_distance"] = first_point.distance_to(second_point)
                scroll.accept_event()
        elif event is InputEventScreenDrag:
            var drag := event as InputEventScreenDrag
            touch_points[drag.index] = drag.position
            if touch_points.size() >= 2:
                var drag_keys := touch_points.keys()
                var point_a: Vector2 = touch_points[drag_keys[0]]
                var point_b: Vector2 = touch_points[drag_keys[1]]
                var new_distance := point_a.distance_to(point_b)
                var old_distance := float(pinch_state["last_distance"])
                if old_distance > 8.0 and new_distance > 8.0:
                    zoom_state["value"] = clampf(float(zoom_state["value"]) * (new_distance / old_distance), 1.0, 5.0)
                    update_zoom.call()
                pinch_state["last_distance"] = new_distance
                scroll.accept_event()
    )

    update_zoom.call()
    _apply_touch_targets(popup)
    var popup_width := mini(int(fit_w) + 48, int(get_viewport_rect().size.x) - 24)
    var popup_height := int(fit_h) + 230
    popup.popup_centered(_mobile_dialog_size(Vector2i(maxi(240, popup_width), popup_height)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _manual_first_figure_block(entry: Dictionary) -> Dictionary:
    var blocks_value = entry.get("blocks", [])
    if not (blocks_value is Array):
        return {}
    for block_value in blocks_value:
        if block_value is Dictionary:
            var block: Dictionary = block_value
            if str(block.get("type", "")) == "figure_ref" and str(block.get("image", "")) != "":
                return block
    return {}

func _manual_clean_notice_text(value: String) -> String:
    var cleaned := value.strip_edges()
    cleaned = cleaned.replace(" ■", "\n• ")
    if cleaned.begins_with("■"):
        cleaned = "• " + cleaned.substr(1)
    cleaned = cleaned.replace("■", "\n• ")
    return cleaned.strip_edges()

func _add_manual_page_tail(container: VBoxContainer) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 18
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(spacer)

    var divider := HSeparator.new()
    divider.modulate = Color("17414a")
    divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(divider)

    var hint := Label.new()
    hint.text = "Свайп влево / вправо — следующая или предыдущая страница"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_font_size_override("font_size", 9)
    hint.add_theme_color_override("font_color", Color("66808b"))
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(hint)

    var final_space := Control.new()
    final_space.custom_minimum_size.y = 24
    final_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(final_space)


func _add_manual_notice(container: VBoxContainer, kind: String, title_text: String, body_text: String) -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var bg := Color("0b2029e8")
    var border := Color("1d5862")
    var accent := Color("55dfe4")
    if kind == "warning":
        bg = Color("291719e8")
        border = Color("c9585f")
        accent = Color("ff7d84")
    elif kind == "caution":
        bg = Color("2a2114e8")
        border = Color("b98b36")
        accent = Color("f0bb56")
    elif kind == "eco":
        bg = Color("10251fe8")
        border = Color("3e8d6d")
        accent = Color("69d6a2")
    panel.add_theme_stylebox_override("panel", _style_box(bg, 14, border, 1))
    container.add_child(panel)

    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 5)
    margin.add_child(box)

    var heading := Label.new()
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var fallback_title := "Примечание"
    if kind == "warning":
        fallback_title = "ВНИМАНИЕ"
    elif kind == "caution":
        fallback_title = "ОСТОРОЖНО"
    elif kind == "eco":
        fallback_title = "Окружающая среда"
    heading.text = title_text if title_text != "" else fallback_title
    heading.add_theme_font_size_override("font_size", 12)
    heading.add_theme_color_override("font_color", accent)
    box.add_child(heading)

    if body_text != "":
        var body := Label.new()
        body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        body.text = _manual_clean_notice_text(body_text)
        body.add_theme_font_size_override("font_size", 13)
        body.add_theme_color_override("font_color", Color("d6e4e8"))
        body.add_theme_constant_override("line_spacing", 4)
        body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        box.add_child(body)

func _build_overview() -> void:
    # Fixed dashboard: the complete home screen must fit without vertical scrolling.
    overview_box.add_theme_constant_override("separation", 8)

    var hero := Panel.new()
    hero.custom_minimum_size.y = 240
    hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.clip_contents = true
    hero.add_theme_stylebox_override("panel", _style_box(Color("08141c"), 22, Color("1b4a55"), 1, Color("00dfe826"), 3))
    overview_box.add_child(hero)

    var hero_image := TextureRect.new()
    hero_image.texture = load("res://assets/ui/hero_yeti.jpg")
    hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(hero_image)

    var shade := ColorRect.new()
    shade.color = Color("04101818")
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(shade)

    # Smooth dark fade keeps the lower text readable without flattening the photo.
    var lower_shade := TextureRect.new()
    lower_shade.texture = load("res://assets/ui/fade_bottom.png")
    lower_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    lower_shade.stretch_mode = TextureRect.STRETCH_SCALE
    lower_shade.anchor_left = 0.0
    lower_shade.anchor_right = 1.0
    lower_shade.anchor_top = 0.42
    lower_shade.anchor_bottom = 1.0
    lower_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(lower_shade)

    var hero_margin := MarginContainer.new()
    hero_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hero_margin.add_theme_constant_override("margin_left", 16)
    hero_margin.add_theme_constant_override("margin_right", 14)
    hero_margin.add_theme_constant_override("margin_top", 14)
    hero_margin.add_theme_constant_override("margin_bottom", 12)
    hero.add_child(hero_margin)
    var hero_column := VBoxContainer.new()
    hero_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero_margin.add_child(hero_column)
    var hero_spacer := Control.new()
    hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero_column.add_child(hero_spacer)

    var hero_title_row := HBoxContainer.new()
    hero_title_row.add_theme_constant_override("separation", 8)
    hero_column.add_child(hero_title_row)
    vehicle_name_label = Label.new()
    vehicle_name_label.add_theme_font_size_override("font_size", 24)
    vehicle_name_label.add_theme_color_override("font_color", Color("f7fbfd"))
    vehicle_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero_title_row.add_child(vehicle_name_label)
    var edit_btn := _mini_round_button("res://assets/ui/icons/edit.svg")
    edit_btn.pressed.connect(_open_vehicle_dialog)
    hero_title_row.add_child(edit_btn)

    var vin_row := HBoxContainer.new()
    hero_column.add_child(vin_row)
    vehicle_vin_label = Label.new()
    vehicle_vin_label.add_theme_font_size_override("font_size", 14)
    vehicle_vin_label.add_theme_color_override("font_color", Color("b7c9d2"))
    vehicle_vin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vin_row.add_child(vehicle_vin_label)
    var copy_btn := _mini_round_button("res://assets/ui/icons/copy.svg")
    copy_btn.tooltip_text = "Скопировать VIN"
    copy_btn.pressed.connect(func():
        var vehicle := VehicleService.vehicle()
        DisplayServer.clipboard_set(str(vehicle.get("vin", "")))
    )
    vin_row.add_child(copy_btn)

    var metric_row := HBoxContainer.new()
    metric_row.add_theme_constant_override("separation", 8)
    overview_box.add_child(metric_row)

    var mileage_metric := _metric_card("Пробег", "res://assets/ui/icons/gauge.svg", _open_mileage_dialog)
    (mileage_metric["card"] as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
    metric_row.add_child(mileage_metric["card"] as Node)
    mileage_value = mileage_metric["value"] as Label
    mileage_caption = mileage_metric["caption"] as Label

    var engine_metric := _metric_card("Двигатель", "res://assets/ui/icons/engine.svg", func(): _open_event_dialog("engine_replacement"))
    (engine_metric["card"] as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
    metric_row.add_child(engine_metric["card"] as Node)
    engine_value = engine_metric["value"] as Label
    engine_caption = engine_metric["caption"] as Label
    engine_value.add_theme_font_size_override("font_size", 15)

    fault_home_box = VBoxContainer.new()
    fault_home_box.add_theme_constant_override("separation", 7)
    overview_box.add_child(fault_home_box)

    var search_shell := Panel.new()
    search_shell.custom_minimum_size.y = 62
    search_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    search_shell.add_theme_stylebox_override("panel", _style_box(Color("063844e8"), 28, Color("12e6ea"), 2, Color("0de4e44f"), 5))
    overview_box.add_child(search_shell)
    var search_click := Button.new()
    search_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    search_click.focus_mode = Control.FOCUS_NONE
    search_click.add_theme_stylebox_override("normal", _style_box(Color("00000000"), 28))
    search_click.add_theme_stylebox_override("hover", _style_box(Color("074a542e"), 28, Color("5ffcff66"), 1))
    search_click.add_theme_stylebox_override("pressed", _style_box(Color("052d3655"), 28, Color("12e6eaaa"), 1))
    search_click.pressed.connect(_open_global_search)
    search_shell.add_child(search_click)
    var search_margin := MarginContainer.new()
    search_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    search_margin.add_theme_constant_override("margin_left", 16)
    search_margin.add_theme_constant_override("margin_right", 10)
    search_margin.add_theme_constant_override("margin_top", 8)
    search_margin.add_theme_constant_override("margin_bottom", 8)
    search_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    search_shell.add_child(search_margin)
    var search_row := HBoxContainer.new()
    search_row.add_theme_constant_override("separation", 12)
    search_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    search_margin.add_child(search_row)
    search_row.add_child(_centered_icon("res://assets/ui/icons/search.svg", 28, Color("1ff2f2")))
    var search_label := Label.new()
    search_label.text = "Найти деталь или проблему"
    search_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    search_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    search_label.add_theme_font_size_override("font_size", 17)
    search_label.add_theme_color_override("font_color", Color("dffeff"))
    search_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    search_row.add_child(search_label)
    var search_arrow_shell := PanelContainer.new()
    search_arrow_shell.custom_minimum_size = Vector2(42, 42)
    search_arrow_shell.add_theme_stylebox_override("panel", _style_box(Color("07343ed9"), 21, Color("15aeb8"), 1, Color("00e4e43a"), 4))
    search_arrow_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
    search_row.add_child(search_arrow_shell)
    search_arrow_shell.add_child(_centered_icon("res://assets/ui/icons/arrow_right.svg", 20, Color("efffff")))

    var service_card := _feature_card("Ближайшее обслуживание", "Добавь последнее обслуживание — и я помогу следить за сроками.", "res://assets/ui/service_oil.jpg", "res://assets/ui/icons/oil.svg", func(): _switch_to_page(maintenance_box))
    overview_box.add_child(service_card["card"] as Node)
    next_service_value = service_card["subtitle"] as Label

    var reminder_card := _feature_card("Напоминания", "Активных напоминаний нет", "res://assets/ui/reminders_brake.jpg", "res://assets/ui/icons/reminder.svg", _open_reminders_tab)
    overview_box.add_child(reminder_card["card"] as Node)
    reminders_summary_value = reminder_card["subtitle"] as Label

    var cost_card := _feature_card("Расходы", "0 руб.", "res://assets/ui/expenses_money.jpg", "res://assets/ui/icons/expenses.svg", func(): _switch_to_page(history_box))
    overview_box.add_child(cost_card["card"] as Node)
    total_cost_value = cost_card["subtitle"] as Label
    total_cost_value.add_theme_font_size_override("font_size", 18)
    total_cost_value.add_theme_color_override("font_color", Color("f5fbfd"))

    data_mode_value = Label.new()
    data_mode_value.visible = false
    overview_box.add_child(data_mode_value)
    recent_box = VBoxContainer.new()
    recent_box.visible = false
    overview_box.add_child(recent_box)

func _build_history_page() -> void:
    _page_heading(history_box, "История", "Все работы, пробег и расходы в одной ленте", "res://assets/ui/icons/history.svg")
    _page_banner(history_box, "res://assets/ui/expenses_money.jpg", "История автомобиля", "Работы, детали и затраты — без разрозненных записей")
    var bar := HBoxContainer.new()
    history_box.add_child(bar)
    var add := Button.new()
    add.text = "+ Новая запись"
    add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add.pressed.connect(func(): _open_event_dialog())
    bar.add_child(add)

func _build_maintenance_page() -> void:
    _page_heading(maintenance_box, "Обслуживание", "Что уже пора делать и что приближается", "res://assets/ui/icons/oil.svg")
    _page_banner(maintenance_box, "res://assets/ui/service_yeti.jpg", "План обслуживания", "Сроки по времени и реальному пробегу")
    var info := Label.new()
    info.text = "Сроки считаются от последних записей в истории. Интервалы ниже — настраиваемые ориентиры: сервисная книжка и техническая документация конкретной машины имеют приоритет. Если есть минимум две записи пробега, приложение также оценивает дату по твоему реальному темпу езды."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.modulate = Color("9ba6b2")
    maintenance_box.add_child(info)

func _build_reminders_page() -> void:
    _page_heading(reminders_box, "Напоминания", "Сроки, пробег и системные уведомления", "res://assets/ui/icons/reminder.svg")
    _page_banner(reminders_box, "res://assets/ui/reminders_brake.jpg", "Не пропусти важное", "Уведомления появляются только на основании истории машины")
    var info := Label.new()
    info.text = "Здесь появляются работы, срок которых приближается, наступил или уже просрочен. Центр напоминаний работает всегда; системные Android-уведомления доступны только в сборке, где подключён модуль Notification Scheduler."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.modulate = Color("9ba6b2")
    reminders_box.add_child(info)

    var system_card := _glass_card(reminders_box)
    var system_title := Label.new()
    system_title.text = "Системные уведомления Android"
    system_title.add_theme_font_size_override("font_size", 20)
    system_card.add_child(system_title)
    notification_status_value = Label.new()
    notification_status_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notification_status_value.modulate = Color("b7c1cb")
    system_card.add_child(notification_status_value)

    notification_controls_box = VBoxContainer.new()
    notification_controls_box.add_theme_constant_override("separation", 8)
    system_card.add_child(notification_controls_box)

    notification_enabled_toggle = CheckBox.new()
    notification_enabled_toggle.text = "Системные напоминания включены"
    notification_enabled_toggle.button_pressed = Notifications.notifications_enabled()
    notification_enabled_toggle.toggled.connect(func(value: bool): Notifications.set_notifications_enabled(value))
    notification_controls_box.add_child(notification_enabled_toggle)

    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    notification_controls_box.add_child(actions)
    var permission_btn := Button.new()
    permission_btn.text = "Разрешить уведомления"
    permission_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    permission_btn.pressed.connect(func(): Notifications.request_permission())
    actions.add_child(permission_btn)
    var sync_btn := Button.new()
    sync_btn.text = "Обновить план"
    sync_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sync_btn.pressed.connect(func(): Notifications.sync_maintenance(true))
    notification_controls_box.add_child(sync_btn)
    var settings_btn := Button.new()
    settings_btn.text = "Настройки уведомлений Android"
    settings_btn.pressed.connect(func(): Notifications.open_app_notification_settings())
    notification_controls_box.add_child(settings_btn)

    var reliability_btn := Button.new()
    reliability_btn.text = "Разрешения для надёжной доставки"
    reliability_btn.pressed.connect(func(): Notifications.request_reliable_delivery())
    notification_controls_box.add_child(reliability_btn)

    reminders_dynamic_box = VBoxContainer.new()
    reminders_dynamic_box.add_theme_constant_override("separation", 12)
    reminders_box.add_child(reminders_dynamic_box)

func _build_diagnostics_page() -> void:
    _page_heading(diagnostics_box, "Диагностика", "Лампа, код ошибки или симптом", "res://assets/ui/icons/diagnostic.svg")
    var intro := Label.new()
    intro.text = "Выберите, с чего начать проверку. Результат не назначает неисправную деталь без подтверждения."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.modulate = Color("9ba6b2")
    diagnostics_box.add_child(intro)

    diagnostic_content = VBoxContainer.new()
    diagnostic_content.add_theme_constant_override("separation", 10)
    diagnostics_box.add_child(diagnostic_content)
    _show_diagnostic_scenarios()

func _show_diagnostic_scenarios() -> void:
    if diagnostic_content == null:
        return
    _clear_children(diagnostic_content)
    diagnostic_flow_id = ""
    diagnostic_node_id = ""
    diagnostic_context_part_name = ""
    diagnostic_history.clear()
    active_saved_fault_id = ""

    var title := Label.new()
    title.text = "С чего начнём?"
    title.add_theme_font_size_override("font_size", 21)
    diagnostic_content.add_child(title)

    _diagnostic_entry_card("Лампа на панели", "На приборке что-то загорелось", func(): _show_warning_lights())
    _diagnostic_entry_card("Код ошибки", "Есть Pxxxx / код сканера", func(): _show_dtc_lookup())

    _diagnostic_entry_card("По симптомам", "Что происходит с машиной?", func(): _show_symptom_scenarios())

    var saved_rows: Array = Storage.data.get("saved_faults", [])
    if not saved_rows.is_empty():
        _diagnostic_entry_card("Сохранённые неисправности · %d" % saved_rows.size(), "Записи, добавленные вручную", func(): _show_saved_faults())

func _show_saved_faults() -> void:
    _clear_children(diagnostic_content)
    _diagnostic_back_button()
    var heading := Label.new()
    heading.text = "Сохранённые неисправности"
    heading.add_theme_font_size_override("font_size", 21)
    diagnostic_content.add_child(heading)
    var rows: Array = Storage.data.get("saved_faults", [])
    if rows.is_empty():
        _fault_text_block(diagnostic_content, "Записей пока нет", "Сохраните лампу или код из карточки диагностики. Запись добавляется вручную.")
    for value in rows:
        var row: Dictionary = value
        var card := _glass_card(diagnostic_content)
        var warning := FaultCatalog.warning(str(row.get("warning_id", "")))
        if warning.is_empty() and str(row.get("dtc_code", "")) != "":
            var code := FaultCatalog.dtc(str(row.get("dtc_code", "")))
            warning = FaultCatalog.warning(str(code.get("dashboard_warning_id", "")))
        if not warning.is_empty():
            var image := TextureRect.new()
            image.texture = load(str(warning.get("image", ""))) as Texture2D
            image.custom_minimum_size = Vector2(40, 40)
            image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            card.add_child(image)
        var title := Label.new()
        title.text = (str(row.get("dtc_code", "")) + " · " if str(row.get("dtc_code", "")) != "" else "") + str(row.get("title", "Сохранённая неисправность"))
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.add_child(title)
        var status := Label.new()
        status.text = str(row.get("date", "")) + " · " + str({"NEW":"Новая", "CHECKING":"Проверяется", "RESOLVED":"Решена"}.get(str(row.get("status", "NEW")), "Новая"))
        status.modulate = Color("9ba6b2")
        card.add_child(status)
        if str(row.get("note", "")) != "":
            var note := Label.new()
            note.text = str(row.get("note", ""))
            note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            card.add_child(note)
        var open := Button.new()
        open.text = "Открыть запись"
        open.custom_minimum_size.y = 48
        open.pressed.connect(_open_saved_fault.bind(row))
        card.add_child(open)
    _apply_touch_targets(diagnostic_content)

func _show_symptom_scenarios() -> void:
    _clear_children(diagnostic_content)
    _diagnostic_back_button()
    var symptoms_title := Label.new()
    symptoms_title.text = "Выберите симптом"
    symptoms_title.add_theme_font_size_override("font_size", 21)
    diagnostic_content.add_child(symptoms_title)

    for scenario_value in DiagnosticService.scenarios():
        var scenario: Dictionary = scenario_value
        var card := _glass_card(diagnostic_content)
        var button := Button.new()
        button.text = str(scenario.get("title", "Сценарий"))
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.y = 48
        button.pressed.connect(_start_diagnostic.bind(str(scenario.get("id", ""))))
        card.add_child(button)
        var subtitle := Label.new()
        subtitle.text = str(scenario.get("subtitle", ""))
        subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        subtitle.modulate = Color("8793a1")
        subtitle.add_theme_font_size_override("font_size", 11)
        card.add_child(subtitle)

func _diagnostic_entry_card(title_text: String, subtitle_text: String, action: Callable) -> void:
    var card := _glass_card(diagnostic_content)
    var button := Button.new()
    button.text = title_text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size.y = 48
    button.pressed.connect(action)
    card.add_child(button)
    var subtitle := Label.new()
    subtitle.text = subtitle_text
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.modulate = Color("8793a1")
    subtitle.add_theme_font_size_override("font_size", 11)
    card.add_child(subtitle)

func _diagnostic_back_button() -> void:
    var back := Button.new()
    back.text = "← Диагностика"
    back.custom_minimum_size.y = 48
    back.pressed.connect(_show_diagnostic_scenarios)
    diagnostic_content.add_child(back)

func _show_warning_lights() -> void:
    _clear_children(diagnostic_content)
    _diagnostic_back_button()
    var heading := Label.new()
    heading.text = "Лампы на панели"
    heading.add_theme_font_size_override("font_size", 21)
    diagnostic_content.add_child(heading)
    for value in FaultCatalog.warnings():
        var row: Dictionary = value
        var card := _glass_card(diagnostic_content)
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation", 12)
        card.add_child(line)
        var image := TextureRect.new()
        image.texture = load(str(row.get("image", ""))) as Texture2D
        image.custom_minimum_size = Vector2(48, 48)
        image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        line.add_child(image)
        var copy := VBoxContainer.new()
        copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(copy)
        var title := Label.new()
        title.text = str(row.get("title", "Предупреждение"))
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        copy.add_child(title)
        var summary := Label.new()
        summary.text = str(row.get("summary", ""))
        summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        summary.add_theme_font_size_override("font_size", 12)
        summary.modulate = Color("9ba6b2")
        copy.add_child(summary)
        var open := Button.new()
        open.text = "Открыть"
        open.custom_minimum_size.y = 48
        open.pressed.connect(_show_warning_detail.bind(str(row.get("id", ""))))
        card.add_child(open)

func _show_warning_detail(warning_id: String, saved_id: String = "") -> void:
    active_saved_fault_id = saved_id
    var row := FaultCatalog.warning(warning_id)
    if row.is_empty(): return
    _clear_children(diagnostic_content)
    _diagnostic_back_button()
    var panel := _glass_card(diagnostic_content)
    panel.add_theme_constant_override("separation", 10)
    var symbol := TextureRect.new()
    symbol.texture = load(str(row.get("image", ""))) as Texture2D
    symbol.custom_minimum_size = Vector2(104, 104)
    symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    panel.add_child(symbol)
    var caption := Label.new()
    caption.text = "Как выглядит на приборной панели"
    caption.add_theme_font_size_override("font_size", 13)
    caption.modulate = Color("9ba6b2")
    panel.add_child(caption)
    var title := Label.new()
    title.text = str(row.get("title", ""))
    title.add_theme_font_size_override("font_size", 22)
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(title)
    var severity := Label.new()
    var severity_text := {"STOP":"Остановитесь", "URGENT_CHECK":"Требуется срочная проверка", "CHECK_SOON":"Требуется проверка", "INFORMATION":"Информация"}.get(str(row.get("severity", "")), "Требуется проверка")
    severity.text = severity_text
    severity.add_theme_color_override("font_color", Color(str(row.get("symbol_color", "#f2b84b"))))
    severity.add_theme_font_size_override("font_size", 17)
    panel.add_child(severity)
    if warning_id == "check_engine":
        _fault_text_block(panel, "Если лампа мигает", "Срочность выше: снизьте нагрузку. При сильной тряске или потере мощности безопасно остановитесь и выключите двигатель.")
    if bool(row.get("stop_driving", false)):
        var stop := Label.new()
        stop.text = str(row.get("summary", "Остановитесь и выключите двигатель."))
        stop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        stop.add_theme_font_size_override("font_size", 19)
        stop.add_theme_color_override("font_color", Color("ff7777"))
        panel.add_child(stop)
    _fault_text_block(panel, "Что означает", str(row.get("meaning", "")))
    _fault_text_block(panel, "Что делать сейчас", str(row.get("what_to_do", "")))
    _fault_text_list(panel, "Возможные причины", row.get("possible_causes", []))
    _fault_text_list(panel, "Что проверить", row.get("first_checks", []))
    _fault_text_list(panel, "Возможные решения", row.get("possible_solutions", []))
    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    diagnostic_content.add_child(actions)
    var flow := str(row.get("related_diagnostic_flow", ""))
    if flow != "":
        var check := Button.new()
        check.text = "Начать диагностику"
        check.custom_minimum_size.y = 50
        check.pressed.connect(_start_diagnostic.bind(flow, str(row.get("title", ""))))
        actions.add_child(check)
    var nodes: Array = row.get("related_node_ids", [])
    if not nodes.is_empty():
        var diagram := Button.new()
        diagram.text = "Показать на схеме"
        diagram.custom_minimum_size.y = 50
        diagram.pressed.connect(_open_fault_node.bind(str(nodes[0])))
        actions.add_child(diagram)
    var source: Dictionary = row.get("source", {})
    _fault_text_block(diagnostic_content, "Источник", "%s · стр. %s руководства владельца" % [str(source.get("title", "")), str(source.get("manual_page", ""))])
    _add_save_fault_action(diagnostic_content, warning_id, "", str(row.get("title", "Предупреждение")))
    _add_saved_fault_status(diagnostic_content)

func _show_dtc_lookup(saved_id: String = "") -> void:
    active_saved_fault_id = saved_id
    _clear_children(diagnostic_content)
    _diagnostic_back_button()
    var heading := Label.new()
    heading.text = "Код ошибки"
    heading.add_theme_font_size_override("font_size", 21)
    diagnostic_content.add_child(heading)
    var field := LineEdit.new()
    field.placeholder_text = "P189C, 006300, P130A или P0301"
    field.custom_minimum_size.y = 50
    diagnostic_content.add_child(field)
    var result_box := VBoxContainer.new()
    result_box.add_theme_constant_override("separation", 9)
    diagnostic_content.add_child(result_box)
    var lookup := func():
        field.release_focus()
        DisplayServer.virtual_keyboard_hide()
        _show_dtc_detail(FaultCatalog.normalize_code(field.text), result_box)
    field.text_submitted.connect(func(_text: String): lookup.call())
    var button := Button.new()
    button.text = "Найти код"
    button.custom_minimum_size.y = 48
    button.pressed.connect(lookup)
    diagnostic_content.add_child(button)
    field.grab_focus()

func _show_dtc_detail(code: String, target: VBoxContainer) -> void:
    _clear_children(target)
    var row := FaultCatalog.dtc(code)
    if row.is_empty():
        if not FaultCatalog.valid_lookup_code(code):
            _fault_text_block(target, "Формат кода", "Введите Pxxxx, Uxxxx, Cxxxx, Bxxxx или 5–6-значный код VAG из сканера.")
        else:
            _fault_text_block(target, "Код отсутствует", "Код пока отсутствует в локальной базе Yeti Garage. Сохраните полный код, название блока и текст сканера. Не придумываем трактовку неизвестной ошибки.")
        return
    var badge := Label.new()
    badge.text = str(row.get("code", "")) + " · " + str(row.get("title_ru", ""))
    badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    badge.add_theme_font_size_override("font_size", 19)
    target.add_child(badge)
    var warning := FaultCatalog.warning(str(row.get("dashboard_warning_id", "")))
    if not warning.is_empty():
        var image := TextureRect.new()
        image.texture = load(str(warning.get("image", ""))) as Texture2D
        image.custom_minimum_size = Vector2(72, 72)
        image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        target.add_child(image)
    var severity_note := "Сохраните код и проверьте систему до продолжения обычной эксплуатации."
    match str(row.get("severity", "CHECK_SOON")):
        "STOP":
            severity_note = "Если горит красная лампа давления масла или есть признаки потери давления, безопасно остановитесь и заглушите двигатель. Не продолжайте движение до проверки."
        "URGENT_CHECK":
            severity_note = "Нужна срочная диагностика. При сильной тряске двигателя, мигании Check Engine, исчезновении тяги или неконтролируемом переключении передач безопасно остановитесь."
        "INFORMATION":
            severity_note = "Сохраните код и проверьте обстоятельства его появления."
    _fault_text_block(target, "Срочность", severity_note)
    _fault_text_block(target, "Что означает", str(row.get("description", "")))
    _fault_text_list(target, "Что водитель может заметить", row.get("driver_symptoms", []))
    _fault_text_list(target, "Возможные причины", row.get("possible_causes", []))
    _fault_text_list(target, "Что проверить сначала", row.get("first_checks", []))
    _fault_text_list(target, "Возможные решения", row.get("possible_solutions", []))
    var actions := VBoxContainer.new()
    target.add_child(actions)
    var flow := str(row.get("related_diagnostic_flow", ""))
    if flow != "":
        var check := Button.new()
        check.text = "Начать диагностику"
        check.custom_minimum_size.y = 48
        check.pressed.connect(_start_diagnostic.bind(flow, code))
        actions.add_child(check)
    var nodes: Array = row.get("related_node_ids", [])
    if not nodes.is_empty():
        var diagram := Button.new()
        diagram.text = "Показать на схеме"
        diagram.custom_minimum_size.y = 48
        diagram.pressed.connect(_open_fault_node.bind(str(nodes[0])))
        actions.add_child(diagram)
    var code_kind := "GENERIC OBD-II · общее описание SAE J2012."
    if str(row.get("verification_status", "")) == "VAG_SPECIFIC":
        code_kind = "VAG_SPECIFIC · Код VAG · проверенная трактовка семейства VAG, не гарантия появления на конкретном ЭБУ."
    elif str(row.get("verification_status", "")) == "REFERENCE_ONLY":
        code_kind = "Справочное описание · проверьте по номеру блока управления."
    _fault_text_block(target, "Тип кода", code_kind)
    var aliases: Array = row.get("vag_codes", [])
    if not aliases.is_empty():
        _fault_text_block(target, "Другие номера сканера", " / ".join(aliases))
    _fault_text_block(target, "Для какого автомобиля", str(row.get("applicability", "Требуется сверка с автомобилем и блоком управления.")))
    var code_source: Dictionary = row.get("source", {})
    if not code_source.is_empty():
        _fault_text_block(target, "Источник", str(code_source.get("title", "")) + "\n" + str(code_source.get("url", "")))
    _add_save_fault_action(target, "", str(row.get("code", code)), str(row.get("title_ru", "Код ошибки")))
    _add_saved_fault_status(target)

func _fault_text_block(parent: Control, heading_text: String, body_text: String) -> void:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    parent.add_child(box)
    var heading := Label.new()
    heading.text = heading_text
    heading.add_theme_font_size_override("font_size", 16)
    box.add_child(heading)
    var body := Label.new()
    body.text = body_text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.modulate = Color("aab8c1")
    box.add_child(body)

func _fault_text_list(parent: Control, heading_text: String, values: Array) -> void:
    var body := "\n".join(values.map(func(value): return "• " + str(value)))
    _fault_text_block(parent, heading_text, body)

func _open_fault_node(node_id: String) -> void:
    if mobile_technical_catalog and vehicle_3d_view != null and vehicle_3d_view.has_method("focus_node"):
        _switch_to_page(vehicle_3d_box)
        vehicle_3d_view.focus_node(node_id)
    else:
        _show_info_dialog("Технический справочник", "Связанная схема: %s" % node_id)

func _save_fault(warning_id: String, dtc_code: String, title_text: String, note_text: String = "") -> void:
    var rows: Array = Storage.data.get("saved_faults", [])
    var id := "fault_%s" % str(Time.get_unix_time_from_system())
    rows.push_front({"id":id, "date":Time.get_date_string_from_system(), "warning_id":warning_id, "dtc_code":dtc_code, "title":title_text, "note":note_text, "status":"NEW"})
    Storage.data["saved_faults"] = rows
    Storage.save()
    active_saved_fault_id = id
    _refresh_saved_fault_card()
    _show_info_dialog("Сохранённая неисправность", "Запись сохранена вручную. Приложение не считывало данные автомобиля.")

func _add_save_fault_action(parent: Control, warning_id: String, code: String, title_text: String) -> void:
    var note := LineEdit.new()
    note.placeholder_text = "Заметка (необязательно)"
    note.custom_minimum_size.y = 48
    parent.add_child(note)
    var save := Button.new()
    save.text = "Сохранить неисправность"
    save.custom_minimum_size.y = 48
    save.pressed.connect(func(): _save_fault(warning_id, code, title_text, note.text.strip_edges()))
    parent.add_child(save)

func _add_saved_fault_status(parent: Control) -> void:
    if active_saved_fault_id == "": return
    var selector := OptionButton.new()
    selector.custom_minimum_size.y = 48
    selector.add_item("Новая", 0)
    selector.add_item("Проверяется", 1)
    selector.add_item("Решена", 2)
    var rows: Array = Storage.data.get("saved_faults", [])
    for i in range(rows.size()):
        var row: Dictionary = rows[i]
        if str(row.get("id", "")) == active_saved_fault_id:
            selector.select({"NEW":0, "CHECKING":1, "RESOLVED":2}.get(str(row.get("status", "NEW")), 0))
            break
    selector.item_selected.connect(func(index: int): _update_saved_fault_status(active_saved_fault_id, ["NEW", "CHECKING", "RESOLVED"][index]))
    parent.add_child(selector)

func _update_saved_fault_status(fault_id: String, status: String) -> void:
    var rows: Array = Storage.data.get("saved_faults", [])
    for i in range(rows.size()):
        var row: Dictionary = rows[i]
        if str(row.get("id", "")) == fault_id:
            row["status"] = status
            rows[i] = row
            break
    Storage.data["saved_faults"] = rows
    Storage.save()
    _refresh_saved_fault_card()

func _refresh_saved_fault_card() -> void:
    if fault_home_box == null: return
    _clear_children(fault_home_box)
    var rows: Array = Storage.data.get("saved_faults", [])
    for value in rows:
        var row: Dictionary = value
        if str(row.get("status", "NEW")) == "RESOLVED": continue
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _style_box(Color("0b1e27"), 16, Color("6b4c36"), 1))
        fault_home_box.add_child(card)
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation", 10)
        card.add_child(line)
        var warning := FaultCatalog.warning(str(row.get("warning_id", "")))
        if not warning.is_empty():
            var icon := TextureRect.new()
            icon.texture = load(str(warning.get("image", ""))) as Texture2D
            icon.custom_minimum_size = Vector2(38, 38)
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            line.add_child(icon)
        var copy := VBoxContainer.new()
        copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(copy)
        var heading := Label.new()
        heading.text = "Требует внимания"
        heading.add_theme_font_size_override("font_size", 12)
        heading.modulate = Color("f2b84b")
        copy.add_child(heading)
        var title := Label.new()
        title.text = (str(row.get("dtc_code", "")) + " · " if str(row.get("dtc_code", "")) != "" else "") + str(row.get("title", "Сохранённая неисправность"))
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        copy.add_child(title)
        var open := Button.new()
        open.text = "Открыть"
        open.custom_minimum_size.y = 48
        open.pressed.connect(_open_saved_fault.bind(row))
        line.add_child(open)
        break

func _open_saved_fault(row: Dictionary) -> void:
    active_saved_fault_id = str(row.get("id", ""))
    _switch_to_page(diagnostics_box)
    var warning_id := str(row.get("warning_id", ""))
    var code := str(row.get("dtc_code", ""))
    if warning_id != "":
        _show_warning_detail(warning_id, active_saved_fault_id)
    elif code != "":
        _show_dtc_lookup(active_saved_fault_id)
        await get_tree().process_frame
        for child in diagnostic_content.get_children():
            if child is VBoxContainer and child != diagnostic_content:
                _show_dtc_detail(code, child as VBoxContainer)

func _start_diagnostic(flow_id: String, context_part_name: String = "") -> void:
    var flow: Dictionary = DiagnosticService.flow(flow_id)
    if flow.is_empty():
        return
    diagnostic_flow_id = flow_id
    diagnostic_context_part_name = context_part_name
    diagnostic_node_id = str(flow.get("start", ""))
    diagnostic_history.clear()
    _render_diagnostic_node()

func _render_diagnostic_node() -> void:
    _clear_children(diagnostic_content)
    var flow: Dictionary = DiagnosticService.flow(diagnostic_flow_id)
    var nodes: Dictionary = flow.get("nodes", {})
    if diagnostic_node_id == "" or not nodes.has(diagnostic_node_id):
        _show_diagnostic_scenarios()
        return
    var node: Dictionary = nodes[diagnostic_node_id]

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 8)
    diagnostic_content.add_child(top_row)
    var home_btn := Button.new()
    home_btn.text = "← Сценарии"
    home_btn.pressed.connect(_show_diagnostic_scenarios)
    top_row.add_child(home_btn)
    if not diagnostic_history.is_empty():
        var back_btn := Button.new()
        back_btn.text = "Назад"
        back_btn.pressed.connect(_diagnostic_back)
        top_row.add_child(back_btn)

    var flow_title := Label.new()
    flow_title.text = str(flow.get("title", "Диагностика"))
    flow_title.add_theme_font_size_override("font_size", 20)
    diagnostic_content.add_child(flow_title)
    if diagnostic_context_part_name != "":
        var context := Label.new()
        context.text = "Связанная деталь: «%s». Это возможная причина для проверки, не диагноз." % diagnostic_context_part_name
        context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        context.modulate = Color("71ddb6")
        diagnostic_content.add_child(context)

    var question := Label.new()
    question.text = str(node.get("question", ""))
    question.add_theme_font_size_override("font_size", 22)
    question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    diagnostic_content.add_child(question)

    var hint_text: String = str(node.get("hint", ""))
    if hint_text != "":
        var hint := Label.new()
        hint.text = "Внимание: " + hint_text
        hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        hint.modulate = Color("f3c86a")
        diagnostic_content.add_child(hint)

    var options: Array = node.get("options", [])
    for option_value in options:
        var option: Dictionary = option_value
        var button := Button.new()
        button.text = str(option.get("text", "Ответ"))
        button.custom_minimum_size.y = 48
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_choose_diagnostic_option.bind(option))
        diagnostic_content.add_child(button)

func _choose_diagnostic_option(option: Dictionary) -> void:
    var result_text: String = str(option.get("result", ""))
    if result_text != "":
        _show_diagnostic_result(result_text)
        return
    var next_id: String = str(option.get("next", ""))
    if next_id == "":
        return
    diagnostic_history.append(diagnostic_node_id)
    diagnostic_node_id = next_id
    _render_diagnostic_node()

func _diagnostic_back() -> void:
    if diagnostic_history.is_empty():
        _show_diagnostic_scenarios()
        return
    diagnostic_node_id = diagnostic_history.pop_back()
    _render_diagnostic_node()

func _show_diagnostic_result(result_text: String) -> void:
    _clear_children(diagnostic_content)
    var flow: Dictionary = DiagnosticService.flow(diagnostic_flow_id)

    var title := Label.new()
    title.text = "Результат проверки"
    title.add_theme_font_size_override("font_size", 22)
    diagnostic_content.add_child(title)

    var flow_title := Label.new()
    flow_title.text = str(flow.get("title", "Диагностика"))
    flow_title.modulate = Color("9ba6b2")
    diagnostic_content.add_child(flow_title)
    if diagnostic_context_part_name != "":
        var context := Label.new()
        context.text = "Проверяемая деталь из технического справочника: %s" % diagnostic_context_part_name
        context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        context.modulate = Color("71ddb6")
        diagnostic_content.add_child(context)

    var result := Label.new()
    result.text = result_text
    result.add_theme_font_size_override("font_size", 19)
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    diagnostic_content.add_child(result)

    var note := Label.new()
    note.text = "Это не автоматический приговор детали. Мы фиксируем только то, что подтверждается ответами и проверками."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.modulate = Color("8793a1")
    diagnostic_content.add_child(note)

    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    diagnostic_content.add_child(actions)

    var restart := Button.new()
    restart.text = "Начать заново"
    restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart.pressed.connect(_show_diagnostic_scenarios)
    actions.add_child(restart)

    var save_btn := Button.new()
    save_btn.text = "Записать в историю"
    save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    save_btn.pressed.connect(_save_diagnostic_result.bind(str(flow.get("title", "Диагностика")), result_text))
    actions.add_child(save_btn)

func _save_diagnostic_result(title_text: String, result_text: String) -> void:
    ServiceHistoryService.add_event({
        "type":"diagnostic",
        "title":"Диагностика: %s" % title_text,
        "date":Time.get_date_string_from_system(),
        "date_unknown":false,
        "mileage":MileageService.current_mileage(),
        "mileage_unknown":MileageService.current_mileage() <= 0,
        "cost":0.0,
        "labor_cost":0.0,
        "notes":result_text
    })

func _build_3d_page() -> void:
    if mobile_technical_catalog:
        vehicle_3d_view = MobileTechnicalCatalogView.new()
        vehicle_3d_view.set_vehicle_profile(VehicleService.vehicle())
    else:
        var desktop_view_script: Script = load("res://scenes/vehicle_3d/vehicle_3d_view.gd")
        vehicle_3d_view = desktop_view_script.new()
        vehicle_3d_view.set_vehicle_profile(VehicleService.vehicle())
    vehicle_3d_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vehicle_3d_view.set_history_provider(Callable(self, "_part_history_summary_for_3d"))
    vehicle_3d_view.replacement_requested.connect(_open_part_replacement)
    vehicle_3d_view.history_requested.connect(_show_part_history)
    vehicle_3d_view.repair_requested.connect(_open_repair_for_part)
    vehicle_3d_view.diagnostic_requested.connect(_open_diagnostic_for_part)
    vehicle_3d_view.manual_requested.connect(_open_manual_for_part)
    if vehicle_3d_view.has_signal("diagnostic_flow_requested"):
        vehicle_3d_view.diagnostic_flow_requested.connect(_open_diagnostic_from_catalog)
    vehicle_3d_box.add_child(vehicle_3d_view)

func _open_diagnostic_from_catalog(flow_id: String, title: String) -> void:
    _switch_to_page(diagnostics_box)
    _start_diagnostic(flow_id, title)

func _open_technical_result_from_search(result: Dictionary, dialog: Window) -> void:
    dialog.hide()
    if mobile_technical_catalog and vehicle_3d_view != null and vehicle_3d_view.has_method("open_catalog_result"):
        vehicle_3d_view.open_catalog_result(result)
    else:
        var part_id := str(result.get("part_id", ""))
        if part_id != "" and vehicle_3d_view != null and vehicle_3d_view.has_method("focus_part"):
            vehicle_3d_view.focus_part(part_id)
    _switch_to_page(vehicle_3d_box)
    dialog.queue_free()

func _part_history_summary_for_3d(part_id: String) -> String:
    var events := ServiceHistoryService.events_for_part(part_id)
    if events.is_empty():
        return "По этой детали пока нет записей о замене."
    var latest: Dictionary = events[0]
    return "Последняя запись: %s • %s" % [_event_date_text(latest), _event_mileage_text(latest)]

func _open_diagnostic_for_part(part_id: String, part_name: String) -> void:
    var flow_id := PartCatalogService.diagnostic_flow_for_part(part_id)
    if flow_id == "":
        _show_info_dialog("Проверка детали", "Для «%s» отдельная проверенная диагностическая ветка пока не добавлена." % part_name)
        return
    _switch_to_page(diagnostics_box)
    _start_diagnostic(flow_id, part_name)


func _open_manual_for_part(part_id: String, part_name: String) -> void:
    var matches := ManualSearchService.search(part_name, 3)
    if matches.is_empty():
        var catalog := PartCatalogService.get_part(part_id)
        var group_name := str(catalog.get("group", ""))
        if group_name != "":
            matches = ManualSearchService.search(group_name, 3)
    if matches.is_empty():
        _show_info_dialog("Руководство ŠKODA Yeti", "Для «%s» в руководстве владельца не найдено прямого совпадения. Это нормально для деталей, которые описываются только в ремонтной документации." % part_name)
        return
    var first: Dictionary = matches[0]
    var page := int(first.get("page", 0))
    if page <= 0:
        _show_info_dialog("Руководство ŠKODA Yeti", "Для «%s» найден раздел без корректной страницы." % part_name)
        return
    _open_official_manual(page)

func _open_global_search() -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    popup.wrap_controls = false
    add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(370), 0)
    panel.clip_contents = true
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 9)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    root.add_child(title_row)
    var title := Label.new()
    title.text = "Поиск по Yeti Garage"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 20)
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    var field := LineEdit.new()
    field.placeholder_text = "Например: ШРУС, гул, тормоза…"
    field.custom_minimum_size.y = 50
    _style_line_edit(field)
    root.add_child(field)

    var hint := Label.new()
    hint.text = "Ищем среди деталей, диагностических сценариев и официального руководства ŠKODA Yeti."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_color_override("font_color", Color("8fa7b3"))
    hint.add_theme_font_size_override("font_size", 12)
    root.add_child(hint)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.scroll_deadzone = 8
    scroll.follow_focus = true
    scroll.set_meta("preserve_scroll_modes", true)
    root.add_child(scroll)
    var results := VBoxContainer.new()
    results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    results.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    results.add_theme_constant_override("separation", 8)
    scroll.add_child(results)

    # Let pointer events reach ScrollContainer from every result surface. Rows
    # remain visually identical; a short release opens a row, while a drag stays
    # with the native scroll gesture recognizer.
    var pointer_state := {"active": false, "dragged": false, "distance": 0.0, "last_activation_ms": -1000}
    var activate_result := func(position: Vector2):
        var now_ms := Time.get_ticks_msec()
        if now_ms - int(pointer_state["last_activation_ms"]) < 220:
            return
        pointer_state["last_activation_ms"] = now_ms
        _activate_global_search_result_at(results, position)
    scroll.gui_input.connect(func(event: InputEvent):
        if event is InputEventScreenTouch:
            var touch := event as InputEventScreenTouch
            if touch.pressed:
                pointer_state["active"] = true
                pointer_state["dragged"] = false
                pointer_state["distance"] = 0.0
            elif bool(pointer_state["active"]):
                var tap_position: Vector2 = touch.position
                if not bool(pointer_state["dragged"]):
                    activate_result.call(tap_position)
                pointer_state["active"] = false
        elif event is InputEventScreenDrag and bool(pointer_state["active"]):
            var drag := event as InputEventScreenDrag
            pointer_state["distance"] = float(pointer_state["distance"]) + drag.relative.length()
            if float(pointer_state["distance"]) >= 12.0:
                pointer_state["dragged"] = true
                field.release_focus()
        elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
            var mouse_button := event as InputEventMouseButton
            if mouse_button.pressed:
                pointer_state["active"] = true
                pointer_state["dragged"] = false
                pointer_state["distance"] = 0.0
            elif bool(pointer_state["active"]):
                if not bool(pointer_state["dragged"]):
                    activate_result.call(mouse_button.position)
                pointer_state["active"] = false
        elif event is InputEventMouseMotion and bool(pointer_state["active"]) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            var motion := event as InputEventMouseMotion
            pointer_state["distance"] = float(pointer_state["distance"]) + motion.relative.length()
            if float(pointer_state["distance"]) >= 12.0:
                pointer_state["dragged"] = true
                field.release_focus()
    )

    # Full manual search scans a few megabytes of local text. Debounce typing so
    # Android does not rescan the index on every key press.
    var search_timer := Timer.new()
    search_timer.one_shot = true
    search_timer.wait_time = 0.18
    popup.add_child(search_timer)
    var pending_query := {"value": ""}
    field.text_changed.connect(func(query: String):
        pending_query["value"] = query
        search_timer.start()
    )
    search_timer.timeout.connect(func():
        _render_global_search_results(results, str(pending_query.get("value", "")), popup)
        _set_search_results_mouse_ignored(results)
    )
    _render_global_search_results(results, "", popup)
    _apply_touch_targets(popup)
    _set_search_results_mouse_ignored(results)
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    var search_popup_size := _mobile_dialog_size(Vector2i(400, 700))
    popup.popup_centered_clamped(search_popup_size, 0.96)
    await get_tree().process_frame
    if is_instance_valid(popup) and is_instance_valid(panel):
        panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        panel.position = Vector2.ZERO
        panel.size = Vector2(popup.size)
    popup.popup_hide.connect(func(): popup.queue_free())
    field.grab_focus()

func _render_global_search_results(results: VBoxContainer, query: String, dialog: Window) -> void:
    _clear_children(results)
    var q := query.strip_edges().to_lower()
    if q == "":
        var label := Label.new()
        label.text = "Начни вводить название детали или симптом. Поиск также покажет подходящие страницы руководства ŠKODA Yeti."
        label.modulate = Color("9ba6b2")
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        results.add_child(label)
        return

    var part_matches := PartCatalogService.search(q).filter(func(part: Dictionary): return TechnicalCatalogService.is_compatible(part, VehicleService.vehicle()))
    var diagnostic_matches: Array = DiagnosticService.search(q)
    var manual_matches := ManualSearchService.search(q, 3)
    var catalog_matches := TechnicalCatalogService.search(q, VehicleService.vehicle())
    var fault_matches := FaultCatalog.search(q)

    var total_shown := 0
    var catalog_count := 0
    if mobile_technical_catalog:
        for catalog_value in catalog_matches:
            var catalog_row: Dictionary = catalog_value
            if str(catalog_row.get("kind", "")) not in ["system", "node"] or catalog_count >= 4:
                continue
            if catalog_count == 0:
                _add_search_section_label(results, "Системы и узлы")
            var catalog_button := Button.new()
            catalog_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
            catalog_button.text = "%s • %s" % [str(catalog_row.get("name", "Узел")), str(catalog_row.get("subtitle", "Каталог"))]
            catalog_button.custom_minimum_size.y = 48
            catalog_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _style_global_search_result_button(catalog_button)
            var catalog_action := _open_technical_result_from_search.bind(catalog_row, dialog)
            catalog_button.set_meta("search_action", catalog_action)
            catalog_button.pressed.connect(catalog_action)
            results.add_child(catalog_button)
            catalog_count += 1
            total_shown += 1

    if not fault_matches.is_empty():
        for fault_value in fault_matches:
            if total_shown >= 12: break
            var fault_row: Dictionary = fault_value
            if str(fault_row.get("kind", "")) == "warning":
                if catalog_count == 0:
                    _add_search_section_label(results, "Лампы")
                    catalog_count = -100
                var warning_button := Button.new()
                warning_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
                warning_button.text = "Лампа · " + str(fault_row.get("name", ""))
                warning_button.custom_minimum_size.y = 48
                warning_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                _style_global_search_result_button(warning_button)
                var warning_action := _open_warning_from_search.bind(str(fault_row.get("id", "")), dialog)
                warning_button.set_meta("search_action", warning_action)
                warning_button.pressed.connect(warning_action)
                results.add_child(warning_button)
                total_shown += 1
            elif str(fault_row.get("kind", "")) == "dtc":
                _add_search_section_label(results, "Коды ошибок")
                var dtc_button := Button.new()
                dtc_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
                dtc_button.text = "Код · " + str(fault_row.get("name", ""))
                dtc_button.custom_minimum_size.y = 48
                dtc_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                _style_global_search_result_button(dtc_button)
                var dtc_action := _open_dtc_from_search.bind(str(fault_row.get("id", "")), dialog)
                dtc_button.set_meta("search_action", dtc_action)
                dtc_button.pressed.connect(dtc_action)
                results.add_child(dtc_button)
                total_shown += 1
    elif FaultCatalog.valid_lookup_code(query):
        _add_search_section_label(results, "Код ошибки")
        var unknown_code := FaultCatalog.normalize_code(query)
        var unknown_button := Button.new()
        unknown_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        unknown_button.text = "Код · " + unknown_code
        unknown_button.custom_minimum_size.y = 48
        unknown_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _style_global_search_result_button(unknown_button)
        var unknown_action := _open_dtc_from_search.bind(unknown_code, dialog)
        unknown_button.set_meta("search_action", unknown_action)
        unknown_button.pressed.connect(unknown_action)
        results.add_child(unknown_button)
        total_shown += 1

    if not part_matches.is_empty():
        _add_search_section_label(results, "Детали")
        var part_count := 0
        for row_value in part_matches:
            if part_count >= 4:
                break
            var row: Dictionary = row_value
            var button := Button.new()
            button.mouse_filter = Control.MOUSE_FILTER_IGNORE
            button.text = "%s • %s" % [str(row.get("name", "Деталь")), str(row.get("group", ""))]
            button.custom_minimum_size.y = 48
            button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _style_global_search_result_button(button)
            var action := _open_part_from_search.bind(str(row.get("id", "")), dialog)
            button.set_meta("search_action", action)
            button.pressed.connect(action)
            results.add_child(button)
            part_count += 1
            total_shown += 1

    if not diagnostic_matches.is_empty():
        _add_search_section_label(results, "Диагностика")
        var diag_count := 0
        for scenario_value in diagnostic_matches:
            if diag_count >= 3:
                break
            var diag_row: Dictionary = scenario_value
            var diag_btn := Button.new()
            diag_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
            diag_btn.text = str(diag_row.get("title", "Диагностика"))
            diag_btn.custom_minimum_size.y = 48
            diag_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _style_global_search_result_button(diag_btn)
            var diagnostic_action := _open_diagnostic_from_search.bind(str(diag_row.get("id", "")), dialog)
            diag_btn.set_meta("search_action", diagnostic_action)
            diag_btn.pressed.connect(diagnostic_action)
            results.add_child(diag_btn)
            diag_count += 1
            total_shown += 1

    if not manual_matches.is_empty():
        _add_search_section_label(results, "Официальное руководство")
        for manual_value in manual_matches:
            var manual_row: Dictionary = manual_value
            _add_manual_search_result(results, manual_row, dialog)
            total_shown += 1

    if total_shown == 0:
        var empty := Label.new()
        empty.text = "Пока ничего не нашла. Попробуй более простое слово: «гул», «тормоза», «антифриз», «масло», «предохранители»."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.modulate = Color("9ba6b2")
        results.add_child(empty)

func _style_global_search_result_button(button: Button) -> void:
    # Search rows remain one line and trim at word boundaries so a long result
    # cannot widen the popup or wrap into a narrow vertical strip on mobile.
    GlobalSearchLayout.style_result_button(button)

func _add_search_section_label(results: VBoxContainer, text_value: String) -> void:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.text = text_value
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color("67dce0"))
    label.add_theme_constant_override("outline_size", 2)
    label.add_theme_color_override("font_outline_color", Color("04141a"))
    results.add_child(label)

func _add_manual_search_result(results: VBoxContainer, row: Dictionary, dialog: Window) -> void:
    var page := int(row.get("page", 1))
    var card := Panel.new()
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.custom_minimum_size.y = 126
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel", _style_box(Color("071d27ed"), 16, Color("1d5862"), 1, Color("00dfe81a"), 2))
    results.add_child(card)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(box)

    var source := Label.new()
    source.text = "Руководство ŠKODA Yeti • %s" % _manual_page_reference(row, page)
    source.add_theme_font_size_override("font_size", 11)
    source.add_theme_color_override("font_color", Color("4ee8eb"))
    source.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(source)

    var title := Label.new()
    title.text = str(row.get("title", row.get("chapter", "Руководство")))
    title.add_theme_font_size_override("font_size", 14)
    title.add_theme_color_override("font_color", Color("e8f6f7"))
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.max_lines_visible = 2
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(title)

    var quote := Label.new()
    quote.text = "«%s»" % str(row.get("snippet", ""))
    quote.add_theme_font_size_override("font_size", 11)
    quote.add_theme_color_override("font_color", Color("9fb2bb"))
    quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quote.max_lines_visible = 3
    quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(quote)

    var figure_block := _manual_first_figure_block(row)
    if not figure_block.is_empty():
        var preview_path := str(figure_block.get("image", ""))
        if ResourceLoader.exists(preview_path):
            var preview_texture := load(preview_path) as Texture2D
            if preview_texture != null:
                card.custom_minimum_size.y = 228
                var preview := TextureRect.new()
                preview.texture = preview_texture
                preview.custom_minimum_size = Vector2(0, 88)
                preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
                box.add_child(preview)
                var figure_hint := Label.new()
                figure_hint.text = "На странице есть схема / иллюстрация"
                figure_hint.add_theme_font_size_override("font_size", 10)
                figure_hint.add_theme_color_override("font_color", Color("6fcbd0"))
                figure_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
                box.add_child(figure_hint)

    var click := Button.new()
    click.mouse_filter = Control.MOUSE_FILTER_IGNORE
    click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    click.focus_mode = Control.FOCUS_NONE
    click.add_theme_stylebox_override("normal", _style_box(Color("00000000"), 16))
    click.add_theme_stylebox_override("hover", _style_box(Color("0a657024"), 16, Color("4beef044"), 1))
    click.add_theme_stylebox_override("pressed", _style_box(Color("0b596238"), 16, Color("4beef077"), 1))
    var manual_action := _open_manual_page_from_search.bind(page, dialog)
    card.set_meta("search_action", manual_action)
    click.pressed.connect(manual_action)
    card.add_child(click)

func _activate_global_search_result_at(results: VBoxContainer, position: Vector2) -> void:
    for child_value in results.get_children():
        if not (child_value is Control):
            continue
        var row := child_value as Control
        if not row.has_meta("search_action") or not row.get_global_rect().has_point(position):
            continue
        var action: Callable = row.get_meta("search_action")
        if action.is_valid():
            action.call()
        return

func _set_search_results_mouse_ignored(node: Node) -> void:
    if node is Control:
        (node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
    for child in node.get_children():
        _set_search_results_mouse_ignored(child)

func _open_manual_page_from_search(page: int, dialog: Window) -> void:
    dialog.hide()
    _open_official_manual(page)

func _open_part_from_search(part_id: String, dialog: Window) -> void:
    dialog.hide()
    if vehicle_3d_view != null and vehicle_3d_view.has_method("focus_part"):
        vehicle_3d_view.focus_part(part_id)
    _switch_to_page(vehicle_3d_box)
    dialog.queue_free()

func _open_diagnostic_from_search(flow_id: String, dialog: Window) -> void:
    dialog.hide()
    _switch_to_page(diagnostics_box)
    _start_diagnostic(flow_id)
    dialog.queue_free()

func _open_warning_from_search(warning_id: String, dialog: Window) -> void:
    dialog.hide()
    _switch_to_page(diagnostics_box)
    _show_warning_detail(warning_id)
    dialog.queue_free()

func _open_dtc_from_search(code: String, dialog: Window) -> void:
    dialog.hide()
    _switch_to_page(diagnostics_box)
    _show_dtc_lookup()
    await get_tree().process_frame
    for child in diagnostic_content.get_children():
        if child is LineEdit:
            (child as LineEdit).text = code
        if child is VBoxContainer and child != diagnostic_content:
            _show_dtc_detail(code, child as VBoxContainer)
    dialog.queue_free()

func _build_repair_page() -> void:
    _page_heading(repair_box, "Пошаговый ремонт", "Инструкция, инструменты и контроль каждого шага", "res://assets/ui/icons/book.svg")
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 8)
    repair_box.add_child(top)
    var close_btn := Button.new()
    close_btn.text = "← К справочнику" if mobile_technical_catalog else "← К 3D"
    close_btn.pressed.connect(_return_to_3d_from_repair)
    top.add_child(close_btn)

    repair_title = Label.new()
    repair_title.text = "Пошаговый ремонт"
    repair_title.add_theme_font_size_override("font_size", 24)
    repair_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    repair_box.add_child(repair_title)

    repair_progress = Label.new()
    repair_progress.modulate = Color("8f9aa7")
    repair_box.add_child(repair_progress)

    repair_part_label = Label.new()
    repair_part_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    repair_part_label.modulate = Color("71ddb6")
    repair_box.add_child(repair_part_label)

    repair_scope_label = Label.new()
    repair_scope_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    repair_scope_label.modulate = Color("8f9aa7")
    repair_box.add_child(repair_scope_label)

    var card := _glass_card(repair_box)
    repair_step_title = Label.new()
    repair_step_title.add_theme_font_size_override("font_size", 22)
    repair_step_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(repair_step_title)
    repair_step_body = Label.new()
    repair_step_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(repair_step_body)
    repair_tool_label = Label.new()
    repair_tool_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    repair_tool_label.modulate = Color("aeb8c4")
    card.add_child(repair_tool_label)
    repair_warning_label = Label.new()
    repair_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    repair_warning_label.modulate = Color("f0b35b")
    card.add_child(repair_warning_label)

    var actions := GridContainer.new()
    actions.columns = 2
    actions.add_theme_constant_override("h_separation", 8)
    actions.add_theme_constant_override("v_separation", 8)
    repair_box.add_child(actions)

    repair_back_button = Button.new()
    repair_back_button.text = "Назад"
    repair_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    repair_back_button.pressed.connect(_repair_previous_step)
    actions.add_child(repair_back_button)

    repair_next_button = Button.new()
    repair_next_button.text = "Готово →"
    repair_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    repair_next_button.pressed.connect(_repair_next_step)
    actions.add_child(repair_next_button)

    var show_3d_btn := Button.new()
    show_3d_btn.text = "Показать в справочнике" if mobile_technical_catalog else "Показать деталь в 3D"
    show_3d_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    show_3d_btn.pressed.connect(_show_current_repair_part_in_3d)
    actions.add_child(show_3d_btn)

    var restart_btn := Button.new()
    restart_btn.text = "Начать заново"
    restart_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart_btn.pressed.connect(_restart_repair_guide)
    actions.add_child(restart_btn)

    repair_finish_box = VBoxContainer.new()
    repair_finish_box.add_theme_constant_override("separation", 8)
    repair_finish_box.visible = false
    repair_box.add_child(repair_finish_box)
    var done_label := Label.new()
    done_label.text = "Инструкция пройдена. Отмечай замену только если работа действительно выполнена на автомобиле."
    done_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    done_label.modulate = Color("71ddb6")
    repair_finish_box.add_child(done_label)
    var save_work_btn := Button.new()
    save_work_btn.text = "Записать выполненную замену"
    save_work_btn.pressed.connect(_record_completed_repair)
    repair_finish_box.add_child(save_work_btn)

func _open_repair_for_part(part_id: String, part_name: String) -> void:
    var guide := RepairService.guide_for_part(part_id)
    if guide.is_empty():
        _show_info_dialog("Пошаговый ремонт", "Для «%s» пошаговая инструкция ещё не добавлена. Архитектура уже готова — будем наполнять проверенными процедурами по узлам." % part_name)
        return
    repair_guide_id = str(guide.get("id", ""))
    var session := RepairService.start_session(repair_guide_id, part_id)
    repair_step_index = int(session.get("step", 0))
    _switch_to_page(repair_box)
    _render_repair_step()

func _render_repair_step() -> void:
    var guide := RepairService.get_guide(repair_guide_id)
    if guide.is_empty():
        return
    var steps: Array = guide.get("steps", [])
    if steps.is_empty():
        return
    repair_step_index = clampi(repair_step_index, 0, steps.size() - 1)
    var step: Dictionary = steps[repair_step_index]
    repair_title.text = str(guide.get("title", "Пошаговый ремонт"))
    repair_progress.text = "Шаг %d из %d • Сложность %s" % [repair_step_index + 1, steps.size(), str(guide.get("difficulty", "—"))]
    repair_part_label.text = "Сейчас: %s" % _repair_part_name(str(step.get("part_id", "")))
    repair_scope_label.text = str(guide.get("verified_scope", ""))
    repair_step_title.text = str(step.get("title", "Шаг"))
    repair_step_body.text = str(step.get("body", ""))
    var tool := str(step.get("tool", ""))
    repair_tool_label.text = "Сейчас понадобится: %s" % tool if tool != "" else ""
    var warning := str(step.get("warning", ""))
    repair_warning_label.text = "Внимание: %s" % warning if warning != "" else ""
    repair_back_button.disabled = repair_step_index <= 0
    repair_next_button.disabled = false
    repair_next_button.text = "Завершить инструкцию" if repair_step_index == steps.size() - 1 else "Готово →"
    repair_finish_box.visible = false

func _repair_next_step() -> void:
    var guide := RepairService.get_guide(repair_guide_id)
    var steps: Array = guide.get("steps", [])
    if steps.is_empty():
        return
    if repair_step_index >= steps.size() - 1:
        RepairService.clear_session()
        repair_finish_box.visible = true
        repair_next_button.disabled = true
        repair_back_button.disabled = false
        return
    repair_step_index += 1
    RepairService.set_step(repair_step_index)
    _render_repair_step()

func _repair_previous_step() -> void:
    if repair_step_index <= 0:
        return
    if RepairService.active_session().is_empty():
        var guide := RepairService.get_guide(repair_guide_id)
        RepairService.start_session(repair_guide_id, str(guide.get("part_id", "")))
    repair_step_index -= 1
    RepairService.set_step(repair_step_index)
    _render_repair_step()

func _restart_repair_guide() -> void:
    var guide := RepairService.get_guide(repair_guide_id)
    if guide.is_empty():
        return
    RepairService.clear_session()
    RepairService.start_session(repair_guide_id, str(guide.get("part_id", "")))
    repair_step_index = 0
    repair_next_button.disabled = false
    _render_repair_step()

func _show_current_repair_part_in_3d() -> void:
    var guide := RepairService.get_guide(repair_guide_id)
    var steps: Array = guide.get("steps", [])
    if steps.is_empty():
        return
    var step: Dictionary = steps[clampi(repair_step_index, 0, steps.size() - 1)]
    var part_id := str(step.get("part_id", guide.get("part_id", "")))
    if vehicle_3d_view != null and vehicle_3d_view.has_method("focus_part"):
        vehicle_3d_view.focus_part(part_id)
    _switch_to_page(vehicle_3d_box)

func _return_to_3d_from_repair() -> void:
    _switch_to_page(vehicle_3d_box)

func _record_completed_repair() -> void:
    var guide := RepairService.get_guide(repair_guide_id)
    if guide.is_empty():
        return
    _open_part_replacement(str(guide.get("part_id", "")), str(guide.get("title", "Деталь")))

func _repair_part_name(part_id: String) -> String:
    var names := {
        "wheel":"Колесо",
        "brake_disc":"Тормозной диск",
        "brake_caliper":"Тормозной суппорт",
        "brake_pads":"Тормозные колодки",
        "hub":"Ступица",
        "wheel_bearing":"Ступичный подшипник"
    }
    return str(names.get(part_id, part_id if part_id != "" else "узел"))

func _build_event_dialog() -> void:
    event_dialog = PopupPanel.new()
    event_dialog.transparent_bg = true
    add_child(event_dialog)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(382), 690)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    event_dialog.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 9)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    root.add_child(title_row)
    event_dialog_title = Label.new()
    event_dialog_title.text = "Событие"
    event_dialog_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    event_dialog_title.add_theme_font_size_override("font_size", 21)
    event_dialog_title.add_theme_color_override("font_color", Color("f3fbfc"))
    title_row.add_child(event_dialog_title)
    var close := _popup_close_button()
    close.pressed.connect(func():
        _clear_event_form()
        event_dialog.hide()
    )
    title_row.add_child(close)

    var hint := Label.new()
    hint.text = "Данные сохраняются в историю автомобиля"
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color("8098a4"))
    root.add_child(hint)

    event_dialog_scroll = ScrollContainer.new()
    event_dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    event_dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    event_dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    event_dialog_scroll.scroll_deadzone = 10
    event_dialog_scroll.follow_focus = false
    root.add_child(event_dialog_scroll)

    var form := VBoxContainer.new()
    form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    form.add_theme_constant_override("separation", 8)
    event_dialog_scroll.add_child(form)

    event_id_edit = LineEdit.new()
    event_id_edit.visible = false
    form.add_child(event_id_edit)

    form.add_child(_form_label("Тип"))
    event_type = OptionButton.new()
    var types := [
        ["Обслуживание", "maintenance"],
        ["Замена масла двигателя", "engine_oil"],
        ["Замена масляного фильтра", "oil_filter"],
        ["Замена воздушного фильтра", "air_filter"],
        ["Замена антифриза", "coolant"],
        ["Замена тормозной жидкости", "brake_fluid"],
        ["Ремонт", "repair"],
        ["Замена детали", "part_replacement"],
        ["Замена двигателя", "engine_replacement"],
        ["Диагностика", "diagnostic"],
        ["Другое", "other"]
    ]
    for item in types:
        event_type.add_item(item[0])
        event_type.set_item_metadata(event_type.item_count - 1, item[1])
    event_type.item_selected.connect(func(_idx): _update_engine_fields_visibility())
    form.add_child(event_type)

    form.add_child(_form_label("Название"))
    event_title = LineEdit.new()
    event_title.placeholder_text = "Например: Замена передних колодок"
    _style_line_edit(event_title)
    form.add_child(event_title)

    form.add_child(_form_label("Дата (ГГГГ-ММ-ДД)"))
    event_date = LineEdit.new()
    event_date.text = Time.get_date_string_from_system()
    _style_line_edit(event_date)
    form.add_child(event_date)
    event_date_unknown = CheckBox.new()
    event_date_unknown.text = "Точная дата неизвестна"
    event_date_unknown.toggled.connect(func(pressed): event_date.editable = not pressed)
    form.add_child(event_date_unknown)

    form.add_child(_form_label("Пробег автомобиля"))
    event_mileage = SpinBox.new()
    event_mileage.max_value = 2000000
    event_mileage.step = 1
    var mileage_line := event_mileage.get_line_edit()
    if mileage_line != null:
        _style_line_edit(mileage_line)
    form.add_child(event_mileage)
    event_mileage_unknown = CheckBox.new()
    event_mileage_unknown.text = "Пробег на момент события неизвестен"
    event_mileage_unknown.toggled.connect(func(pressed): event_mileage.editable = not pressed)
    form.add_child(event_mileage_unknown)

    form.add_child(_form_label("Запчасти / материалы, руб."))
    event_cost = SpinBox.new()
    event_cost.max_value = 10000000
    event_cost.step = 1
    var cost_line := event_cost.get_line_edit()
    if cost_line != null:
        _style_line_edit(cost_line)
    form.add_child(event_cost)

    form.add_child(_form_label("Работа, руб."))
    event_labor_cost = SpinBox.new()
    event_labor_cost.max_value = 10000000
    event_labor_cost.step = 1
    var labor_line := event_labor_cost.get_line_edit()
    if labor_line != null:
        _style_line_edit(labor_line)
    form.add_child(event_labor_cost)

    engine_code_label = _form_label("Код установленного двигателя")
    form.add_child(engine_code_label)
    engine_code = LineEdit.new()
    engine_code.placeholder_text = "Например: CBZB"
    _style_line_edit(engine_code)
    form.add_child(engine_code)
    engine_initial_mileage_label = _form_label("Пробег двигателя до установки")
    form.add_child(engine_initial_mileage_label)
    engine_initial_mileage = SpinBox.new()
    engine_initial_mileage.max_value = 2000000
    engine_initial_mileage.step = 1
    engine_initial_mileage.tooltip_text = "Пробег двигателя до установки, если известен"
    var engine_mileage_line := engine_initial_mileage.get_line_edit()
    if engine_mileage_line != null:
        _style_line_edit(engine_mileage_line)
    form.add_child(engine_initial_mileage)
    engine_initial_mileage_unknown = CheckBox.new()
    engine_initial_mileage_unknown.text = "Пробег установленного двигателя неизвестен"
    engine_initial_mileage_unknown.toggled.connect(func(pressed): engine_initial_mileage.editable = not pressed)
    form.add_child(engine_initial_mileage_unknown)

    form.add_child(_form_label("Комментарий"))
    event_notes = TextEdit.new()
    event_notes.custom_minimum_size = Vector2(0, 110)
    event_notes.placeholder_text = "Что делали, какие детали поставили, что заметили..."
    form.add_child(event_notes)

    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    root.add_child(actions)
    var cancel := Button.new()
    cancel.text = "Отмена"
    cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel.pressed.connect(func():
        _clear_event_form()
        event_dialog.hide()
    )
    actions.add_child(cancel)
    var save := Button.new()
    save.text = "Сохранить"
    save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_primary_button(save)
    save.pressed.connect(func():
        _save_event_from_form()
        event_dialog.hide()
    )
    actions.add_child(save)

    _update_engine_fields_visibility()

func _form_label(text_value: String) -> Label:
    var l := Label.new()
    l.text = text_value
    l.modulate = Color("b9c3ce")
    return l

func _page_heading(parent: VBoxContainer, title_text: String, subtitle_text: String, icon_path: String) -> void:
    var shell := PanelContainer.new()
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_theme_stylebox_override("panel", _style_box(Color("071923e8"), 20, Color("174a56"), 1, Color("00e6e61c"), 2))
    parent.add_child(shell)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 11)
    margin.add_theme_constant_override("margin_bottom", 11)
    shell.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    margin.add_child(row)

    var icon_shell := PanelContainer.new()
    icon_shell.custom_minimum_size = Vector2(46, 46)
    icon_shell.add_theme_stylebox_override("panel", _style_box(Color("063641ef"), 17, Color("0edee5"), 1, Color("00ebeb42"), 3))
    row.add_child(icon_shell)
    icon_shell.add_child(_centered_icon(icon_path, 25, Color("18eef0")))

    var texts := VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    texts.add_theme_constant_override("separation", 2)
    row.add_child(texts)

    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("f5fbfd"))
    texts.add_child(title)

    var subtitle := Label.new()
    subtitle.text = subtitle_text
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("91a9b5"))
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texts.add_child(subtitle)

func _page_banner(parent: VBoxContainer, image_path: String, title_text: String, subtitle_text: String) -> void:
    var banner := Panel.new()
    banner.custom_minimum_size.y = 138
    banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    banner.clip_contents = true
    banner.add_theme_stylebox_override("panel", _style_box(Color("071821ef"), 20, Color("174b57"), 1, Color("00e4e41a"), 2))
    parent.add_child(banner)

    var photo := TextureRect.new()
    photo.texture = load(image_path)
    photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(photo)

    var dark := TextureRect.new()
    dark.texture = load("res://assets/ui/fade_bottom.png")
    dark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    dark.stretch_mode = TextureRect.STRETCH_SCALE
    dark.anchor_left = 0.0
    dark.anchor_right = 1.0
    dark.anchor_top = 0.30
    dark.anchor_bottom = 1.0
    dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(dark)

    var tint := ColorRect.new()
    tint.color = Color("02101722")
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(tint)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 15)
    margin.add_theme_constant_override("margin_right", 15)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(margin)

    var column := VBoxContainer.new()
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(column)
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(spacer)
    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color("f5fbfd"))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(title)
    var subtitle := Label.new()
    subtitle.text = subtitle_text
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("aec4ce"))
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(subtitle)

func _style_box(bg: Color, radius: int, border: Color = Color("00000000"), border_width: int = 0, shadow: Color = Color("00000000"), shadow_size: int = 0) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.border_color = border
    style.shadow_color = shadow
    style.shadow_size = shadow_size
    return style

func _icon_rect(path: String, size: float, tint: Color = Color("ffffff")) -> TextureRect:
    var icon := TextureRect.new()
    icon.texture = load(path)
    icon.custom_minimum_size = Vector2(size, size)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.modulate = tint
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func _centered_icon(path: String, size: float, tint: Color = Color("ffffff")) -> CenterContainer:
    # Keep every UI icon in a square footprint. This prevents Android/container
    # layout from optically stretching SVGs inside wide/tall shells.
    var center := CenterContainer.new()
    center.custom_minimum_size = Vector2(size, size)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    center.add_child(_icon_rect(path, size, tint))
    return center

func _create_sheet_popup(title_text: String, preferred_size: Vector2i = Vector2i(390, 520)) -> Dictionary:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(float(preferred_size.x) - 18.0), maxf(300.0, float(preferred_size.y) - 40.0))
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 9)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    root.add_child(title_row)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color("f3fbfc"))
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.scroll_deadzone = 10
    scroll.follow_focus = true
    root.add_child(scroll)

    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    scroll.add_child(content)

    popup.popup_hide.connect(func(): popup.queue_free())
    return {"popup": popup, "root": root, "content": content, "scroll": scroll}

func _show_sheet_popup(sheet: Dictionary, preferred_size: Vector2i) -> void:
    var popup := sheet.get("popup") as PopupPanel
    if popup == null:
        return
    _apply_touch_targets(popup)
    var scroll := sheet.get("scroll") as ScrollContainer
    if scroll != null:
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        scroll.scroll_vertical = 0
    popup.popup_centered(_mobile_dialog_size(preferred_size))

func _add_sheet_actions(root: VBoxContainer, popup: PopupPanel, primary_text: String, on_primary: Callable) -> void:
    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    root.add_child(actions)
    var cancel := Button.new()
    cancel.text = "Отмена"
    cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel.pressed.connect(func(): popup.hide())
    actions.add_child(cancel)
    var primary := Button.new()
    primary.text = primary_text
    primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_primary_button(primary)
    primary.pressed.connect(func():
        if on_primary.is_valid():
            on_primary.call()
    )
    actions.add_child(primary)

func _popup_close_button() -> Button:
    var button := Button.new()
    button.text = "×"
    button.tooltip_text = "Закрыть"
    button.custom_minimum_size = Vector2(40, 40)
    button.set_meta("compact_icon_button", true)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 25)
    button.add_theme_color_override("font_color", Color("dcecf2"))
    button.add_theme_stylebox_override("normal", _style_box(Color("081820c9"), 12, Color("17343d"), 1))
    button.add_theme_stylebox_override("hover", _style_box(Color("0a252dde"), 12, Color("22cfd4"), 1))
    button.add_theme_stylebox_override("pressed", _style_box(Color("092229e8"), 12, Color("22e7ea"), 1))
    return button

func _mobile_dialog_content_width(preferred: float = 370.0, viewport_width_override: float = -1.0) -> float:
    var viewport_width := viewport_width_override if viewport_width_override > 0.0 else get_viewport_rect().size.x
    return GlobalSearchLayout.content_width(preferred, viewport_width)

func _mobile_dialog_size(preferred: Vector2i, viewport_size_override: Vector2i = Vector2i.ZERO) -> Vector2i:
    var viewport_size := Vector2(get_viewport_rect().size) if viewport_size_override == Vector2i.ZERO else Vector2(viewport_size_override)
    return GlobalSearchLayout.popup_size(preferred, Vector2i(viewport_size))

func _mini_round_button(icon_path: String) -> Button:
    var button := Button.new()
    # Do not use Button.icon here: on Android the theme paddings make small
    # round-button icons look optically shifted. Center a TextureRect explicitly.
    button.custom_minimum_size = Vector2(48, 48)
    button.set_meta("compact_icon_button", true)
    button.add_theme_stylebox_override("normal", _style_box(Color("09232dd9"), 24, Color("1a4c57"), 1))
    button.add_theme_stylebox_override("hover", _style_box(Color("0a3a44ef"), 24, Color("2df4f6"), 1, Color("00dce844"), 4))
    button.add_theme_stylebox_override("pressed", _style_box(Color("082d36ef"), 24, Color("2df4f6"), 1, Color("00dce844"), 3))
    button.focus_mode = Control.FOCUS_NONE

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(center)

    var icon_size := 21.0
    if icon_path.ends_with("edit.svg"):
        icon_size = 20.0
    elif icon_path.ends_with("copy.svg"):
        icon_size = 19.0
    var icon := _centered_icon(icon_path, icon_size, Color("e6fbff"))
    center.add_child(icon)
    return button

func _metric_card(title_text: String, icon_path: String, action: Callable) -> Dictionary:
    var card := Panel.new()
    card.custom_minimum_size.y = 92
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    # Calm premium: metrics are informative, not primary CTAs.
    card.add_theme_stylebox_override("panel", _style_box(Color("081820e8"), 18, Color("173f49"), 1))

    var click := Button.new()
    click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    click.focus_mode = Control.FOCUS_NONE
    click.add_theme_stylebox_override("normal", _style_box(Color("00000000"), 18))
    click.add_theme_stylebox_override("hover", _style_box(Color("0b313a24"), 18, Color("18e9ec42"), 1))
    click.add_theme_stylebox_override("pressed", _style_box(Color("0b313a38"), 18, Color("18e9ec66"), 1))
    click.pressed.connect(action)
    card.add_child(click)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 9)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(margin)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(row)

    var icon_shell := PanelContainer.new()
    icon_shell.custom_minimum_size = Vector2(40, 40)
    icon_shell.add_theme_stylebox_override("panel", _style_box(Color("082a33df"), 15, Color("16727d"), 1))
    icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(icon_shell)
    icon_shell.add_child(_centered_icon(icon_path, 22, Color("20dfe3")))

    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_box.add_theme_constant_override("separation", 0)
    text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(text_box)
    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 12)
    title.add_theme_color_override("font_color", Color("8fa6b2"))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_box.add_child(title)
    var value := Label.new()
    value.add_theme_font_size_override("font_size", 17)
    value.add_theme_color_override("font_color", Color("f1fafc"))
    value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    value.max_lines_visible = 2
    value.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_box.add_child(value)

    var caption := Label.new()
    caption.add_theme_font_size_override("font_size", 9)
    caption.add_theme_color_override("font_color", Color("6f8794"))
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.max_lines_visible = 1
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_box.add_child(caption)

    return {"card": card, "value": value, "caption": caption}

func _feature_card(title_text: String, subtitle_text: String, image_path: String, icon_path: String, action: Callable) -> Dictionary:
    var card := Panel.new()
    card.custom_minimum_size.y = 88
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.clip_contents = true
    # Secondary actions stay visually quiet; the photo supplies depth without competing with search.
    card.add_theme_stylebox_override("panel", _style_box(Color("07171fe9"), 18, Color("163b45"), 1))

    var click := Button.new()
    click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    click.focus_mode = Control.FOCUS_NONE
    click.add_theme_stylebox_override("normal", _style_box(Color("00000000"), 18))
    click.add_theme_stylebox_override("hover", _style_box(Color("0b313a20"), 18, Color("18e9ec38"), 1))
    click.add_theme_stylebox_override("pressed", _style_box(Color("0b313a35"), 18, Color("18e9ec5a"), 1))
    click.pressed.connect(action)
    card.add_child(click)

    var photo := TextureRect.new()
    photo.texture = load(image_path)
    photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    photo.anchor_left = 0.60
    photo.anchor_right = 1.0
    photo.anchor_top = 0.0
    photo.anchor_bottom = 1.0
    photo.modulate = Color(0.82, 0.88, 0.92, 0.68)
    photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(photo)
    var image_shade := TextureRect.new()
    image_shade.texture = load("res://assets/ui/fade_left.png")
    image_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image_shade.stretch_mode = TextureRect.STRETCH_SCALE
    image_shade.anchor_left = 0.60
    image_shade.anchor_right = 0.82
    image_shade.anchor_top = 0.0
    image_shade.anchor_bottom = 1.0
    image_shade.modulate = Color(1, 1, 1, 0.90)
    image_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(image_shade)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(margin)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(row)

    var icon_shell := PanelContainer.new()
    icon_shell.custom_minimum_size = Vector2(44, 44)
    icon_shell.add_theme_stylebox_override("panel", _style_box(Color("082a33df"), 15, Color("16727d"), 1))
    icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(icon_shell)
    icon_shell.add_child(_centered_icon(icon_path, 23, Color("20dfe3")))

    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_box.add_theme_constant_override("separation", 1)
    text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(text_box)
    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", Color("eef7f9"))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_box.add_child(title)
    var subtitle := Label.new()
    subtitle.text = subtitle_text
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("9db0ba"))
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.max_lines_visible = 2
    subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_box.add_child(subtitle)

    return {"card": card, "subtitle": subtitle}

func _glass_card(parent: Container, accent: Color = Color("184752")) -> VBoxContainer:
    var shell := PanelContainer.new()
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_theme_stylebox_override("panel", _style_box(Color("071821e8"), 18, accent, 1))
    parent.add_child(shell)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 13)
    margin.add_theme_constant_override("margin_right", 13)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    shell.add_child(margin)

    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 6)
    margin.add_child(box)
    return box

func _connect_signals() -> void:
    AppState.mileage_changed.connect(_refresh_all)
    AppState.history_changed.connect(_refresh_all)
    AppState.maintenance_changed.connect(_refresh_all)
    AppState.vehicle_changed.connect(_refresh_all)
    Notifications.status_changed.connect(_refresh_reminders)
    Notifications.test_result.connect(func(message: String): _show_info_dialog("Уведомления", message))
    Notifications.maintenance_notification_opened.connect(_on_maintenance_notification_opened)
    call_deferred("_consume_pending_notification_open")

func _consume_pending_notification_open() -> void:
    var item_id := Notifications.consume_last_opened_item_id()
    if item_id != "" and item_id != "test":
        _on_maintenance_notification_opened(item_id)

func _refresh_all() -> void:
    if vehicle_3d_view != null:
        vehicle_3d_view.set_vehicle_profile(VehicleService.vehicle())
    _refresh_overview()
    _refresh_history()
    _refresh_maintenance()
    _refresh_reminders()
    _apply_touch_targets(self)
    Notifications.call_deferred("sync_maintenance")

func _refresh_overview() -> void:
    var vehicle: Dictionary = VehicleService.vehicle()
    header_subtitle.text = "%s %s • %s • %s" % [vehicle.get("make","Skoda"), vehicle.get("model","Yeti"), str(int(vehicle.get("year", 2011))), vehicle.get("drivetrain","FWD")]
    vehicle_name_label.text = str(vehicle.get("nickname", "Моя Yeti"))
    vehicle_vin_label.text = "VIN: %s" % str(vehicle.get("vin", ""))
    if Storage.is_demo_mode():
        data_mode_value.text = "ДЕМО-РЕЖИМ\nТестовые записи хранятся отдельно и не затрагивают твою Yeti."
        data_mode_value.modulate = Color("f3c86a")
        header_title.text = "Yeti"
        header_accent.text = "Garage • ДЕМО"
    else:
        data_mode_value.text = "МОЯ МАШИНА\nРаботаем с реальной историей автомобиля."
        data_mode_value.modulate = Color("b9d7c5")
        header_title.text = "Yeti"
        header_accent.text = "Garage"
    var current := MileageService.current_mileage()
    mileage_value.text = "%s км" % _format_int(current) if current > 0 else "Пробег не указан"
    if mileage_caption != null:
        mileage_caption.text = "Текущий пробег" if current > 0 else "Пробег пока не указан"

    var engine_event := ServiceHistoryService.latest_engine_replacement()
    var factory_name := str(vehicle.get("factory_engine_name", "1.2 TSI"))
    var factory_code := str(vehicle.get("factory_engine_code", "CBZB"))
    var factory_line := "По заводской конфигурации: %s%s" % [factory_name, (" (%s)" % factory_code) if factory_code != "" else ""]
    if engine_event.is_empty():
        if bool(vehicle.get("engine_replacement_known", false)):
            engine_value.text = "Установленный двигатель: данные пока не подтверждены\n%s" % factory_line
        elif bool(vehicle.get("current_engine_confirmed", false)):
            var current_name := str(vehicle.get("current_engine_name", ""))
            var current_code := str(vehicle.get("current_engine_code", ""))
            var current_label := current_name if current_name != "" else "Двигатель"
            if current_code != "":
                current_label += " (%s)" % current_code
            engine_value.text = "%s\n%s" % [current_label, factory_line]
        else:
            engine_value.text = "Текущий двигатель не подтверждён\n%s" % factory_line
    else:
        var install_unknown := bool(engine_event.get("mileage_unknown", false))
        var install_mileage := int(engine_event.get("mileage", 0))
        var initial_unknown := bool(engine_event.get("engine_initial_mileage_unknown", false))
        var initial := int(engine_event.get("engine_initial_mileage", 0))
        var code := str(engine_event.get("engine_code", "")).strip_edges()
        var engine_label := code if code != "" else "код двигателя не указан"
        if install_unknown or install_mileage <= 0:
            engine_value.text = "%s • замена отмечена\nПробег автомобиля при установке неизвестен\n%s" % [engine_label, factory_line]
        else:
            var since_install: int = current - install_mileage if current > install_mileage else 0
            var text := "%s • после установки: %s км" % [engine_label, _format_int(since_install)]
            if not initial_unknown and initial > 0:
                text += "\nПримерный общий пробег двигателя: %s км" % _format_int(initial + since_install)
            text += "\n%s" % factory_line
            engine_value.text = text

    # На компактной карточке главной оставляем только главное значение.
    if engine_event.is_empty():
        var compact_engine := factory_name
        if factory_code != "":
            compact_engine += " (%s)" % factory_code
        engine_value.text = compact_engine
        if engine_caption != null:
            engine_caption.text = "Заводская конфигурация"
    else:
        var compact_code := str(engine_event.get("engine_code", "")).strip_edges()
        engine_value.text = compact_code if compact_code != "" else "Двигатель заменён"
        if engine_caption != null:
            engine_caption.text = "Установленный двигатель"

    var next_text := "Добавь последнее обслуживание — начну считать сроки."
    for item in MaintenanceService.items():
        if str(item.get("status","unknown")) != "unknown":
            next_text = _maintenance_summary(item)
            break
    next_service_value.text = next_text

    var reminder_summary: Dictionary = ReminderService.summary()
    var active_count := int(reminder_summary.get("total", 0))
    var missing_count := int(reminder_summary.get("missing_baselines", 0))
    if active_count > 0:
        var urgent_count := int(reminder_summary.get("overdue", 0)) + int(reminder_summary.get("due", 0))
        reminders_summary_value.text = "%s активных • %s требуют внимания сейчас" % [str(active_count), str(urgent_count)]
    elif missing_count > 0:
        reminders_summary_value.text = "Нет активных. Для %s пунктов не хватает истории." % str(missing_count)
    else:
        reminders_summary_value.text = "Активных напоминаний нет."

    total_cost_value.text = "%s руб." % _format_money(ServiceHistoryService.total_cost())
    _refresh_saved_fault_card()

    _clear_children(recent_box)
    var latest := ServiceHistoryService.events()
    if latest.is_empty():
        var empty := Label.new()
        empty.text = "История пока пустая."
        empty.modulate = Color("8793a1")
        recent_box.add_child(empty)
    else:
        for i in range(min(3, latest.size())):
            var event: Dictionary = latest[i]
            var l := Label.new()
            l.text = "%s  •  %s\n%s" % [_event_date_text(event), event.get("title","Событие"), _event_mileage_text(event)]
            l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            recent_box.add_child(l)

func _refresh_history() -> void:
    _clear_children_after(history_box, 3)
    var events := ServiceHistoryService.events()
    if events.is_empty():
        var empty_card := _glass_card(history_box)
        var empty_title := Label.new()
        empty_title.text = "История пока пустая"
        empty_title.add_theme_font_size_override("font_size", 18)
        empty_card.add_child(empty_title)
        var empty_text := Label.new()
        empty_text.text = "Добавь первую работу, замену или запись пробега — дальше всё будет собираться в одной ленте."
        empty_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty_text.add_theme_font_size_override("font_size", 12)
        empty_text.modulate = Color("8fa5b1")
        empty_card.add_child(empty_text)
        return
    for event in events:
        var card := _glass_card(history_box)
        var title := Label.new()
        title.text = str(event.get("title", "Событие"))
        title.add_theme_font_size_override("font_size", 19)
        card.add_child(title)
        var meta := Label.new()
        meta.text = "%s • %s" % [_event_date_text(event), _event_mileage_text(event)]
        meta.modulate = Color("9ba6b2")
        card.add_child(meta)
        var cost := float(event.get("cost",0)) + float(event.get("labor_cost",0))
        if cost > 0:
            var c := Label.new()
            c.text = "Стоимость: %s руб." % _format_money(cost)
            card.add_child(c)
        if str(event.get("notes", "")).strip_edges() != "":
            var notes := Label.new()
            notes.text = str(event.get("notes",""))
            notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            notes.modulate = Color("b3bdc8")
            card.add_child(notes)
        var actions := VBoxContainer.new()
        card.add_child(actions)
        var details := Button.new()
        details.text = "Открыть"
        details.pressed.connect(_show_event_details.bind(event))
        actions.add_child(details)
        var edit := Button.new()
        edit.text = "Изменить"
        edit.pressed.connect(_edit_event.bind(event))
        actions.add_child(edit)
        var del := Button.new()
        del.text = "Удалить"
        del.pressed.connect(_confirm_delete.bind(str(event.get("id",""))))
        actions.add_child(del)

func _refresh_maintenance() -> void:
    _clear_children_after(maintenance_box, 3)
    for item in MaintenanceService.items():
        var card := _glass_card(maintenance_box)
        var title := Label.new()
        title.text = str(item.get("title","Обслуживание"))
        title.add_theme_font_size_override("font_size", 19)
        card.add_child(title)
        var status := Label.new()
        status.text = _maintenance_summary(item)
        status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.add_child(status)
        var actions := VBoxContainer.new()
        actions.add_theme_constant_override("separation", 8)
        card.add_child(actions)
        var done := Button.new()
        done.text = "Выполнено сейчас"
        done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        done.pressed.connect(_mark_maintenance_done.bind(item))
        actions.add_child(done)
        var configure := Button.new()
        configure.text = "Интервал"
        configure.pressed.connect(_open_maintenance_rule_dialog.bind(item))
        actions.add_child(configure)

func _refresh_reminders() -> void:
    if notification_status_value != null:
        notification_status_value.text = Notifications.status_text()
    if notification_controls_box != null:
        notification_controls_box.visible = Notifications.plugin_available()
    if notification_enabled_toggle != null:
        notification_enabled_toggle.set_pressed_no_signal(Notifications.notifications_enabled())
    _clear_children(reminders_dynamic_box)

    var active: Array = ReminderService.active_reminders()
    if active.is_empty():
        var ok_card := _glass_card(reminders_dynamic_box, Color("1b5f54"))
        var ok_title := Label.new()
        ok_title.text = "Срочных напоминаний нет"
        ok_title.add_theme_font_size_override("font_size", 20)
        ok_card.add_child(ok_title)
        var ok_text := Label.new()
        ok_text.text = "Когда появится последнее обслуживание, приложение начнёт считать сроки по пробегу и дате."
        ok_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ok_text.modulate = Color("9ba6b2")
        ok_card.add_child(ok_text)
    else:
        for reminder in active:
            var status := str(reminder.get("status", "soon"))
            var reminder_accent := Color("184752")
            if status in ["due", "soon"]:
                reminder_accent = Color("6d4f22")
            elif status == "overdue":
                reminder_accent = Color("71313a")
            var card := _glass_card(reminders_dynamic_box, reminder_accent)
            var title := Label.new()
            title.text = "%s %s" % [_status_icon(status), str(reminder.get("title", "Обслуживание"))]
            title.add_theme_font_size_override("font_size", 20)
            card.add_child(title)
            var message := Label.new()
            message.text = str(reminder.get("message", ""))
            message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            message.modulate = Color("b9c3ce")
            card.add_child(message)
            var actions := VBoxContainer.new()
            actions.add_theme_constant_override("separation", 8)
            card.add_child(actions)
            var done := Button.new()
            done.text = "Выполнено сейчас"
            done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            done.pressed.connect(_mark_maintenance_done.bind(reminder.get("maintenance_item", {})))
            actions.add_child(done)
            var snooze := Button.new()
            snooze.text = "Через 7 дней"
            snooze.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            snooze.pressed.connect(_snooze_reminder.bind(str(reminder.get("id", ""))))
            actions.add_child(snooze)
            var plan := Button.new()
            plan.text = "К ТО"
            plan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            plan.pressed.connect(_open_maintenance_tab)
            actions.add_child(plan)

    var missing: Array = ReminderService.missing_baselines()
    if not missing.is_empty():
        var missing_card := _glass_card(reminders_dynamic_box, Color("5a4b25"))
        var missing_title := Label.new()
        missing_title.text = "Нужны исходные данные"
        missing_title.add_theme_font_size_override("font_size", 19)
        missing_card.add_child(missing_title)
        var missing_text := Label.new()
        var names: Array[String] = []
        for item in missing:
            names.append(str(item.get("title", "Обслуживание")))
        missing_text.text = "Пока не считаю сроки для: %s. Ничего не угадываю — внесём данные по чекам позже." % ", ".join(names)
        missing_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        missing_text.modulate = Color("8793a1")
        missing_card.add_child(missing_text)

func _status_icon(status: String) -> String:
    match status:
        "overdue": return "•"
        "due": return "•"
        "soon": return "•"
        _: return "•"

func _snooze_reminder(reminder_id: String) -> void:
    ReminderService.snooze(reminder_id, 7)

func _open_reminders_tab() -> void:
    _switch_to_page(reminders_box)

func _open_maintenance_tab() -> void:
    _switch_to_page(maintenance_box)

func _on_maintenance_notification_opened(item_id: String) -> void:
    _switch_to_page(maintenance_box)
    for item_value in MaintenanceService.items():
        var item: Dictionary = item_value
        if str(item.get("id", "")) == item_id:
            _show_info_dialog(
                str(item.get("title", "Обслуживание")),
                _maintenance_summary(item) + "\n\nНапоминание открыто из системной шторки телефона."
            )
            return

func _maintenance_summary(item: Dictionary) -> String:
    var status := str(item.get("status", "unknown"))
    if status == "unknown":
        return "История неизвестна — добавь последнюю замену."
    var chunks: Array[String] = []
    var remaining_km = item.get("remaining_km", null)
    var remaining_days = item.get("remaining_days", null)
    if remaining_km != null:
        var km := int(remaining_km)
        chunks.append("%s км" % (_format_int(km) if km >= 0 else ("просрочено на %s" % _format_int(abs(km)))))
    if remaining_days != null:
        var days := int(remaining_days)
        chunks.append("%s дн." % (str(days) if days >= 0 else ("просрочено на %s" % str(abs(days)))))
    var projected_date := str(item.get("projected_date_by_mileage", ""))
    if projected_date != "" and remaining_km != null and int(remaining_km) > 0:
        chunks.append("по темпу езды ≈ %s" % _display_date(projected_date))
    var prefix: String = str({"normal":"Норма", "soon":"Скоро", "due":"Пора", "overdue":"Просрочено"}.get(status, ""))
    return "%s\n%s" % [prefix, " • ".join(chunks)]

func _open_vehicle_dialog() -> void:
    var vehicle: Dictionary = VehicleService.vehicle()
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(382), 650)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 9)
    margin.add_child(root)

    var title_row := HBoxContainer.new()
    root.add_child(title_row)
    var title := Label.new()
    title.text = "Данные машины"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 21)
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    var form := VBoxContainer.new()
    form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    form.add_theme_constant_override("separation", 7)
    scroll.add_child(form)

    var nickname := _line_field(form, "Название", str(vehicle.get("nickname", "Моя Yeti")))
    var vin := _line_field(form, "VIN", str(vehicle.get("vin", "")))
    var year := _spin_field(form, "Год", int(vehicle.get("year", 2011)), 1950, 2100)
    var factory_engine_name_field := _line_field(form, "Заводской двигатель", str(vehicle.get("factory_engine_name", "1.2 TSI")))
    var factory_engine_code_field := _line_field(form, "Код двигателя", str(vehicle.get("factory_engine_code", "CBZB")))
    var replacement_known := CheckBox.new()
    replacement_known.text = "Двигатель уже заменён"
    replacement_known.button_pressed = bool(vehicle.get("engine_replacement_known", false))
    form.add_child(replacement_known)
    var engine_hint := Label.new()
    engine_hint.text = "Установленный двигатель фиксируется через событие «Замена двигателя»."
    engine_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    engine_hint.add_theme_font_size_override("font_size", 11)
    engine_hint.add_theme_color_override("font_color", Color("8198a4"))
    form.add_child(engine_hint)
    var power := _spin_field(form, "Заводская мощность, л.с.", int(vehicle.get("power_hp", 105)), 0, 2000)
    var transmission := _line_field(form, "Коробка", str(vehicle.get("transmission", "Не указана")))
    var drivetrain := _line_field(form, "Привод", str(vehicle.get("drivetrain", "FWD")))

    var save := Button.new()
    save.text = "Сохранить"
    _style_primary_button(save)
    root.add_child(save)
    save.pressed.connect(func():
        VehicleService.update_vehicle({
            "nickname": nickname.text.strip_edges(),
            "vin": vin.text.strip_edges(),
            "year": int(year.value),
            "factory_engine_name": factory_engine_name_field.text.strip_edges(),
            "factory_engine_code": factory_engine_code_field.text.strip_edges(),
            "engine_replacement_known": replacement_known.button_pressed,
            "power_hp": int(power.value),
            "transmission": transmission.text.strip_edges(),
            "drivetrain": drivetrain.text.strip_edges()
        })
        popup.hide()
    )

    _apply_touch_targets(popup)
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    popup.popup_centered(_mobile_dialog_size(Vector2i(400, 700)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _style_line_edit(field: LineEdit) -> void:
    field.custom_minimum_size.y = maxf(field.custom_minimum_size.y, 48.0)
    field.add_theme_color_override("font_color", Color("eaf4f7"))
    field.add_theme_color_override("font_placeholder_color", Color("65818d"))
    field.add_theme_color_override("caret_color", Color("18e4e8"))
    field.add_theme_stylebox_override("normal", _style_box(Color("071a23f2"), 14, Color("17414c"), 1))
    field.add_theme_stylebox_override("focus", _style_box(Color("082029f7"), 14, Color("18dfe6"), 1, Color("00dfe81a"), 2))

func _style_primary_button(button: Button) -> void:
    button.custom_minimum_size.y = 50
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", Color("f2fbfc"))
    button.add_theme_stylebox_override("normal", _style_box(Color("0a4a53"), 16, Color("18dfe6"), 1, Color("00e7e72b"), 3))
    button.add_theme_stylebox_override("pressed", _style_box(Color("09616a"), 16, Color("25f1f1"), 1, Color("00eeee3d"), 3))

func _line_field(form: VBoxContainer, label_text: String, value: String) -> LineEdit:
    form.add_child(_form_label(label_text))
    var field := LineEdit.new()
    field.text = value
    _style_line_edit(field)
    form.add_child(field)
    return field

func _spin_field(form: VBoxContainer, label_text: String, value: int, min_value: int, max_value: int) -> SpinBox:
    form.add_child(_form_label(label_text))
    var field := SpinBox.new()
    field.min_value = min_value
    field.max_value = max_value
    field.step = 1
    field.value = value
    field.custom_minimum_size.y = 48
    var spin_line := field.get_line_edit()
    if spin_line != null:
        _style_line_edit(spin_line)
    form.add_child(field)
    return field

func _open_maintenance_rule_dialog(item: Dictionary) -> void:
    var sheet := _create_sheet_popup("Интервал обслуживания", Vector2i(400, 650))
    var dialog := sheet["popup"] as PopupPanel
    var form := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    var title := Label.new()
    title.text = str(item.get("title", "Обслуживание"))
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color("eaf8fa"))
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    form.add_child(title)

    var note := Label.new()
    note.text = "Это настраиваемый ориентир. Для конкретной машины сервисная книжка и её документация имеют приоритет."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 12)
    note.add_theme_color_override("font_color", Color("829aa5"))
    form.add_child(note)

    var km := _spin_field(form, "Интервал, км (0 = не учитывать)", int(item.get("interval_km", 0)), 0, 500000)
    var days := _spin_field(form, "Интервал, дней (0 = не учитывать)", int(item.get("interval_days", 0)), 0, 5000)
    var warning_km := _spin_field(form, "Предупредить за, км", int(item.get("warning_km", 0)), 0, 100000)
    var warning_days := _spin_field(form, "Предупредить за, дней", int(item.get("warning_days", 0)), 0, 1000)

    _add_sheet_actions(root, dialog, "Сохранить", func():
        var target_id := str(item.get("id", ""))
        var rules: Array = Storage.data.get("maintenance_rules", [])
        for rule in rules:
            if str(rule.get("id", "")) == target_id:
                rule["interval_km"] = int(km.value)
                rule["interval_days"] = int(days.value)
                rule["warning_km"] = int(warning_km.value)
                rule["warning_days"] = int(warning_days.value)
                break
        Storage.data["maintenance_rules"] = rules
        Storage.save()
        AppState.maintenance_changed.emit()
        dialog.hide()
    )
    _show_sheet_popup(sheet, Vector2i(400, 650))

func _toggle_demo_mode() -> void:
    var target_demo := not Storage.is_demo_mode()
    var body := "Открыть тестовую машину? Реальные данные Yeti останутся в отдельном файле и не изменятся." if target_demo else "Вернуться к реальной Yeti? Демо-данные останутся отдельно."
    _open_confirm_popup("Переключить режим", body, "Переключить", func(): Storage.set_demo_mode(target_demo))

func _open_mileage_dialog() -> void:
    var sheet := _create_sheet_popup("Обновить пробег", Vector2i(380, 420))
    var dialog := sheet["popup"] as PopupPanel
    var box := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    box.add_child(_form_label("Пробег, км"))
    var spin := SpinBox.new()
    spin.max_value = 2000000
    spin.step = 1
    spin.value = MileageService.current_mileage()
    var spin_line := spin.get_line_edit()
    if spin_line != null:
        _style_line_edit(spin_line)
    box.add_child(spin)

    box.add_child(_form_label("Дата"))
    var date := LineEdit.new()
    date.text = Time.get_date_string_from_system()
    date.placeholder_text = "ГГГГ-ММ-ДД"
    _style_line_edit(date)
    box.add_child(date)

    _add_sheet_actions(root, dialog, "Сохранить", func():
        MileageService.add_record(int(spin.value), date.text.strip_edges())
        dialog.hide()
    )
    _show_sheet_popup(sheet, Vector2i(380, 420))

func _open_mileage_history() -> void:
    var sheet := _create_sheet_popup("История пробега", Vector2i(400, 700))
    var dialog := sheet["popup"] as PopupPanel
    var box := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    var records := MileageService.history()
    if records.is_empty():
        var empty := Label.new()
        empty.text = "Записей пробега пока нет."
        empty.add_theme_color_override("font_color", Color("8793a1"))
        box.add_child(empty)
    else:
        for record in records:
            var card := _glass_card(box)
            var value := Label.new()
            value.text = "%s км" % _format_int(int(record.get("mileage", 0)))
            value.add_theme_font_size_override("font_size", 20)
            card.add_child(value)

            var meta := Label.new()
            meta.text = "%s • %s" % [_display_date(str(record.get("date", ""))), _mileage_source_text(str(record.get("source", "manual")))]
            meta.add_theme_color_override("font_color", Color("9ba6b2"))
            card.add_child(meta)

            var actions := VBoxContainer.new()
            actions.add_theme_constant_override("separation", 8)
            card.add_child(actions)

            var edit := Button.new()
            edit.text = "Исправить"
            edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            edit.pressed.connect(_edit_mileage_record.bind(record, dialog))
            actions.add_child(edit)

            var del := Button.new()
            del.text = "Удалить"
            del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            del.pressed.connect(_delete_mileage_record.bind(record, dialog))
            actions.add_child(del)

    var close := Button.new()
    close.text = "Закрыть"
    _style_primary_button(close)
    close.pressed.connect(func(): dialog.hide())
    root.add_child(close)
    _show_sheet_popup(sheet, Vector2i(400, 700))

func _edit_mileage_record(record: Dictionary, parent_dialog: PopupPanel) -> void:
    var sheet := _create_sheet_popup("Исправить пробег", Vector2i(380, 430))
    var dialog := sheet["popup"] as PopupPanel
    var box := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    box.add_child(_form_label("Пробег, км"))
    var spin := SpinBox.new()
    spin.max_value = 2000000
    spin.step = 1
    spin.value = int(record.get("mileage", 0))
    var spin_line := spin.get_line_edit()
    if spin_line != null:
        _style_line_edit(spin_line)
    box.add_child(spin)

    box.add_child(_form_label("Дата"))
    var date := LineEdit.new()
    date.text = str(record.get("date", Time.get_date_string_from_system()))
    _style_line_edit(date)
    box.add_child(date)

    _add_sheet_actions(root, dialog, "Сохранить", func():
        MileageService.update_record(str(record.get("id", "")), int(spin.value), date.text.strip_edges())
        dialog.hide()
        if is_instance_valid(parent_dialog):
            parent_dialog.hide()
        _open_mileage_history()
    )
    _show_sheet_popup(sheet, Vector2i(380, 430))

func _delete_mileage_record(record: Dictionary, parent_dialog: PopupPanel) -> void:
    var body := "%s км • %s\n\nЗапись пробега будет удалена. Это действие нельзя отменить." % [_format_int(int(record.get("mileage", 0))), _display_date(str(record.get("date", "")))]
    var delete_action := func():
        MileageService.delete_record(str(record.get("id", "")))
        if is_instance_valid(parent_dialog):
            parent_dialog.hide()
        _open_mileage_history()
    _open_confirm_popup("Удалить запись пробега?", body, "Удалить", delete_action, true)

func _open_event_dialog(preset_type: String = "") -> void:
    _clear_event_form()
    if preset_type != "":
        _select_type(preset_type)
        if preset_type == "engine_replacement":
            event_title.text = "Замена двигателя"
    event_mileage.value = MileageService.current_mileage()
    event_dialog_title.text = "Замена двигателя" if preset_type == "engine_replacement" else "Новое событие"
    if event_dialog_scroll != null:
        event_dialog_scroll.scroll_vertical = 0
    _apply_touch_targets(event_dialog)
    event_dialog.popup_centered(_mobile_dialog_size(Vector2i(400, 780)))

func _edit_event(event: Dictionary) -> void:
    _clear_event_form()
    event_editing_id = str(event.get("id", ""))
    event_part_id = str(event.get("part_id", ""))
    _select_type(str(event.get("type", "other")))
    event_title.text = str(event.get("title", ""))
    event_date_unknown.button_pressed = bool(event.get("date_unknown", false))
    event_date.text = str(event.get("date", Time.get_date_string_from_system()))
    event_date.editable = not event_date_unknown.button_pressed
    event_mileage_unknown.button_pressed = bool(event.get("mileage_unknown", false))
    event_mileage.value = int(event.get("mileage", 0))
    event_mileage.editable = not event_mileage_unknown.button_pressed
    event_cost.value = float(event.get("cost", 0))
    event_labor_cost.value = float(event.get("labor_cost", 0))
    event_notes.text = str(event.get("notes", ""))
    engine_code.text = str(event.get("engine_code", ""))
    engine_initial_mileage_unknown.button_pressed = bool(event.get("engine_initial_mileage_unknown", false))
    engine_initial_mileage.value = int(event.get("engine_initial_mileage", 0))
    engine_initial_mileage.editable = not engine_initial_mileage_unknown.button_pressed
    _update_engine_fields_visibility()
    event_dialog_title.text = "Редактировать событие"
    if event_dialog_scroll != null:
        event_dialog_scroll.scroll_vertical = 0
    _apply_touch_targets(event_dialog)
    event_dialog.popup_centered(_mobile_dialog_size(Vector2i(400, 780)))

func _select_type(code: String) -> void:
    for i in range(event_type.item_count):
        if str(event_type.get_item_metadata(i)) == code:
            event_type.select(i)
            break
    _update_engine_fields_visibility()

func _update_engine_fields_visibility() -> void:
    if event_type == null or engine_code == null or engine_initial_mileage == null or engine_initial_mileage_unknown == null:
        return
    var is_engine := str(event_type.get_item_metadata(event_type.selected)) == "engine_replacement"
    if engine_code_label != null:
        engine_code_label.visible = is_engine
    engine_code.visible = is_engine
    if engine_initial_mileage_label != null:
        engine_initial_mileage_label.visible = is_engine
    engine_initial_mileage.visible = is_engine
    engine_initial_mileage_unknown.visible = is_engine

func _clear_event_form() -> void:
    event_editing_id = ""
    event_part_id = ""
    if event_title == null:
        return
    event_title.text = ""
    event_date_unknown.button_pressed = false
    event_date.text = Time.get_date_string_from_system()
    event_date.editable = true
    event_mileage_unknown.button_pressed = false
    event_mileage.value = MileageService.current_mileage()
    event_mileage.editable = true
    event_cost.value = 0
    event_labor_cost.value = 0
    event_notes.text = ""
    # Не подставляем заводской код в форму замены: после свапа текущий мотор
    # может быть другим, и мы не должны превращать CBZB в выдуманный факт.
    engine_code.text = ""
    engine_initial_mileage_unknown.button_pressed = false
    engine_initial_mileage.value = 0
    engine_initial_mileage.editable = true
    event_type.select(0)
    _update_engine_fields_visibility()

func _save_event_from_form() -> void:
    var type_code := str(event_type.get_item_metadata(event_type.selected))
    var title := event_title.text.strip_edges()
    if title == "":
        title = event_type.get_item_text(event_type.selected)
    var event := {
        "type": type_code,
        "title": title,
        "date": "" if event_date_unknown.button_pressed else event_date.text.strip_edges(),
        "date_unknown": event_date_unknown.button_pressed,
        "mileage": 0 if event_mileage_unknown.button_pressed else int(event_mileage.value),
        "mileage_unknown": event_mileage_unknown.button_pressed,
        "cost": float(event_cost.value),
        "labor_cost": float(event_labor_cost.value),
        "notes": event_notes.text.strip_edges()
    }
    if event_part_id != "":
        event["part_id"] = event_part_id
    if type_code == "engine_replacement":
        event["engine_code"] = engine_code.text.strip_edges()
        event["engine_initial_mileage"] = 0 if engine_initial_mileage_unknown.button_pressed else int(engine_initial_mileage.value)
        event["engine_initial_mileage_unknown"] = engine_initial_mileage_unknown.button_pressed
    if event_editing_id == "":
        ServiceHistoryService.add_event(event)
    else:
        ServiceHistoryService.update_event(event_editing_id, event)
    if type_code == "engine_replacement":
        VehicleService.update_vehicle({"engine_replacement_known": true})
    _clear_event_form()

func _show_event_details(event: Dictionary) -> void:
    var sheet := _create_sheet_popup(str(event.get("title", "Событие")), Vector2i(400, 620))
    var dialog := sheet["popup"] as PopupPanel
    var box := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    var meta := Label.new()
    meta.text = "%s\n%s" % [_event_date_text(event), _event_mileage_text(event)]
    meta.add_theme_color_override("font_color", Color("9ba6b2"))
    box.add_child(meta)

    var event_type_label := Label.new()
    event_type_label.text = "Тип: %s" % _event_type_text(str(event.get("type", "other")))
    box.add_child(event_type_label)

    var total := float(event.get("cost", 0.0)) + float(event.get("labor_cost", 0.0))
    if total > 0.0:
        var cost_label := Label.new()
        cost_label.text = "Стоимость: %s руб." % _format_money(total)
        box.add_child(cost_label)

    if str(event.get("part_id", "")).strip_edges() != "":
        var part_label := Label.new()
        part_label.text = "Связанная деталь: %s" % str(event.get("part_id", ""))
        box.add_child(part_label)

    if str(event.get("notes", "")).strip_edges() != "":
        var notes_title := Label.new()
        notes_title.text = "Комментарий"
        notes_title.add_theme_font_size_override("font_size", 18)
        box.add_child(notes_title)
        var notes := Label.new()
        notes.text = str(event.get("notes", ""))
        notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        notes.add_theme_color_override("font_color", Color("c9d9df"))
        box.add_child(notes)

    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    root.add_child(actions)
    var close := Button.new()
    close.text = "Закрыть"
    close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    close.pressed.connect(func(): dialog.hide())
    actions.add_child(close)
    var edit_btn := Button.new()
    edit_btn.text = "Редактировать"
    edit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_primary_button(edit_btn)
    edit_btn.pressed.connect(func():
        dialog.hide()
        _edit_event(event)
    )
    actions.add_child(edit_btn)

    _show_sheet_popup(sheet, Vector2i(400, 620))

func _copy_backup_to_clipboard() -> void:
    DisplayServer.clipboard_set(Storage.export_transfer_text())
    _show_info_dialog("Копия для переноса готова", "Данные машины помещены в буфер обмена. Сохрани этот длинный текст вне приложения — например, в заметках или сообщении себе. Он позволит перенести историю в другую установку Yeti Garage или восстановить её после переустановки.\n\nКопия содержит VIN и историю автомобиля — не публикуй её в открытом доступе.")

func _confirm_import_from_clipboard() -> void:
    var raw := DisplayServer.clipboard_get().strip_edges()
    if raw == "":
        _show_info_dialog("Буфер пуст", "Скопируй текст резервной копии Yeti Garage и попробуй ещё раз.")
        return
    var info: Dictionary = Storage.inspect_transfer_text(raw)
    if info.is_empty():
        _show_info_dialog("Не похоже на копию Yeti Garage", "В буфере нет корректной переносимой копии автомобиля.")
        return
    var mileage_text := "не указан" if int(info.get("mileage", 0)) <= 0 else "%s км" % _format_int(int(info.get("mileage", 0)))
    var body := "%s\nVIN: %s\nПробег: %s\nЗаписей истории: %s\n\nТекущие данные этой установки сначала сохранятся в локальную резервную копию." % [str(info.get("vehicle_name", "Автомобиль")), str(info.get("vin", "—")), mileage_text, str(info.get("events", 0))]
    _open_confirm_popup(
        "Перенести данные этой машины?",
        body,
        "Перенести",
        func():
            var ok := Storage.import_transfer_text(raw)
            _show_info_dialog("Готово" if ok else "Ошибка", "Данные машины перенесены в эту установку." if ok else "Не удалось восстановить данные из этой копии.")
    )

func _show_info_dialog(title_text: String, body_text: String) -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(350), 0)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)
    var title_row := HBoxContainer.new()
    box.add_child(title_row)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 20)
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)
    var body := Label.new()
    body.text = body_text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 14)
    body.add_theme_color_override("font_color", Color("c6d7de"))
    box.add_child(body)
    var ok := Button.new()
    ok.text = "Понятно"
    _style_primary_button(ok)
    ok.pressed.connect(func(): popup.hide())
    box.add_child(ok)
    _apply_touch_targets(popup)
    popup.popup_centered(_mobile_dialog_size(Vector2i(370, 300)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _open_confirm_popup(title_text: String, body_text: String, confirm_text: String, on_confirm: Callable, destructive: bool = false) -> void:
    var popup := PopupPanel.new()
    popup.transparent_bg = true
    add_child(popup)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(_mobile_dialog_content_width(350), 0)
    panel.add_theme_stylebox_override("panel", _style_box(Color("07141df7"), 22, Color("1b4a55"), 1, Color("00dfe81f"), 2))
    popup.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)
    var title_row := HBoxContainer.new()
    box.add_child(title_row)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 20)
    title_row.add_child(title)
    var close := _popup_close_button()
    close.pressed.connect(func(): popup.hide())
    title_row.add_child(close)
    var body := Label.new()
    body.text = body_text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_theme_font_size_override("font_size", 14)
    body.add_theme_color_override("font_color", Color("c6d7de"))
    box.add_child(body)
    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    box.add_child(actions)
    var cancel := Button.new()
    cancel.text = "Отмена"
    cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel.pressed.connect(func(): popup.hide())
    actions.add_child(cancel)
    var confirm := Button.new()
    confirm.text = confirm_text
    confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_primary_button(confirm)
    if destructive:
        confirm.add_theme_stylebox_override("normal", _style_box(Color("4b2026"), 16, Color("b95b66"), 1))
        confirm.add_theme_stylebox_override("pressed", _style_box(Color("63272f"), 16, Color("e47a83"), 1))
    confirm.pressed.connect(func():
        popup.hide()
        if on_confirm.is_valid():
            on_confirm.call()
    )
    actions.add_child(confirm)
    _apply_touch_targets(popup)
    popup.popup_centered(_mobile_dialog_size(Vector2i(380, 330)))
    popup.popup_hide.connect(func(): popup.queue_free())

func _create_manual_backup() -> void:
    var ok: bool = Storage.create_manual_backup()
    _show_info_dialog("Локальная резервная копия", "Копия текущих данных сохранена на этом устройстве." if ok else "Не удалось создать резервную копию.")

func _confirm_restore_manual_backup() -> void:
    if not Storage.has_manual_backup():
        _show_info_dialog("Локальная резервная копия", "Локальной резервной копии пока нет.")
        return
    var restore_action := func():
        var ok := Storage.restore_manual_backup()
        _show_info_dialog("Готово" if ok else "Ошибка", "Локальная резервная копия восстановлена." if ok else "Не удалось восстановить локальную резервную копию.")
    _open_confirm_popup(
        "Восстановить локальную копию?",
        "Текущие данные будут заменены содержимым последней локальной резервной копии.",
        "Восстановить",
        restore_action,
        true
    )

func _open_part_replacement(part_id: String, part_name: String) -> void:
    _clear_event_form()
    event_part_id = part_id
    _select_type("part_replacement")
    event_title.text = "Замена: %s" % part_name
    event_mileage.value = MileageService.current_mileage()
    event_dialog_title.text = "Замена детали"
    if event_dialog_scroll != null:
        event_dialog_scroll.scroll_vertical = 0
    _apply_touch_targets(event_dialog)
    event_dialog.popup_centered(_mobile_dialog_size(Vector2i(400, 780)))

func _show_part_history(part_id: String, part_name: String) -> void:
    var sheet := _create_sheet_popup("История детали", Vector2i(400, 560))
    var dialog := sheet["popup"] as PopupPanel
    var box := sheet["content"] as VBoxContainer
    var root := sheet["root"] as VBoxContainer

    var heading := Label.new()
    heading.text = part_name
    heading.add_theme_font_size_override("font_size", 20)
    heading.add_theme_color_override("font_color", Color("eef8fa"))
    box.add_child(heading)

    var found := 0
    for event in ServiceHistoryService.events():
        if str(event.get("part_id", "")) != part_id:
            continue
        found += 1
        var card := _glass_card(box)
        var entry := Label.new()
        entry.text = "%s • %s\n%s" % [_event_date_text(event), event.get("title", "Событие"), _event_mileage_text(event)]
        entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.add_child(entry)
    if found == 0:
        var empty := Label.new()
        empty.text = "По этой детали пока нет записей. После первой замены история появится здесь."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.add_theme_color_override("font_color", Color("8793a1"))
        box.add_child(empty)

    var close := Button.new()
    close.text = "Закрыть"
    _style_primary_button(close)
    close.pressed.connect(func(): dialog.hide())
    root.add_child(close)
    _show_sheet_popup(sheet, Vector2i(400, 560))

func _mark_maintenance_done(item: Dictionary) -> void:
    var current := MileageService.current_mileage()
    if current <= 0:
        _open_mileage_dialog()
        return
    _open_confirm_popup(
        "Отметить выполненным?",
        "%s\nПробег: %s км\n\nВ историю будет добавлена запись с сегодняшней датой. Стоимость можно дописать позже." % [str(item.get("title", "Обслуживание")), _format_int(current)],
        "Отметить",
        func(): _commit_maintenance_done(item, current)
    )

func _commit_maintenance_done(item: Dictionary, current: int) -> void:
    ServiceHistoryService.add_event({
        "type": str(item.get("event_type", "maintenance")),
        "title": str(item.get("title", "Обслуживание")),
        "date": Time.get_date_string_from_system(),
        "mileage": current,
        "cost": 0.0,
        "labor_cost": 0.0,
        "notes": "Отмечено как выполненное в плане обслуживания"
    })

func _confirm_delete(id: String) -> void:
    _open_confirm_popup(
        "Удалить запись?",
        "Запись будет удалена из истории. Это действие нельзя отменить.",
        "Удалить",
        func(): ServiceHistoryService.delete_event(id),
        true
    )

func _apply_touch_targets(node: Node) -> void:
    if node is ScrollContainer and str(node.name) == "3D" and not mobile_technical_catalog:
        return
    if vehicle_3d_view != null and node == vehicle_3d_view and not mobile_technical_catalog:
        return
    if node is ScrollContainer:
        var scroll := node as ScrollContainer
        scroll.scroll_deadzone = 10
        scroll.follow_focus = true
        ScrollGesture.attach(scroll)
        scroll.mouse_filter = Control.MOUSE_FILTER_STOP
        if not bool(scroll.get_meta("preserve_scroll_modes", false)):
            scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
            scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        var vbar := scroll.get_v_scroll_bar()
        if vbar != null:
            vbar.modulate = Color(1, 1, 1, 0)
            vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var hbar := scroll.get_h_scroll_bar()
        if hbar != null:
            hbar.modulate = Color(1, 1, 1, 0)
            hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if node is Button and not (node is CheckBox) and not (node is OptionButton):
        var button := node as Button
        if bool(button.get_meta("compact_icon_button", false)):
            # Compact icon actions must stay square; the previous global 48px height
            # rule turned 42x42 circles into 42x48 pills on Android.
            var side := max(max(button.custom_minimum_size.x, button.custom_minimum_size.y), 48.0)
            button.custom_minimum_size = Vector2(side, side)
        else:
            button.custom_minimum_size.y = max(button.custom_minimum_size.y, 48.0)
        button.mouse_filter = Control.MOUSE_FILTER_PASS
        button.autowrap_mode = TextServer.AUTOWRAP_OFF if node.get_parent() is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
        button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        if not button.has_theme_stylebox_override("normal"):
            button.add_theme_stylebox_override("normal", _style_box(Color("0a1d27e8"), 14, Color("194956"), 1))
            button.add_theme_stylebox_override("hover", _style_box(Color("0b2c36f2"), 14, Color("1edee6"), 1, Color("00e7e74b"), 5))
            button.add_theme_stylebox_override("pressed", _style_box(Color("07343def"), 14, Color("28f2f1"), 1, Color("00efef65"), 7))
            button.add_theme_color_override("font_color", Color("eaf7fa"))
            button.add_theme_color_override("font_hover_color", Color("ffffff"))
            button.add_theme_color_override("font_pressed_color", Color("dfffff"))
    elif node is LineEdit:
        var edit := node as LineEdit
        edit.custom_minimum_size.y = max(edit.custom_minimum_size.y, 48.0)
        edit.mouse_filter = Control.MOUSE_FILTER_PASS
        if not edit.has_theme_stylebox_override("normal"):
            edit.add_theme_stylebox_override("normal", _style_box(Color("071923ed"), 14, Color("194753"), 1))
            edit.add_theme_stylebox_override("focus", _style_box(Color("071923f7"), 14, Color("22e8eb"), 2, Color("00e8e83b"), 4))
            edit.add_theme_color_override("font_color", Color("edf8fa"))
            edit.add_theme_color_override("font_placeholder_color", Color("6f8793"))
    elif node is TextEdit:
        var text_edit := node as TextEdit
        text_edit.mouse_filter = Control.MOUSE_FILTER_PASS
        if not text_edit.has_theme_stylebox_override("normal"):
            text_edit.add_theme_stylebox_override("normal", _style_box(Color("071923ed"), 14, Color("194753"), 1))
            text_edit.add_theme_stylebox_override("focus", _style_box(Color("071923f7"), 14, Color("22e8eb"), 2, Color("00e8e83b"), 4))
            text_edit.add_theme_color_override("font_color", Color("edf8fa"))
            text_edit.add_theme_color_override("font_placeholder_color", Color("6f8793"))
    elif node is OptionButton or node is SpinBox:
        var control := node as Control
        if control != null:
            control.custom_minimum_size.y = max(control.custom_minimum_size.y, 48.0)
            control.mouse_filter = Control.MOUSE_FILTER_PASS
        if node is OptionButton:
            var selector := node as OptionButton
            selector.fit_to_longest_item = false
            selector.clip_text = true
            selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    elif node is CheckBox:
        var check := node as CheckBox
        check.custom_minimum_size.y = max(check.custom_minimum_size.y, 44.0)
        check.mouse_filter = Control.MOUSE_FILTER_PASS
        check.add_theme_color_override("font_color", Color("d7e6ea"))
    elif node is Label or node is TextureRect or node is ColorRect or node is HSeparator or node is VSeparator:
        var passive := node as Control
        if node is Label and (not (node.get_parent() is HBoxContainer) or (node.size_flags_horizontal & Control.SIZE_EXPAND) != 0):
            (node as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        if passive != null:
            passive.mouse_filter = Control.MOUSE_FILTER_IGNORE
    elif (node is Container or node is Panel) and not (node is ScrollContainer):
        # Layout/decorative containers must not sit on top of full-card buttons.
        # PASS here made the home dashboard look correct but swallowed taps on Android.
        var passthrough := node as Control
        if passthrough != null:
            passthrough.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for child in node.get_children():
        _apply_touch_targets(child)

func _clear_children_after(node: Node, keep_count: int) -> void:
    for index in range(node.get_child_count() - 1, keep_count - 1, -1):
        var child := node.get_child(index)
        node.remove_child(child)
        child.queue_free()

func _clear_children(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

func _event_date_text(event: Dictionary) -> String:
    if bool(event.get("date_unknown", false)) or str(event.get("date", "")).strip_edges() == "":
        return "Дата неизвестна"
    return _display_date(str(event.get("date", "")))

func _display_date(value: String) -> String:
    var clean := value.strip_edges()
    var parts := clean.split("-")
    if parts.size() == 3 and parts[0].length() == 4:
        return "%s.%s.%s" % [parts[2], parts[1], parts[0]]
    return clean

func _event_mileage_text(event: Dictionary) -> String:
    if bool(event.get("mileage_unknown", false)) or int(event.get("mileage", 0)) <= 0:
        return "Пробег неизвестен"
    return "%s км" % _format_int(int(event.get("mileage", 0)))

func _mileage_source_text(source: String) -> String:
    match source:
        "manual": return "вручную"
        "demo": return "демо"
        "import": return "импорт"
        _: return source if source != "" else "запись"

func _event_type_text(code: String) -> String:
    var names := {
        "maintenance":"Обслуживание",
        "engine_oil":"Замена масла двигателя",
        "oil_filter":"Замена масляного фильтра",
        "air_filter":"Замена воздушного фильтра",
        "coolant":"Замена охлаждающей жидкости",
        "brake_fluid":"Замена тормозной жидкости",
        "repair":"Ремонт",
        "part_replacement":"Замена детали",
        "engine_replacement":"Замена двигателя",
        "diagnostic":"Диагностика",
        "other":"Другое"
    }
    return str(names.get(code, code if code != "" else "Другое"))

func _format_int(value: int) -> String:
    var s := str(abs(value))
    var out := ""
    while s.length() > 3:
        out = " " + s.substr(s.length() - 3, 3) + out
        s = s.substr(0, s.length() - 3)
    out = s + out
    return ("-" if value < 0 else "") + out

func _format_money(value: float) -> String:
    return _format_int(int(round(value)))
