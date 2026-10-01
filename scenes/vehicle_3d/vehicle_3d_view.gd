extends VBoxContainer

signal replacement_requested(part_id: String, part_name: String)
signal history_requested(part_id: String, part_name: String)
signal repair_requested(part_id: String, part_name: String)
signal diagnostic_requested(part_id: String, part_name: String)
signal manual_requested(part_id: String, part_name: String)

const ServiceHistoryService = preload("res://services/service_history_service.gd")
const MileageService = preload("res://services/mileage_service.gd")
const PartCatalogService = preload("res://services/part_catalog_service.gd")

const CYAN := Color("20e7eb")
const TEXT := Color("edf8fa")
const MUTED := Color("8da4b1")
const PANEL := Color("071923ee")
const PANEL_2 := Color("091f29f4")
const BORDER := Color("184955")

const DETAILED_PARTS := {
    "wheel": {"description":"Колесо передаёт усилие автомобиля на дорогу и закрывает тормозной узел."},
    "brake_disc": {"description":"Диск вращается вместе с колесом. При торможении колодки сжимают его с двух сторон."},
    "brake_caliper": {"description":"Суппорт прижимает тормозные колодки к диску. Проверяются направляющие, поршень и отсутствие утечек."},
    "brake_pads": {"description":"Фрикционные накладки, которые прижимаются к тормозному диску. Для них уже есть связь с пошаговой заменой."},
    "brake_hose": {"description":"Гибкий тормозной шланг подаёт давление к суппорту и должен оставаться герметичным при ходе подвески и повороте колеса."},
    "hub": {"description":"Ступица соединяет колесо с поворотным узлом и вращается вместе с колесом."},
    "wheel_bearing": {"description":"Ступичный подшипник позволяет ступице вращаться и воспринимает нагрузку от колеса."},
    "strut": {"description":"Амортизационная стойка гасит колебания подвески и помогает колесу сохранять контакт с дорогой."},
    "spring": {"description":"Пружина держит вес автомобиля и позволяет подвеске перемещаться вверх и вниз."},
    "control_arm": {"description":"Нижний рычаг задаёт положение колеса относительно кузова и соединяет поворотный узел с подрамником."},
    "ball_joint": {"description":"Шаровая опора соединяет рычаг с поворотным узлом и позволяет подвеске двигаться, а колесу — поворачиваться."},
    "stabilizer_link": {"description":"Стойка стабилизатора передаёт усилие между стабилизатором и подвеской и часто проявляет люфт стуком на неровностях."},
    "tie_rod_end": {"description":"Рулевой наконечник передаёт движение рулевой тяги на поворотный кулак."},
    "steering_tie_rod": {"description":"Рулевая тяга передаёт движение от рулевого механизма к наконечнику."},
    "steering_rack": {"description":"Рулевой механизм преобразует вращение руля в продольное движение рулевых тяг."},
    "cv_joint_outer": {"description":"Наружный ШРУС передаёт крутящий момент на колесо при повороте и ходе подвески."},
    "cv_joint_inner": {"description":"Внутренний ШРУС компенсирует изменение длины привода при работе подвески."},
    "drive_shaft": {"description":"Приводной вал передаёт крутящий момент от коробки к ступичному узлу."}
}

const SYSTEM_FOCUS := {
    "engine": Vector3(1.55, 1.15, 0.0),
    "cooling": Vector3(2.45, 1.02, 0.0),
    "fuel_intake": Vector3(1.35, 1.32, -0.62),
    "exhaust": Vector3(-0.55, 0.48, 0.58),
    "transmission": Vector3(0.45, 0.78, 0.0),
    "drive": Vector3(0.25, 0.42, -0.78),
    "suspension": Vector3(1.92, 0.62, -1.30),
    "steering": Vector3(1.45, 0.78, -0.62),
    "brakes": Vector3(1.95, 0.52, -1.46),
    "electrical": Vector3(1.42, 1.25, 0.70),
    "body": Vector3(0.0, 1.28, 0.0),
    "interior": Vector3(-0.42, 1.75, 0.0),
    "climate": Vector3(0.15, 1.48, 0.15),
    "lighting": Vector3(2.72, 1.20, 0.0),
    "safety": Vector3(-0.50, 1.55, 0.0),
    "wipers_glass": Vector3(0.85, 2.18, 0.0)
}

const SYSTEM_FOCUS_SCALE := {
    "engine": Vector3(1.10, 0.72, 0.90),
    "cooling": Vector3(0.66, 0.82, 1.16),
    "fuel_intake": Vector3(0.95, 0.55, 0.84),
    "exhaust": Vector3(1.45, 0.42, 0.58),
    "transmission": Vector3(0.94, 0.62, 0.82),
    "drive": Vector3(1.34, 0.42, 0.72),
    "suspension": Vector3(0.70, 0.84, 0.54),
    "steering": Vector3(0.90, 0.50, 0.70),
    "brakes": Vector3(0.55, 0.75, 0.52),
    "electrical": Vector3(0.72, 0.50, 0.72),
    "body": Vector3(2.15, 0.95, 1.14),
    "interior": Vector3(1.47, 0.64, 0.94),
    "climate": Vector3(0.84, 0.50, 0.70),
    "lighting": Vector3(0.54, 0.55, 1.14),
    "safety": Vector3(1.50, 0.65, 0.96),
    "wipers_glass": Vector3(1.68, 0.30, 1.10)
}

const ASSEMBLY_FOCUS := {
    "front_left_brake": Vector3(1.9, 0.52, -1.4),
    "front_left_suspension": Vector3(1.6, 0.78, -1.1),
    "front_left_drive": Vector3(0.65, 0.45, -0.8),
    "steering_rack_assembly": Vector3(1.15, 0.66, -0.55),
    "wheels": Vector3(1.9, 0.5, -1.42),
    "engine_long_block": Vector3(1.45, 1.18, 0.0),
    "radiator_pack": Vector3(2.35, 0.95, 0.0),
    "gearbox_clutch": Vector3(0.55, 0.78, 0.1),
    "hvac_box": Vector3(0.25, 1.28, 0.0),
    "dashboard": Vector3(-0.2, 1.5, 0.0),
    "front_lighting": Vector3(2.65, 1.1, 0.0),
    "rear_lighting": Vector3(-2.65, 1.1, 0.0),
    "front_wiper_system": Vector3(0.9, 2.1, 0.0),
    "rear_wiper_system": Vector3(-2.3, 2.05, 0.0),
    "timing_assembly": Vector3(1.8, 1.35, -0.4),
    "lubrication": Vector3(1.25, 0.62, 0.0),
    "intake": Vector3(1.15, 1.5, -0.6),
    "coolant_circuit": Vector3(1.8, 0.95, 0.25),
    "selector": Vector3(0.3, 0.8, 0.15),
    "steering_column_assembly": Vector3(0.45, 1.45, -0.35),
    "seats": Vector3(-0.65, 1.0, 0.0),
    "center_console": Vector3(-0.1, 1.15, 0.0),
    "ac_circuit": Vector3(1.6, 1.0, 0.2),
    "cabin_electrical": Vector3(-0.6, 1.45, 0.2),
    "front_body": Vector3(2.35, 0.92, 0.0),
    "doors": Vector3(-0.4, 1.2, 1.0),
    "rear_body": Vector3(-2.25, 1.15, 0.0),
    "passive_safety": Vector3(-0.45, 1.55, 0.0)
}

var viewport_container: SubViewportContainer
var subviewport: SubViewport
var world_root: Node3D
var vehicle_root: Node3D
var assembly_root: Node3D
var camera: Camera3D
var system_marker: Node3D

var header_block: Control
var selectors_panel: Control
var selected_card: Control
var stage_shell: PanelContainer
var system_selector: Button
var assembly_selector: Button
var part_selector: Button
var selector_popup: PopupPanel
var selector_list: VBoxContainer
var selector_scroll: ScrollContainer
var selector_level := "system"
var explode_button: Button
var xray_button: Button
var isolate_button: Button
var expand_button: Button
var hide_selected_button: Button
var selected_name: Label
var selected_status: Label
var selected_description: Label
var selected_history: Label

var selected_system := ""
var selected_assembly := ""
var last_rendered_assembly := ""
var selected_id := ""
var selected_part_name := ""
var view_mode := "vehicle"
var exploded := false
var xray_mode := false
var isolate_mode := false
var expanded_stage := false
var hidden_parts: Dictionary = {}
var parts: Dictionary = {}
var vehicle_meshes: Array = []

var drag_distance := 0.0
var pointer_down := false
var last_pointer := Vector2.ZERO
var touch_points: Dictionary = {}
var page_scroll: ScrollContainer
var page_pointer_down := false
var page_drag_distance := 0.0
var page_touch_actions: Dictionary = {}

func _ready() -> void:
    add_theme_constant_override("separation", 10)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _build_controls()
    _build_3d()
    _show_vehicle_overview()
    call_deferred("_prepare_page_touch_routing")

func _exit_tree() -> void:
    if selector_popup != null and is_instance_valid(selector_popup):
        selector_popup.queue_free()

func _build_controls() -> void:
    header_block = VBoxContainer.new()
    header_block.add_theme_constant_override("separation", 3)
    add_child(header_block)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    header_block.add_child(title_row)

    var heading := VBoxContainer.new()
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_constant_override("separation", 1)
    title_row.add_child(heading)

    var title := Label.new()
    title.text = "3D-узлы ŠKODA Yeti"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", TEXT)
    heading.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Автомобиль → система → узел → деталь"
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", MUTED)
    heading.add_child(subtitle)

    var count_badge := PanelContainer.new()
    count_badge.custom_minimum_size = Vector2(82, 48)
    count_badge.add_theme_stylebox_override("panel", _style_box(Color("082b35e8"), 14, Color("16717b"), 1))
    title_row.add_child(count_badge)
    var count_label := Label.new()
    count_label.text = "%d систем\n%d деталей" % [PartCatalogService.SYSTEMS.size(), PartCatalogService.PARTS.size()]
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    count_label.add_theme_font_size_override("font_size", 11)
    count_label.add_theme_color_override("font_color", Color("bceff1"))
    count_badge.add_child(count_label)

    selectors_panel = PanelContainer.new()
    selectors_panel.add_theme_stylebox_override("panel", _style_box(Color("071820d8"), 16, BORDER, 1))
    add_child(selectors_panel)
    var selectors_margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        selectors_margin.add_theme_constant_override("margin_" + side, 10)
    selectors_panel.add_child(selectors_margin)
    var selectors := VBoxContainer.new()
    selectors.add_theme_constant_override("separation", 6)
    selectors_margin.add_child(selectors)
    system_selector = _button("Система  ▾", func(): _open_selector("system"))
    assembly_selector = _button("Узел  ▾", func(): _open_selector("assembly"))
    part_selector = _button("Деталь  ▾", func(): _open_selector("part"))
    selectors.add_child(system_selector)
    selectors.add_child(assembly_selector)
    selectors.add_child(part_selector)
    _create_selector_popup()

    stage_shell = PanelContainer.new()
    stage_shell.add_theme_stylebox_override("panel", _style_box(Color("050d13f8"), 22, Color("15505c"), 1, Color("00e7e72a"), 6))
    add_child(stage_shell)

    viewport_container = SubViewportContainer.new()
    viewport_container.custom_minimum_size = Vector2(0, 440)
    viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_container.stretch = true
    viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
    viewport_container.gui_input.connect(_on_viewport_input)
    stage_shell.add_child(viewport_container)

    subviewport = SubViewport.new()
    subviewport.size = Vector2i(860, 880)
    subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    subviewport.own_world_3d = true
    subviewport.physics_object_picking = true
    subviewport.transparent_bg = false
    viewport_container.add_child(subviewport)

    var gesture_hint := Label.new()
    gesture_hint.text = "1 палец — вращение   •   2 пальца — масштаб   •   тап — деталь"
    gesture_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gesture_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    gesture_hint.add_theme_font_size_override("font_size", 12)
    gesture_hint.add_theme_color_override("font_color", Color("78909c"))
    add_child(gesture_hint)

    var toolbar := GridContainer.new()
    toolbar.columns = 3
    toolbar.add_theme_constant_override("h_separation", 7)
    toolbar.add_theme_constant_override("v_separation", 7)
    add_child(toolbar)

    explode_button = _button("Разобрать", _toggle_exploded)
    xray_button = _button("Рентген", _toggle_xray)
    isolate_button = _button("Изолировать", _toggle_isolate)
    toolbar.add_child(explode_button)
    toolbar.add_child(xray_button)
    toolbar.add_child(isolate_button)
    toolbar.add_child(_button("Показать всё", _show_all))
    toolbar.add_child(_button("Сброс ракурса", _reset_view))
    expand_button = _button("Развернуть", _toggle_expanded_stage)
    toolbar.add_child(expand_button)

    selected_card = PanelContainer.new()
    selected_card.add_theme_stylebox_override("panel", _style_box(PANEL_2, 18, BORDER, 1))
    add_child(selected_card)
    var card_margin := MarginContainer.new()
    card_margin.add_theme_constant_override("margin_left", 14)
    card_margin.add_theme_constant_override("margin_right", 14)
    card_margin.add_theme_constant_override("margin_top", 13)
    card_margin.add_theme_constant_override("margin_bottom", 13)
    selected_card.add_child(card_margin)
    var card := VBoxContainer.new()
    card.add_theme_constant_override("separation", 7)
    card_margin.add_child(card)

    selected_name = Label.new()
    selected_name.add_theme_font_size_override("font_size", 21)
    selected_name.add_theme_color_override("font_color", TEXT)
    selected_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(selected_name)

    selected_status = Label.new()
    selected_status.add_theme_font_size_override("font_size", 12)
    selected_status.add_theme_color_override("font_color", CYAN)
    selected_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(selected_status)

    selected_description = Label.new()
    selected_description.add_theme_font_size_override("font_size", 14)
    selected_description.add_theme_color_override("font_color", Color("c5d2d8"))
    selected_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(selected_description)

    selected_history = Label.new()
    selected_history.add_theme_font_size_override("font_size", 12)
    selected_history.add_theme_color_override("font_color", MUTED)
    selected_history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(selected_history)

    var actions := GridContainer.new()
    actions.columns = 2
    actions.add_theme_constant_override("h_separation", 8)
    actions.add_theme_constant_override("v_separation", 8)
    card.add_child(actions)
    actions.add_child(_button("Проверка", _request_diagnostic))
    actions.add_child(_button("Пошаговый ремонт", _request_repair))
    actions.add_child(_button("История детали", _request_history))
    actions.add_child(_button("Руководство", _request_manual))
    actions.add_child(_button("Записать замену", _request_replacement))
    hide_selected_button = _button("Скрыть деталь", _hide_selected)
    hide_selected_button.disabled = true
    actions.add_child(hide_selected_button)

func _build_3d() -> void:
    world_root = Node3D.new()
    subviewport.add_child(world_root)

    # Make the viewport renderable before constructing any procedural meshes.
    # A runtime error in one decorative part must not leave this viewport without
    # a current camera and turn the whole 3D stage black.
    camera = Camera3D.new()
    camera.fov = 46.0
    camera.near = 0.05
    camera.far = 100.0
    camera.position = Vector3(8.7, 4.0, 9.2)
    world_root.add_child(camera)
    camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
    camera.make_current()

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("061018")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("7c9caf")
    env.ambient_light_energy = 0.62
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    world_root.add_child(environment)

    var key_light := DirectionalLight3D.new()
    key_light.rotation_degrees = Vector3(-48, -32, 0)
    key_light.light_color = Color("dcefff")
    key_light.light_energy = 1.8
    world_root.add_child(key_light)

    var rim := OmniLight3D.new()
    rim.position = Vector3(-4.0, 4.0, -4.5)
    rim.light_color = Color("31dce2")
    rim.omni_range = 13.0
    rim.light_energy = 4.5
    world_root.add_child(rim)

    var fill := OmniLight3D.new()
    fill.position = Vector3(4.5, 3.0, 5.5)
    fill.light_color = Color("dce8f1")
    fill.omni_range = 15.0
    fill.light_energy = 2.1
    world_root.add_child(fill)

    _build_vehicle_context()
    _build_front_left_assembly()
    _build_system_marker()

func _build_vehicle_context() -> void:
    vehicle_root = Node3D.new()
    vehicle_root.name = "YetiVehicleContext"
    vehicle_root.rotation_degrees = Vector3(-3, -28, 0)
    world_root.add_child(vehicle_root)

    var body_color := Color("25323a")
    var glass_color := Color("0b1b24")
    var trim_color := Color("17252d")
    _add_vehicle_shell(body_color)
    _add_vehicle_box(Vector3(1.82, 0.34, 2.48), Vector3(1.77, 1.34, 0.0), Color("2b3a42"))
    _add_vehicle_box(Vector3(0.46, 0.58, 2.56), Vector3(2.66, 0.99, 0.0), Color("202d35"))
    _add_vehicle_box(Vector3(0.42, 0.66, 2.48), Vector3(-2.60, 0.96, 0.0), Color("202d35"))

    # Tall compact SUV cabin with a roof, angled glass and visible side windows.
    _add_vehicle_box(Vector3(2.88, 1.30, 2.18), Vector3(-0.47, 1.94, 0.0), body_color)
    _add_vehicle_box(Vector3(2.48, 0.18, 2.28), Vector3(-0.48, 2.64, 0.0), Color("303e46"))
    _add_vehicle_ellipsoid(Vector3(0.94, 0.12, 1.18), Vector3(1.78, 1.47, 0.0), Color("304047"))
    _add_vehicle_ellipsoid(Vector3(1.16, 0.10, 1.10), Vector3(-0.48, 2.68, 0.0), Color("35434a"))
    _add_vehicle_box(Vector3(0.10, 0.78, 2.02), Vector3(1.18, 2.03, 0.0), glass_color, 0.08, Vector3(0.0, 0.0, 17.0))
    _add_vehicle_box(Vector3(0.10, 0.76, 2.02), Vector3(-2.03, 2.02, 0.0), glass_color, 0.08, Vector3(0.0, 0.0, -13.0))
    for side in [-1.0, 1.0]:
        var side_z: float = float(side) * 1.105
        _add_vehicle_box(Vector3(1.08, 0.72, 0.075), Vector3(0.25, 2.02, side_z), glass_color, 0.08)
        _add_vehicle_box(Vector3(1.02, 0.72, 0.075), Vector3(-1.12, 2.02, side_z), glass_color, 0.08)
        _add_vehicle_box(Vector3(0.11, 1.02, 0.10), Vector3(0.91, 1.99, side * 1.06), Color("35434b"))
        _add_vehicle_box(Vector3(0.11, 1.02, 0.10), Vector3(-0.53, 1.99, side * 1.06), Color("35434b"))
        _add_vehicle_box(Vector3(0.10, 0.98, 0.10), Vector3(-1.88, 1.98, side * 1.06), Color("35434b"))
        _add_vehicle_box(Vector3(0.38, 0.20, 0.28), Vector3(1.22, 1.73, side * 1.34), Color("26343c"))
        _add_vehicle_box(Vector3(2.55, 0.08, 0.12), Vector3(-0.50, 2.78, side * 0.78), Color("82919a"))
        _add_vehicle_box(Vector3(0.035, 0.72, 0.025), Vector3(0.48, 1.16, side * 1.13), Color("17262d"))
        _add_vehicle_box(Vector3(0.035, 0.72, 0.025), Vector3(-1.38, 1.16, side * 1.13), Color("17262d"))
        _add_vehicle_box(Vector3(0.24, 0.045, 0.035), Vector3(-0.38, 1.50, side * 1.15), Color("85939a"))
        _add_vehicle_box(Vector3(2.48, 0.18, 0.18), Vector3(-0.02, 0.55, side * 1.25), Color("202d34"))
        _add_vehicle_ellipsoid(Vector3(0.78, 0.42, 0.095), Vector3(-1.92, 0.91, side * 1.27), Color("1c292f"))
        _add_vehicle_ellipsoid(Vector3(0.78, 0.42, 0.095), Vector3(1.92, 0.91, side * 1.27), Color("1c292f"))
        _add_vehicle_ellipsoid(Vector3(0.18, 0.12, 0.16), Vector3(1.38, 1.78, side * 1.43), Color("36464e"))
        _add_vehicle_box(Vector3(0.34, 0.045, 0.06), Vector3(0.08, 1.54, side * 1.20), Color("87949a"))
        _add_vehicle_box(Vector3(0.34, 0.045, 0.06), Vector3(-1.43, 1.54, side * 1.20), Color("87949a"))
        _add_vehicle_ellipsoid(Vector3(0.28, 0.045, 0.025), Vector3(-0.32, 0.83, side * 1.286), Color("89979d"))
        _add_vehicle_ellipsoid(Vector3(0.28, 0.045, 0.025), Vector3(-1.45, 0.83, side * 1.286), Color("89979d"))

    _add_vehicle_box(Vector3(0.10, 0.72, 1.62), Vector3(2.91, 0.99, 0.0), trim_color)
    _add_vehicle_box(Vector3(0.16, 0.32, 1.42), Vector3(2.98, 0.92, 0.0), Color("10191f"))
    for grille_bar in range(3):
        _add_vehicle_box(Vector3(0.035, 0.035, 1.12), Vector3(3.075, 0.82 + float(grille_bar) * 0.10, 0.0), Color("52616a"))
    _add_vehicle_ellipsoid(Vector3(0.055, 0.09, 0.12), Vector3(3.09, 1.06, 0.0), Color("9eb4bb"), 0.25)
    _add_vehicle_ellipsoid(Vector3(0.10, 0.17, 0.27), Vector3(2.84, 1.34, -0.87), Color("c0e7e9"), 0.8)
    _add_vehicle_ellipsoid(Vector3(0.10, 0.17, 0.27), Vector3(2.84, 1.34, 0.87), Color("c0e7e9"), 0.8)
    _add_vehicle_ellipsoid(Vector3(0.09, 0.10, 0.14), Vector3(2.91, 0.76, -0.88), Color("91c9cc"), 0.35)
    _add_vehicle_ellipsoid(Vector3(0.09, 0.10, 0.14), Vector3(2.91, 0.76, 0.88), Color("91c9cc"), 0.35)
    _add_vehicle_ellipsoid(Vector3(0.08, 0.22, 0.17), Vector3(-2.81, 1.22, -0.99), Color("9c4144"), 0.45)
    _add_vehicle_ellipsoid(Vector3(0.08, 0.22, 0.17), Vector3(-2.81, 1.22, 0.99), Color("9c4144"), 0.45)
    _add_vehicle_box(Vector3(0.18, 0.32, 2.62), Vector3(2.78, 0.69, 0.0), Color("303d44"))
    _add_vehicle_box(Vector3(0.18, 0.32, 2.58), Vector3(-2.79, 0.70, 0.0), Color("303d44"))

    for x in [-1.92, 1.92]:
        for z in [-1.47, 1.47]:
            _add_vehicle_wheel(Vector3(x, 0.47, z))

    for x in [-1.92, 1.92]:
        for z in [-1.31, 1.31]:
            _add_vehicle_box(Vector3(1.32, 0.16, 0.12), Vector3(x, 0.68, z), Color("1a272e"))

func _add_vehicle_shell(color: Color) -> void:
    # A lightly tapered, chamfered eight-point body section avoids the single
    # rectangular slab silhouette while keeping the SUV shell inexpensive.
    var stations := [
        {"x":-2.95, "bottom":0.72, "top":1.10, "half_width":0.92},
        {"x":-2.70, "bottom":0.59, "top":1.35, "half_width":1.22},
        {"x":-2.25, "bottom":0.56, "top":1.48, "half_width":1.28},
        {"x":1.85, "bottom":0.56, "top":1.46, "half_width":1.28},
        {"x":2.50, "bottom":0.62, "top":1.31, "half_width":1.22},
        {"x":2.95, "bottom":0.78, "top":1.08, "half_width":0.92}
    ]
    var rings: Array[PackedVector3Array] = []
    for station_value in stations:
        var station: Dictionary = station_value
        var y0 := float(station["bottom"])
        var y1 := float(station["top"])
        var half_width := float(station["half_width"])
        var corner := minf(0.22, minf(half_width * 0.28, (y1 - y0) * 0.30))
        rings.append(PackedVector3Array([
            Vector3(float(station["x"]), y0, -half_width + corner),
            Vector3(float(station["x"]), y0, half_width - corner),
            Vector3(float(station["x"]), y0 + corner, half_width),
            Vector3(float(station["x"]), y1 - corner, half_width),
            Vector3(float(station["x"]), y1, half_width - corner),
            Vector3(float(station["x"]), y1, -half_width + corner),
            Vector3(float(station["x"]), y1 - corner, -half_width),
            Vector3(float(station["x"]), y0 + corner, -half_width)
        ]))
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring_index in range(rings.size() - 1):
        for point_index in range(8):
            var next_point := (point_index + 1) % 8
            var a: Vector3 = rings[ring_index][point_index]
            var b: Vector3 = rings[ring_index + 1][point_index]
            var c: Vector3 = rings[ring_index + 1][next_point]
            var d: Vector3 = rings[ring_index][next_point]
            _add_triangle(surface, a, b, c)
            _add_triangle(surface, a, c, d)
    surface.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.mesh = surface.commit()
    mesh.material_override = _material(color)
    vehicle_root.add_child(mesh)
    vehicle_meshes.append({"mesh":mesh, "color":color, "emission":0.0})

func _add_vehicle_box(size: Vector3, pos: Vector3, color: Color, emission_strength: float = 0.0, rotation: Vector3 = Vector3.ZERO) -> void:
    var mesh_resource := BoxMesh.new()
    mesh_resource.size = size
    var mesh := MeshInstance3D.new()
    mesh.mesh = mesh_resource
    mesh.position = pos
    mesh.rotation_degrees = rotation
    mesh.material_override = _material(color, 1.0, emission_strength)
    vehicle_root.add_child(mesh)
    vehicle_meshes.append({"mesh":mesh, "color":color, "emission":emission_strength})

func _add_vehicle_ellipsoid(radii: Vector3, pos: Vector3, color: Color, emission_strength: float = 0.0) -> void:
    var sphere := SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 16
    sphere.rings = 8
    var mesh := MeshInstance3D.new()
    mesh.mesh = sphere
    mesh.position = pos
    mesh.scale = radii
    mesh.material_override = _material(color, 1.0, emission_strength)
    vehicle_root.add_child(mesh)
    vehicle_meshes.append({"mesh":mesh, "color":color, "emission":emission_strength})

func _add_vehicle_wheel(pos: Vector3) -> void:
    var tire_resource := CylinderMesh.new()
    tire_resource.top_radius = 0.66
    tire_resource.bottom_radius = 0.66
    tire_resource.height = 0.34
    tire_resource.radial_segments = 48
    var tire := MeshInstance3D.new()
    tire.mesh = tire_resource
    tire.position = pos
    tire.rotation_degrees = Vector3(90, 0, 0)
    tire.material_override = _material(Color("101419"))
    vehicle_root.add_child(tire)
    vehicle_meshes.append({"mesh":tire, "color":Color("101419"), "emission":0.0})

    var rim_resource := CylinderMesh.new()
    rim_resource.top_radius = 0.38
    rim_resource.bottom_radius = 0.38
    rim_resource.height = 0.37
    rim_resource.radial_segments = 40
    var rim_mesh := MeshInstance3D.new()
    rim_mesh.mesh = rim_resource
    rim_mesh.position = pos
    rim_mesh.rotation_degrees = Vector3(90, 0, 0)
    rim_mesh.material_override = _material(Color("82919a"))
    vehicle_root.add_child(rim_mesh)
    vehicle_meshes.append({"mesh":rim_mesh, "color":Color("82919a"), "emission":0.0})

    for side in [-1.0, 1.0]:
        var face_z: float = pos.z + float(side) * 0.21
        for spoke_index in range(5):
            var angle := TAU * float(spoke_index) / 5.0
            var spoke_pos := Vector3(pos.x + cos(angle) * 0.18, pos.y + sin(angle) * 0.18, face_z)
            _add_vehicle_box(Vector3(0.11, 0.52, 0.06), spoke_pos, Color("9ba8af"), 0.0, Vector3(0.0, 0.0, rad_to_deg(angle)))
        var hub_mesh := SphereMesh.new()
        hub_mesh.radius = 0.19
        hub_mesh.height = 0.20
        hub_mesh.radial_segments = 16
        hub_mesh.rings = 8
        var hub := MeshInstance3D.new()
        hub.mesh = hub_mesh
        hub.scale = Vector3(1.0, 1.0, 0.36)
        hub.position = Vector3(pos.x, pos.y, face_z)
        hub.material_override = _material(Color("c0cbd0"))
        vehicle_root.add_child(hub)
        vehicle_meshes.append({"mesh":hub, "color":Color("c0cbd0"), "emission":0.0})

func _build_system_marker() -> void:
    system_marker = Node3D.new()
    system_marker.name = "SystemAreaHighlight"
    var volume_material := _material(Color("24e9ed"), 0.12, 0.55)
    for shape in [Vector3(1.0, 0.42, 0.72), Vector3(0.68, 0.60, 0.52)]:
        var volume := MeshInstance3D.new()
        var volume_mesh := BoxMesh.new()
        volume_mesh.size = Vector3.ONE
        volume.mesh = volume_mesh
        volume.scale = shape
        volume.material_override = volume_material
        system_marker.add_child(volume)
    system_marker.visible = false
    vehicle_root.add_child(system_marker)

func _build_front_left_assembly() -> void:
    assembly_root = Node3D.new()
    assembly_root.name = "FrontLeftAssembly"
    assembly_root.rotation_degrees = Vector3(-7, -20, 0)
    assembly_root.visible = false
    world_root.add_child(assembly_root)

    _add_cylinder_part("wheel", 1.42, 0.52, Vector3(0.00, 0.35, 0.0), Vector3(0, 0, 90), Color("20262e"), Vector3(2.25, 0, 0))
    _add_cylinder_part("brake_disc", 0.94, 0.12, Vector3(0.36, 0.35, 0.0), Vector3(0, 0, 90), Color("b7bdc6"), Vector3(1.35, 0, 0))
    _add_cylinder_part("hub", 0.35, 0.28, Vector3(0.47, 0.35, 0.0), Vector3(0, 0, 90), Color("7f8a96"), Vector3(0.72, 0, 0))
    _add_cylinder_part("wheel_bearing", 0.46, 0.18, Vector3(0.27, 0.35, 0.0), Vector3(0, 0, 90), Color("a9b3be"), Vector3(0.95, 0.0, -0.22))
    _add_box_part("brake_caliper", Vector3(0.34, 0.90, 0.48), Vector3(0.43, 0.40, 0.88), Vector3(0, 0, -6), Color("9c3437"), Vector3(1.05, 0.08, 0.48))
    _add_box_part("brake_pads", Vector3(0.22, 0.66, 0.20), Vector3(0.37, 0.40, 0.68), Vector3.ZERO, Color("d49b44"), Vector3(0.78, 0.05, 0.35))
    _add_cylinder_part("brake_hose", 0.055, 1.18, Vector3(-0.02, 0.94, 0.79), Vector3(22, 0, -18), Color("30363d"), Vector3(0.34, 0.50, 0.54))
    _add_cylinder_part("strut", 0.20, 2.55, Vector3(0.15, 2.0, -0.55), Vector3.ZERO, Color("70879f"), Vector3(-0.55, 0.70, -0.65))
    _add_spring_part("spring", Vector3(0.15, 2.12, -0.55), Color("8495a2"), Vector3(-0.85, 0.85, -0.75))
    _add_box_part("control_arm", Vector3(2.1, 0.22, 0.38), Vector3(-0.65, -0.78, -0.32), Vector3(0, -12, -8), Color("54606c"), Vector3(-0.70, -0.55, -0.62))
    _add_sphere_part("ball_joint", 0.30, Vector3(0.28, -0.62, -0.18), Color("94a0ac"), Vector3(0.32, -0.58, -0.22))
    _add_cylinder_part("stabilizer_link", 0.075, 1.38, Vector3(-0.62, 0.23, -0.42), Vector3(8, 0, 12), Color("75828e"), Vector3(-0.55, 0.18, -0.45))
    _add_cylinder_part("tie_rod_end", 0.13, 1.15, Vector3(-0.28, 0.12, -0.80), Vector3(0, 0, 68), Color("697887"), Vector3(-0.72, 0.08, -0.72))
    _add_cylinder_part("steering_tie_rod", 0.085, 1.75, Vector3(-1.20, 0.10, -0.76), Vector3(0, 0, 82), Color("7c8995"), Vector3(-0.90, 0.02, -0.72))
    _add_box_part("steering_rack", Vector3(2.25, 0.22, 0.30), Vector3(-2.22, 0.08, -0.72), Vector3(0, 0, -4), Color("52616d"), Vector3(-0.72, 0.0, -0.62))
    _add_sphere_part("cv_joint_outer", 0.43, Vector3(-0.22, 0.35, 0.0), Color("5d6a76"), Vector3(-1.08, 0.03, 0.0))
    _add_cylinder_part("drive_shaft", 0.12, 2.05, Vector3(-1.18, 0.35, 0.02), Vector3(0, 0, 90), Color("596975"), Vector3(-1.30, -0.15, 0.10))
    _add_sphere_part("cv_joint_inner", 0.46, Vector3(-2.13, 0.35, 0.02), Color("667580"), Vector3(-1.48, -0.12, 0.12))

    # Rounded ends make the selected caliper read as a formed assembly rather than a block.
    var caliper_body: StaticBody3D = parts["brake_caliper"].get("node")
    var caliper_color := Color("9c3437")
    for cap_y in [0.05, 0.75]:
        var cap_mesh := SphereMesh.new()
        cap_mesh.radius = 0.20
        cap_mesh.height = 0.32
        cap_mesh.radial_segments = 16
        cap_mesh.rings = 8
        var cap := MeshInstance3D.new()
        cap.mesh = cap_mesh
        cap.position = Vector3(0.0, cap_y, 0.0)
        cap.material_override = _material(caliper_color)
        caliper_body.add_child(cap)

    var knuckle_mesh := BoxMesh.new()
    knuckle_mesh.size = Vector3(0.34, 1.45, 0.44)
    var knuckle := MeshInstance3D.new()
    knuckle.mesh = knuckle_mesh
    knuckle.position = Vector3(0.05, 0.28, -0.28)
    knuckle.rotation_degrees = Vector3(0, 0, -7)
    knuckle.material_override = _material(Color("46515c"))
    assembly_root.add_child(knuckle)

func _add_box_part(id: String, size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color, explode_offset: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = id
    body.position = pos
    body.rotation_degrees = rot_deg
    body.set_meta("part_id", id)
    assembly_root.add_child(body)
    var mesh_resource := BoxMesh.new()
    mesh_resource.size = size
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = mesh_resource
    mesh_instance.material_override = _material(color)
    body.add_child(mesh_instance)
    var shape_resource := BoxShape3D.new()
    shape_resource.size = size
    var collision := CollisionShape3D.new()
    collision.shape = shape_resource
    body.add_child(collision)
    _register_part(id, body, mesh_instance, pos, pos + explode_offset, color)

func _add_cylinder_part(id: String, radius: float, height: float, pos: Vector3, rot_deg: Vector3, color: Color, explode_offset: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = id
    body.position = pos
    body.rotation_degrees = rot_deg
    body.set_meta("part_id", id)
    assembly_root.add_child(body)
    var mesh_instance := MeshInstance3D.new()
    if id == "brake_disc":
        mesh_instance.mesh = _make_brake_disc_mesh(radius, height, 0.31, 48)
    elif id == "wheel":
        mesh_instance.mesh = _make_brake_disc_mesh(radius, height, 0.89, 40)
    else:
        var mesh_resource := CylinderMesh.new()
        mesh_resource.top_radius = radius
        mesh_resource.bottom_radius = radius
        mesh_resource.height = height
        mesh_resource.radial_segments = 36
        mesh_instance.mesh = mesh_resource
    mesh_instance.material_override = _material(color)
    body.add_child(mesh_instance)
    var shape_resource: Shape3D
    if id in ["brake_disc", "wheel"]:
        var ring_shape := ConcavePolygonShape3D.new()
        ring_shape.set_faces(mesh_instance.mesh.get_faces())
        shape_resource = ring_shape
    else:
        var cylinder_shape := CylinderShape3D.new()
        cylinder_shape.radius = radius
        cylinder_shape.height = height
        shape_resource = cylinder_shape
    var collision := CollisionShape3D.new()
    collision.shape = shape_resource
    body.add_child(collision)
    _register_part(id, body, mesh_instance, pos, pos + explode_offset, color)
    if id == "wheel":
        _add_wheel_face_details(body)
    elif id in ["cv_joint_outer", "cv_joint_inner"]:
        _add_cv_boot_ridges(body, radius)

func _make_brake_disc_mesh(radius: float, height: float, inner_radius: float, segments: int) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half := height * 0.5
    for i in range(segments):
        var a0 := TAU * float(i) / float(segments)
        var a1 := TAU * float(i + 1) / float(segments)
        var outer0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
        var outer1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
        var inner0 := Vector3(cos(a0) * inner_radius, 0.0, sin(a0) * inner_radius)
        var inner1 := Vector3(cos(a1) * inner_radius, 0.0, sin(a1) * inner_radius)
        _add_triangle(surface, Vector3(outer0.x, half, outer0.z), Vector3(inner1.x, half, inner1.z), Vector3(outer1.x, half, outer1.z))
        _add_triangle(surface, Vector3(outer0.x, half, outer0.z), Vector3(inner0.x, half, inner0.z), Vector3(inner1.x, half, inner1.z))
        _add_triangle(surface, Vector3(outer1.x, -half, outer1.z), Vector3(inner1.x, -half, inner1.z), Vector3(outer0.x, -half, outer0.z))
        _add_triangle(surface, Vector3(outer1.x, -half, outer1.z), Vector3(inner0.x, -half, inner0.z), Vector3(inner1.x, -half, inner1.z))
        _add_triangle(surface, Vector3(outer0.x, -half, outer0.z), Vector3(outer0.x, half, outer0.z), Vector3(outer1.x, half, outer1.z))
        _add_triangle(surface, Vector3(outer0.x, -half, outer0.z), Vector3(outer1.x, half, outer1.z), Vector3(outer1.x, -half, outer1.z))
        _add_triangle(surface, Vector3(inner1.x, -half, inner1.z), Vector3(inner0.x, half, inner0.z), Vector3(inner0.x, -half, inner0.z))
        _add_triangle(surface, Vector3(inner1.x, -half, inner1.z), Vector3(inner1.x, half, inner1.z), Vector3(inner0.x, half, inner0.z))
    surface.generate_normals()
    return surface.commit()

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    surface.add_vertex(a)
    surface.add_vertex(b)
    surface.add_vertex(c)

func _add_wheel_face_details(body: StaticBody3D) -> void:
    var rim := MeshInstance3D.new()
    rim.mesh = _make_brake_disc_mesh(0.93, 0.54, 0.63, 32)
    rim.rotation_degrees.z = 90.0
    rim.material_override = _material(Color("65727a"))
    body.add_child(rim)
    var face := MeshInstance3D.new()
    face.mesh = _make_brake_disc_mesh(0.84, 0.06, 0.31, 32)
    face.rotation_degrees.z = 90.0
    face.position.y = 0.28
    face.material_override = _material(Color("aab6bc"))
    body.add_child(face)
    for spoke_index in range(5):
        var spoke := MeshInstance3D.new()
        var spoke_mesh := BoxMesh.new()
        spoke_mesh.size = Vector3(0.09, 0.10, 0.60)
        spoke.mesh = spoke_mesh
        var angle := TAU * float(spoke_index) / 5.0
        spoke.position = Vector3(0.0, 0.31, sin(angle) * 0.32)
        spoke.rotation.y = angle
        spoke.material_override = _material(Color("d1d9dc"))
        body.add_child(spoke)

func _add_cv_boot_ridges(body: StaticBody3D, base_radius: float) -> void:
    for ridge_index in range(5):
        var ridge := MeshInstance3D.new()
        var ridge_mesh := CylinderMesh.new()
        ridge_mesh.top_radius = base_radius * (0.52 if ridge_index in [0, 4] else 0.66)
        ridge_mesh.bottom_radius = ridge_mesh.top_radius
        ridge_mesh.height = 0.10
        ridge_mesh.radial_segments = 20
        ridge.mesh = ridge_mesh
        ridge.rotation_degrees.z = 90.0
        ridge.position.x = -0.22 + float(ridge_index) * 0.11
        ridge.material_override = _material(Color("303943"))
        body.add_child(ridge)

func _add_spring_part(id: String, pos: Vector3, color: Color, explode_offset: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = id
    body.position = pos
    body.set_meta("part_id", id)
    assembly_root.add_child(body)
    # Compatibility-safe low-poly helix tube: one surface, 6 coils and 8-sided
    # cross section rather than a chain of visible spheres.
    var turns := 6.0
    var tube_radius := 0.075
    var coil_radius := 0.34
    var coil_height := 1.14
    var longitudinal_steps := 180
    var radial_steps := 8
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring_index in range(longitudinal_steps + 1):
        var t := float(ring_index) / float(longitudinal_steps)
        var angle := TAU * turns * t
        var center := Vector3(cos(angle) * coil_radius, -coil_height * 0.5 + t * coil_height, sin(angle) * coil_radius)
        var tangent := Vector3(-sin(angle) * coil_radius * TAU * turns, coil_height, cos(angle) * coil_radius * TAU * turns).normalized()
        var radial := Vector3(cos(angle), 0.0, sin(angle)).normalized()
        var binormal := tangent.cross(radial).normalized()
        for side_index in range(radial_steps):
            var side_angle := TAU * float(side_index) / float(radial_steps)
            var point := center + (radial * cos(side_angle) + binormal * sin(side_angle)) * tube_radius
            surface.add_vertex(point)
    for ring_index in range(longitudinal_steps):
        for side_index in range(radial_steps):
            var a := ring_index * radial_steps + side_index
            var b := ring_index * radial_steps + (side_index + 1) % radial_steps
            var c := (ring_index + 1) * radial_steps + side_index
            var d := (ring_index + 1) * radial_steps + (side_index + 1) % radial_steps
            surface.add_index(a)
            surface.add_index(b)
            surface.add_index(c)
            surface.add_index(b)
            surface.add_index(d)
            surface.add_index(c)
    surface.generate_normals()
    var spring_mesh := MeshInstance3D.new()
    spring_mesh.mesh = surface.commit()
    spring_mesh.material_override = _material(color)
    body.add_child(spring_mesh)
    var shape := CylinderShape3D.new()
    shape.radius = 0.42
    shape.height = 1.35
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    _register_part(id, body, spring_mesh, pos, pos + explode_offset, color)

func _add_sphere_part(id: String, radius: float, pos: Vector3, color: Color, explode_offset: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = id
    body.position = pos
    body.set_meta("part_id", id)
    assembly_root.add_child(body)
    var mesh_resource := SphereMesh.new()
    mesh_resource.radius = radius
    mesh_resource.height = radius * 2.0
    mesh_resource.radial_segments = 32
    mesh_resource.rings = 16
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = mesh_resource
    mesh_instance.material_override = _material(color)
    body.add_child(mesh_instance)
    var shape_resource := SphereShape3D.new()
    shape_resource.radius = radius
    var collision := CollisionShape3D.new()
    collision.shape = shape_resource
    body.add_child(collision)
    _register_part(id, body, mesh_instance, pos, pos + explode_offset, color)

func _register_part(id: String, body: StaticBody3D, mesh: MeshInstance3D, base_pos: Vector3, exploded_pos: Vector3, color: Color) -> void:
    parts[id] = {"node":body, "mesh":mesh, "base_pos":base_pos, "exploded_pos":exploded_pos, "base_color":color}

func _material(color: Color, alpha: float = 1.0, emission_strength: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    var c := color
    c.a = alpha
    material.albedo_color = c
    material.metallic = 0.32
    material.roughness = 0.36
    if emission_strength > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_strength
    if alpha < 0.999:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    return material

func _show_vehicle_overview() -> void:
    selected_system = ""
    selected_assembly = ""
    selected_id = ""
    selected_part_name = ""
    _refresh_3d_state(true)

func _select_catalog_part(id: String) -> void:
    var catalog := PartCatalogService.get_part(id)
    if catalog.is_empty():
        return
    selected_id = id
    selected_part_name = str(catalog.get("name", id))
    selected_system = str(catalog.get("system", ""))
    selected_assembly = _assembly_for_part(selected_system, id)
    isolate_mode = false
    _refresh_3d_state(true)

func _assembly_for_part(system_id: String, part_id: String) -> String:
    if parts.has(part_id):
        var physical := {
            "brake_disc":"front_left_brake", "brake_caliper":"front_left_brake", "brake_pads":"front_left_brake", "brake_hose":"front_left_brake",
            "strut":"front_left_suspension", "spring":"front_left_suspension", "control_arm":"front_left_suspension", "ball_joint":"front_left_suspension", "stabilizer_link":"front_left_suspension",
            "steering_rack":"steering_rack_assembly", "steering_tie_rod":"steering_rack_assembly", "tie_rod_end":"steering_rack_assembly",
            "wheel":"wheels", "hub":"front_left_drive", "wheel_bearing":"front_left_drive", "drive_shaft":"front_left_drive", "cv_joint_inner":"front_left_drive", "cv_joint_outer":"front_left_drive"
        }
        return str(physical.get(part_id, ""))
    for assembly_value in PartCatalogService.assemblies_for_system(system_id):
        var assembly: Dictionary = assembly_value
        if part_id in assembly.get("parts", []):
            return str(assembly.get("id", ""))
    return ""

func _refresh_3d_state(focus_camera: bool = false) -> void:
    if vehicle_root == null or selected_name == null:
        return
    var has_part := selected_id != ""
    var catalog := PartCatalogService.get_part(selected_id) if has_part else {}
    var system := PartCatalogService.SYSTEMS.get(selected_system, {})
    var assembly := _get_selected_assembly()
    if selected_assembly != last_rendered_assembly:
        var was_exploded := exploded
        exploded = false
        xray_mode = false
        isolate_mode = false
        last_rendered_assembly = selected_assembly
        if was_exploded:
            _apply_exploded_state()
        if explode_button != null:
            explode_button.text = "Разобрать"
        if xray_button != null:
            _set_button_active(xray_button, false)
        if isolate_button != null:
            _set_button_active(isolate_button, false)
    var visible_physical_parts: Array = assembly.get("parts", []) if _is_physical_assembly(selected_assembly) else []
    view_mode = "assembly" if not visible_physical_parts.is_empty() else "vehicle"
    vehicle_root.visible = view_mode != "assembly"
    assembly_root.visible = view_mode == "assembly"
    if system_marker != null:
        system_marker.visible = view_mode == "vehicle" and not selected_system.is_empty()
        if system_marker.visible:
            system_marker.position = SYSTEM_FOCUS.get(selected_system, Vector3.ZERO)
            system_marker.scale = SYSTEM_FOCUS_SCALE.get(selected_system, Vector3.ONE)
            if not selected_assembly.is_empty():
                system_marker.position = ASSEMBLY_FOCUS.get(selected_assembly, system_marker.position)
                system_marker.scale *= 0.62
    for part_id in parts.keys():
        var record: Dictionary = parts[part_id]
        var node: StaticBody3D = record.get("node", null)
        if node != null:
            node.visible = view_mode == "assembly" and str(part_id) in visible_physical_parts
    _refresh_vehicle_materials()
    _refresh_part_visuals()
    _sync_selectors()
    _refresh_context_actions()
    if focus_camera:
        _focus_current_selection()
    if has_part:
        selected_name.text = str(catalog.get("name", selected_id))
        selected_status.text = "%s • %s" % [str(system.get("name", "")), str(assembly.get("name", "зона автомобиля"))]
        selected_description.text = str(DETAILED_PARTS.get(selected_id, {}).get("description", "Деталь расположена в этой области автомобиля.")) if parts.has(selected_id) else "Деталь расположена в этой области автомобиля."
        selected_history.text = _part_history_text(selected_id)
    elif not selected_assembly.is_empty():
        selected_name.text = str(assembly.get("name", "Узел"))
        selected_status.text = "%d деталей в узле" % assembly.get("parts", []).size()
        selected_description.text = "Выбери деталь в списке или нажми на модель узла."
        selected_history.text = ""
    elif not selected_system.is_empty():
        selected_name.text = str(system.get("name", "Система"))
        selected_status.text = "%d компонентов" % PartCatalogService.parts_for_system(selected_system).size()
        selected_description.text = "На автомобиле отмечена область системы. Выбери узел или деталь для просмотра."
        selected_history.text = ""
    else:
        selected_name.text = "Интерактивная карта автомобиля"
        selected_status.text = "%d систем • %d компонентов" % [PartCatalogService.SYSTEMS.size(), PartCatalogService.PARTS.size()]
        selected_description.text = "Выбери систему, затем узел и деталь."
        selected_history.text = ""
    if hide_selected_button != null:
        hide_selected_button.disabled = not (view_mode == "assembly" and parts.has(selected_id))

func _get_selected_assembly() -> Dictionary:
    for item_value in PartCatalogService.assemblies_for_system(selected_system):
        var item: Dictionary = item_value
        if str(item.get("id", "")) == selected_assembly:
            return item
    return {}

func _is_physical_assembly(assembly_id: String) -> bool:
    return assembly_id in ["front_left_brake", "front_left_suspension", "steering_rack_assembly", "front_left_drive", "wheels"]

func _focus_current_selection() -> void:
    if camera == null:
        return
    var local_target: Vector3 = SYSTEM_FOCUS.get(selected_system, Vector3(0.0, 1.0, 0.0))
    var distance := 8.8
    if not selected_assembly.is_empty():
        var assembly := _get_selected_assembly()
        if view_mode == "assembly":
            local_target = Vector3(0.0, 0.7, 0.0)
            distance = 6.9
        else:
            local_target = ASSEMBLY_FOCUS.get(selected_assembly, SYSTEM_FOCUS.get(selected_system, local_target))
            distance = float(assembly.get("distance", 6.4))
    if parts.has(selected_id):
        local_target = parts[selected_id].get("base_pos", local_target)
        distance = 4.6
    elif selected_id != "":
        distance = 6.2
    var target := vehicle_root.global_transform * local_target if view_mode == "vehicle" else assembly_root.global_transform * local_target
    var direction := Vector3(1.0, 0.42, 1.0).normalized()
    camera.position = target + direction * distance
    camera.look_at(target, Vector3.UP)

func _refresh_context_actions() -> void:
    if explode_button == null:
        return
    explode_button.visible = view_mode == "assembly" and selected_assembly in ["front_left_brake", "front_left_suspension", "steering_rack_assembly", "front_left_drive"]
    isolate_button.visible = view_mode == "assembly" and parts.has(selected_id)
    xray_button.visible = view_mode == "assembly" or not selected_system.is_empty()
    hide_selected_button.visible = view_mode == "assembly" and parts.has(selected_id)
    var show_everything := xray_mode or isolate_mode or not hidden_parts.is_empty() or exploded
    var show_all_button := _find_button("Показать всё")
    if show_all_button != null:
        show_all_button.visible = show_everything
    var part_actions_enabled := selected_id != ""
    for label in ["Проверка", "Пошаговый ремонт", "История детали", "Руководство", "Записать замену"]:
        var action_button := _find_button(label)
        if action_button != null:
            action_button.visible = part_actions_enabled
    _set_button_active(xray_button, xray_mode)
    _set_button_active(isolate_button, isolate_mode)

func _find_button(label: String) -> Button:
    for child in get_children():
        var found := _find_button_recursive(child, label)
        if found != null:
            return found
    return null

func _find_button_recursive(node: Node, label: String) -> Button:
    if node is Button and (node as Button).text == label:
        return node as Button
    for child in node.get_children():
        var found := _find_button_recursive(child, label)
        if found != null:
            return found
    return null

func _sync_selectors() -> void:
    system_selector.text = "Система: %s  ▾" % (str(PartCatalogService.SYSTEMS.get(selected_system, {}).get("name", "Автомобиль")))
    assembly_selector.text = "Узел: %s  ▾" % (str(_get_selected_assembly().get("name", "Все узлы")))
    var part_name := str(PartCatalogService.get_part(selected_id).get("name", "Все детали")) if selected_id != "" else "Все детали"
    part_selector.text = "Деталь: %s  ▾" % part_name
    assembly_selector.disabled = selected_system.is_empty()
    part_selector.disabled = selected_system.is_empty()

func _create_selector_popup() -> void:
    selector_popup = PopupPanel.new()
    selector_popup.wrap_controls = false
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.clip_contents = true
    panel.add_theme_stylebox_override("panel", _style_box(Color("071820f8"), 18, BORDER, 1))
    selector_popup.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 8)
    panel.add_child(margin)
    selector_scroll = ScrollContainer.new()
    selector_scroll.custom_minimum_size = Vector2(300, 300)
    selector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    selector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    selector_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    selector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    selector_scroll.scroll_deadzone = 8
    selector_scroll.follow_focus = false
    margin.add_child(selector_scroll)
    selector_list = VBoxContainer.new()
    selector_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    selector_scroll.add_child(selector_list)
    get_tree().root.add_child(selector_popup)

func _open_selector(level: String) -> void:
    selector_level = level
    for child in selector_list.get_children():
        child.queue_free()
    var rows: Array[Dictionary] = []
    if level == "system":
        rows.append({"id":"", "name":"Автомобиль — все системы"})
        for item in PartCatalogService.all_systems():
            rows.append(item)
    elif level == "assembly":
        rows = PartCatalogService.assemblies_for_system(selected_system)
    else:
        for item_value in PartCatalogService.parts_for_system(selected_system):
            var part: Dictionary = item_value
            if selected_assembly.is_empty() or str(part.get("id", "")) in _get_selected_assembly().get("parts", []):
                rows.append(part)
    for row_value in rows:
        var row: Dictionary = row_value
        var id := str(row.get("id", ""))
        var title := str(row.get("name", ""))
        var button := _button(title, _choose_selector_item.bind(id))
        button.custom_minimum_size.y = 54
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_stylebox_override("normal", _style_box(Color("083640ee") if id in [selected_system, selected_assembly, selected_id] else Color("081820e8"), 13, CYAN if id in [selected_system, selected_assembly, selected_id] else BORDER, 1))
        selector_list.add_child(button)
    var popup_height := mini(560, maxi(220, int(get_viewport_rect().size.y * 0.72)))
    selector_popup.popup_centered_clamped(Vector2i(420, popup_height), 0.88)

func _choose_selector_item(id: String) -> void:
    selector_popup.hide()
    if selector_level == "system":
        selected_system = id
        selected_assembly = ""
        selected_id = ""
        selected_part_name = ""
        _refresh_3d_state(true)
    elif selector_level == "assembly":
        selected_assembly = id
        selected_id = ""
        selected_part_name = ""
        _refresh_3d_state(true)
    else:
        _select_catalog_part(id)

func _select_part(id: String) -> void:
    _select_catalog_part(id)

func _part_history_text(id: String) -> String:
    var events := ServiceHistoryService.events_for_part(id)
    if events.is_empty():
        return "История этой детали: записей о замене пока нет."
    var latest: Dictionary = events[0]
    var date_text := "дата неизвестна" if bool(latest.get("date_unknown", false)) else str(latest.get("date", ""))
    var mileage_unknown := bool(latest.get("mileage_unknown", false))
    var mileage_text := "пробег неизвестен" if mileage_unknown else "%s км" % _format_int(int(latest.get("mileage", 0)))
    var extra := ""
    var current := MileageService.current_mileage()
    var installed_at := int(latest.get("mileage", 0))
    if not mileage_unknown and current >= installed_at and installed_at > 0:
        extra = " • после записи пройдено %s км" % _format_int(current - installed_at)
    return "Последняя запись: %s • %s%s" % [date_text, mileage_text, extra]

func _on_viewport_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            touch_points[touch.index] = touch.position
            pointer_down = true
            drag_distance = 0.0
            last_pointer = touch.position
        else:
            var was_single_touch := touch_points.size() <= 1
            if pointer_down and was_single_touch and drag_distance < 16.0 and view_mode == "assembly":
                _select_at(touch.position)
            touch_points.erase(touch.index)
            pointer_down = not touch_points.is_empty()
        accept_event()
        return
    if event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        var old_pos: Vector2 = touch_points.get(drag.index, drag.position - drag.relative)
        touch_points[drag.index] = drag.position
        if touch_points.size() >= 2:
            var other_pos := Vector2.ZERO
            var found_other := false
            for key in touch_points.keys():
                if int(key) != drag.index:
                    other_pos = Vector2(touch_points[key])
                    found_other = true
                    break
            if found_other:
                var old_distance := old_pos.distance_to(other_pos)
                var new_distance := drag.position.distance_to(other_pos)
                var pinch_delta := old_distance - new_distance
                _zoom(pinch_delta * 0.012)
                drag_distance += abs(pinch_delta)
        else:
            drag_distance += drag.relative.length()
            _rotate_active(drag.relative)
        last_pointer = drag.position
        accept_event()
        return
    if event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.button_index == MOUSE_BUTTON_LEFT:
            if mouse_button.pressed:
                pointer_down = true
                drag_distance = 0.0
                last_pointer = mouse_button.position
            else:
                if pointer_down and drag_distance < 10.0 and view_mode == "assembly":
                    _select_at(mouse_button.position)
                pointer_down = false
            accept_event()
        elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
            _zoom(-0.45)
            accept_event()
        elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
            _zoom(0.45)
            accept_event()
        return
    if event is InputEventMouseMotion and pointer_down:
        var motion := event as InputEventMouseMotion
        drag_distance += motion.relative.length()
        _rotate_active(motion.relative)
        last_pointer = motion.position
        accept_event()

func _rotate_active(delta: Vector2) -> void:
    var active: Node3D = assembly_root if view_mode == "assembly" else vehicle_root
    if active == null:
        return
    active.rotation_degrees.y += delta.x * 0.34
    active.rotation_degrees.x = clamp(active.rotation_degrees.x + delta.y * 0.23, -38.0, 38.0)

func _zoom(amount: float) -> void:
    if camera == null:
        return
    var local_target: Vector3 = SYSTEM_FOCUS.get(selected_system, Vector3(0.0, 1.0, 0.0))
    if not selected_assembly.is_empty():
        var assembly := _get_selected_assembly()
        if view_mode == "assembly":
            local_target = Vector3(0.0, 0.7, 0.0)
        else:
            local_target = ASSEMBLY_FOCUS.get(selected_assembly, SYSTEM_FOCUS.get(selected_system, local_target))
    if parts.has(selected_id):
        local_target = parts[selected_id].get("base_pos", local_target)
    var target := vehicle_root.global_transform * local_target if view_mode == "vehicle" else assembly_root.global_transform * local_target
    var vector := camera.position - target
    var distance := clamp(vector.length() + amount, 4.6 if view_mode == "assembly" else 6.5, 15.0)
    camera.position = target + vector.normalized() * distance
    camera.look_at(target, Vector3.UP)

func _select_at(screen_position: Vector2) -> void:
    if camera == null or subviewport == null or viewport_container == null:
        return
    var local_size := viewport_container.size
    if local_size.x <= 0.0 or local_size.y <= 0.0:
        return
    var viewport_size := Vector2(subviewport.size)
    var mapped := Vector2(screen_position.x * viewport_size.x / local_size.x, screen_position.y * viewport_size.y / local_size.y)
    var origin := camera.project_ray_origin(mapped)
    var direction := camera.project_ray_normal(mapped)
    var world := subviewport.world_3d
    if world == null:
        return
    var space_state := world.direct_space_state
    if space_state == null:
        return
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
    var result: Dictionary = space_state.intersect_ray(query)
    if result.is_empty():
        return
    var collider: Object = result.get("collider", null)
    if collider == null or not collider.has_meta("part_id"):
        return
    _select_part(str(collider.get_meta("part_id")))

func _toggle_exploded() -> void:
    if view_mode != "assembly":
        return
    exploded = not exploded
    explode_button.text = "Собрать" if exploded else "Разобрать"
    _apply_exploded_state()

func _toggle_xray() -> void:
    if view_mode != "assembly" and selected_system.is_empty():
        return
    xray_mode = not xray_mode
    _set_button_active(xray_button, xray_mode)
    var show_all_button := _find_button("Показать всё")
    if show_all_button != null:
        show_all_button.visible = xray_mode or isolate_mode or exploded or not hidden_parts.is_empty()
    _refresh_vehicle_materials()
    _refresh_part_visuals()

func _toggle_isolate() -> void:
    if selected_id == "" or not parts.has(selected_id):
        return
    if view_mode != "assembly":
        return
    isolate_mode = not isolate_mode
    _set_button_active(isolate_button, isolate_mode)
    _refresh_part_visuals()

func _hide_selected() -> void:
    if selected_id == "" or not parts.has(selected_id):
        return
    hidden_parts[selected_id] = true
    selected_status.text = "Скрыта из 3D • «Показать всё» вернёт деталь"
    _refresh_part_visuals()
    _refresh_context_actions()

func _show_all() -> void:
    hidden_parts.clear()
    xray_mode = false
    isolate_mode = false
    exploded = false
    explode_button.text = "Разобрать"
    _set_button_active(xray_button, false)
    _set_button_active(isolate_button, false)
    _apply_exploded_state()
    _refresh_vehicle_materials()
    _refresh_part_visuals()
    _refresh_context_actions()
    _reset_view()

func _refresh_part_visuals() -> void:
    var active_assembly: Dictionary = _get_selected_assembly()
    var active_ids: Array = active_assembly.get("parts", [])
    for key in parts.keys():
        var id := str(key)
        var part: Dictionary = parts[id]
        var node: StaticBody3D = part.get("node", null)
        if node == null:
            continue
        var hidden := bool(hidden_parts.get(id, false))
        if isolate_mode and selected_id != "" and id != selected_id:
            hidden = true
        node.visible = view_mode == "assembly" and id in active_ids and not hidden
        for child in node.get_children():
            if child is CollisionShape3D:
                (child as CollisionShape3D).disabled = not node.visible
        if hidden:
            continue
        var base_color: Color = part.get("base_color", Color.WHITE)
        var part_meshes: Array[MeshInstance3D] = []
        for child in node.get_children():
            if child is MeshInstance3D:
                part_meshes.append(child as MeshInstance3D)
        if part_meshes.is_empty():
            var registered_mesh: MeshInstance3D = part.get("mesh", null)
            if registered_mesh != null:
                part_meshes.append(registered_mesh)
        var part_material: StandardMaterial3D
        if id == selected_id:
            part_material = _material(CYAN, 1.0, 1.6)
        elif xray_mode:
            part_material = _material(base_color, 0.30)
        else:
            part_material = _material(base_color, 1.0)
        for mesh in part_meshes:
            mesh.material_override = part_material

func _refresh_vehicle_materials() -> void:
    var focused := selected_system != ""
    for item_value in vehicle_meshes:
        var item: Dictionary = item_value
        var mesh: MeshInstance3D = item.get("mesh", null)
        if mesh == null:
            continue
        var color: Color = item.get("color", Color("25323a"))
        var emission := float(item.get("emission", 0.0))
        mesh.material_override = _material(color, 0.11 if xray_mode else (0.76 if focused else 1.0), emission)

func _apply_exploded_state() -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    for key in parts.keys():
        var part: Dictionary = parts[key]
        var node: StaticBody3D = part.get("node", null)
        if node == null:
            continue
        var target: Vector3 = part.get("base_pos", Vector3.ZERO)
        if exploded:
            var logical_offsets := {
                "wheel":Vector3(2.8, 0.0, 0.0), "brake_caliper":Vector3(1.9, 0.0, 0.5),
                "brake_pads":Vector3(1.3, 0.0, 0.0), "brake_disc":Vector3(0.7, 0.0, 0.0),
                "hub":Vector3(-0.2, 0.0, 0.0), "wheel_bearing":Vector3(-0.9, 0.0, 0.0),
                "strut":Vector3(0.0, 1.6, 0.0), "spring":Vector3(0.0, 2.0, 0.0),
                "control_arm":Vector3(0.0, -1.0, -0.5), "ball_joint":Vector3(0.0, -1.35, 0.0),
                "stabilizer_link":Vector3(-0.6, -0.4, -0.6), "tie_rod_end":Vector3(-0.5, 0.0, -0.7),
                "steering_tie_rod":Vector3(-1.0, 0.0, -0.8), "steering_rack":Vector3(-1.6, 0.0, -0.8),
                "cv_joint_outer":Vector3(-1.0, 0.0, 0.0), "drive_shaft":Vector3(-1.8, 0.0, 0.0), "cv_joint_inner":Vector3(-2.6, 0.0, 0.0)
            }
            target = part.get("base_pos", Vector3.ZERO) + logical_offsets.get(str(key), part.get("exploded_pos", Vector3.ZERO) - part.get("base_pos", Vector3.ZERO))
        tween.tween_property(node, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _reset_view() -> void:
    if camera == null:
        return
    if view_mode == "assembly":
        if assembly_root != null:
            assembly_root.rotation_degrees = Vector3(-7, -20, 0)
    else:
        if vehicle_root != null:
            vehicle_root.rotation_degrees = Vector3(-3, -28, 0)
    _focus_current_selection()

func _toggle_expanded_stage() -> void:
    expanded_stage = not expanded_stage
    viewport_container.custom_minimum_size.y = 650 if expanded_stage else 440
    header_block.visible = not expanded_stage
    selectors_panel.visible = not expanded_stage
    selected_card.visible = not expanded_stage
    expand_button.text = "Свернуть" if expanded_stage else "Развернуть"

func _set_button_active(button: Button, active: bool) -> void:
    button.add_theme_stylebox_override("normal", _style_box(Color("083640e8") if active else Color("081820e8"), 14, CYAN if active else BORDER, 1, Color("00e9e944") if active else Color("00000000"), 4 if active else 0))
    button.add_theme_color_override("font_color", Color("e8ffff") if active else Color("a8bbc4"))

func _request_diagnostic() -> void:
    if selected_id != "":
        diagnostic_requested.emit(selected_id, selected_part_name)

func _request_repair() -> void:
    if selected_id != "":
        repair_requested.emit(selected_id, selected_part_name)

func _request_history() -> void:
    if selected_id != "":
        history_requested.emit(selected_id, selected_part_name)

func _request_manual() -> void:
    if selected_id != "":
        manual_requested.emit(selected_id, selected_part_name)

func _request_replacement() -> void:
    if selected_id != "":
        replacement_requested.emit(selected_id, selected_part_name)

func _button(text_value: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size.y = 48
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_color_override("font_color", Color("dcecef"))
    button.add_theme_color_override("font_hover_color", Color("ffffff"))
    button.add_theme_color_override("font_pressed_color", Color("e8ffff"))
    button.add_theme_stylebox_override("normal", _style_box(Color("081820e8"), 14, BORDER, 1))
    button.add_theme_stylebox_override("hover", _style_box(Color("0a2b35ee"), 14, Color("1c8d98"), 1))
    button.add_theme_stylebox_override("pressed", _style_box(Color("08333ceb"), 14, CYAN, 1, Color("00e9e944"), 4))
    button.set_meta("three_d_action", action)
    button.pressed.connect(action)
    return button

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
    if node == viewport_container or node == selector_popup or (viewport_container != null and viewport_container.is_ancestor_of(node)) or (selector_popup != null and selector_popup.is_ancestor_of(node)):
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
            last_pointer = touch.position
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
        var mouse_button := event as InputEventMouseButton
        if mouse_button.pressed:
            page_pointer_down = true
            page_drag_distance = 0.0
        else:
            if page_pointer_down and page_drag_distance < 7.0:
                _activate_control_at(page_scroll.to_global(mouse_button.position))
            page_pointer_down = false
        return
    if event is InputEventMouseMotion and page_pointer_down:
        page_drag_distance += (event as InputEventMouseMotion).relative.length()

func _activate_control_at(global_position: Vector2) -> void:
    var button := _find_action_button_at(self, global_position)
    if button != null and not button.disabled and button.visible:
        button.emit_signal("pressed")

func _find_action_button_at(node: Node, global_position: Vector2) -> Button:
    if node == viewport_container or node == selector_popup or (viewport_container != null and viewport_container.is_ancestor_of(node)) or (selector_popup != null and selector_popup.is_ancestor_of(node)):
        return null
    var children := node.get_children()
    for index in range(children.size() - 1, -1, -1):
        var found := _find_action_button_at(children[index], global_position)
        if found != null:
            return found
    if node is Button:
        var button := node as Button
        if button.visible and button.get_global_rect().has_point(global_position):
            return button
    return null

func _style_option_button(button: OptionButton) -> void:
    button.add_theme_color_override("font_color", Color("dcecef"))
    button.add_theme_color_override("font_hover_color", Color("ffffff"))
    button.add_theme_color_override("font_pressed_color", Color("e8ffff"))
    button.add_theme_stylebox_override("normal", _style_box(Color("081820ea"), 14, BORDER, 1))
    button.add_theme_stylebox_override("hover", _style_box(Color("0a2b35f0"), 14, Color("1c8d98"), 1))
    button.add_theme_stylebox_override("pressed", _style_box(Color("08333cef"), 14, CYAN, 1))
    button.add_theme_stylebox_override("focus", _style_box(Color("081820ea"), 14, CYAN, 1))

func _style_box(color: Color, radius: int, border_color: Color = Color("00000000"), border_width: int = 0, shadow_color: Color = Color("00000000"), shadow_size: int = 0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    box.border_color = border_color
    box.border_width_left = border_width
    box.border_width_top = border_width
    box.border_width_right = border_width
    box.border_width_bottom = border_width
    box.shadow_color = shadow_color
    box.shadow_size = shadow_size
    box.content_margin_left = 10
    box.content_margin_right = 10
    box.content_margin_top = 8
    box.content_margin_bottom = 8
    return box

func _format_int(value: int) -> String:
    var raw := str(absi(value))
    var out := ""
    while raw.length() > 3:
        out = " " + raw.substr(raw.length() - 3, 3) + out
        raw = raw.substr(0, raw.length() - 3)
    out = raw + out
    return ("-" if value < 0 else "") + out

func focus_part(part_id: String) -> void:
    if PartCatalogService.get_part(part_id).is_empty():
        return
    _select_catalog_part(part_id)
