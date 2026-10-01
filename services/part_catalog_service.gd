class_name PartCatalogService
extends RefCounted

# Единый каталог 3D: 13 систем / 66 компонентов.
# Точные процедуры ремонта добавляются только после проверки источника.

const SYSTEMS := {
    "engine": {"name":"Двигатель", "parts":["engine_block", "cylinder_head", "timing_drive", "turbocharger", "engine_mount", "oil_system"]},
    "cooling": {"name":"Охлаждение", "parts":["radiator", "water_pump", "thermostat", "cooling_fan", "coolant_expansion_tank"]},
    "fuel_intake": {"name":"Топливо и впуск", "parts":["fuel_pump", "fuel_filter", "injectors", "throttle_body", "intake_manifold"]},
    "exhaust": {"name":"Выпуск", "parts":["exhaust_manifold", "catalytic_converter", "oxygen_sensor", "rear_muffler"]},
    "transmission": {"name":"Коробка передач", "parts":["gearbox", "clutch", "flywheel", "selector_mechanism", "transmission_mount"]},
    "drive": {"name":"Привод", "parts":["drive_shaft", "cv_joint_inner", "cv_joint_outer", "hub", "wheel_bearing"]},
    "suspension": {"name":"Подвеска", "parts":["strut", "spring", "control_arm", "ball_joint", "stabilizer_link", "wheel"]},
    "steering": {"name":"Рулевое", "parts":["steering_rack", "steering_tie_rod", "tie_rod_end", "steering_column", "power_steering_motor"]},
    "brakes": {"name":"Тормоза", "parts":["brake_disc", "brake_caliper", "brake_pads", "brake_hose", "brake_master_cylinder", "abs_unit"]},
    "electrical": {"name":"Электрика", "parts":["battery", "alternator", "starter", "fuse_box", "body_control_module"]},
    "body": {"name":"Кузов", "parts":["front_bumper", "hood", "front_fender", "tailgate"]},
    "interior": {"name":"Салон", "parts":["driver_seat", "passenger_seat", "rear_seat", "instrument_cluster", "infotainment"]},
    "climate": {"name":"Климат", "parts":["ac_compressor", "condenser", "heater_core", "blower_motor", "climate_control_unit"]},
}

const PARTS := {
    "engine_block": {"name":"Блок двигателя", "group":"Двигатель", "system":"engine", "keywords":["блок двигателя"], "diagnostic_flow":"", "repair_guide":""},
    "cylinder_head": {"name":"Головка блока цилиндров", "group":"Двигатель", "system":"engine", "keywords":["головка блока цилиндров"], "diagnostic_flow":"", "repair_guide":""},
    "timing_drive": {"name":"Привод ГРМ", "group":"Двигатель", "system":"engine", "keywords":["привод грм"], "diagnostic_flow":"", "repair_guide":""},
    "turbocharger": {"name":"Турбокомпрессор", "group":"Двигатель", "system":"engine", "keywords":["турбокомпрессор"], "diagnostic_flow":"", "repair_guide":""},
    "engine_mount": {"name":"Опора двигателя", "group":"Двигатель", "system":"engine", "keywords":["опора двигателя"], "diagnostic_flow":"", "repair_guide":""},
    "oil_system": {"name":"Система смазки", "group":"Двигатель", "system":"engine", "keywords":["система смазки"], "diagnostic_flow":"", "repair_guide":""},
    "radiator": {"name":"Радиатор", "group":"Охлаждение", "system":"cooling", "keywords":["радиатор"], "diagnostic_flow":"", "repair_guide":""},
    "water_pump": {"name":"Помпа", "group":"Охлаждение", "system":"cooling", "keywords":["помпа"], "diagnostic_flow":"", "repair_guide":""},
    "thermostat": {"name":"Термостат", "group":"Охлаждение", "system":"cooling", "keywords":["термостат"], "diagnostic_flow":"", "repair_guide":""},
    "cooling_fan": {"name":"Вентилятор охлаждения", "group":"Охлаждение", "system":"cooling", "keywords":["вентилятор охлаждения"], "diagnostic_flow":"", "repair_guide":""},
    "coolant_expansion_tank": {"name":"Расширительный бачок", "group":"Охлаждение", "system":"cooling", "keywords":["расширительный бачок"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_pump": {"name":"Топливный насос", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["топливный насос"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_filter": {"name":"Топливный фильтр", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["топливный фильтр"], "diagnostic_flow":"", "repair_guide":""},
    "injectors": {"name":"Форсунки", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["форсунки"], "diagnostic_flow":"", "repair_guide":""},
    "throttle_body": {"name":"Дроссельная заслонка", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["дроссельная заслонка"], "diagnostic_flow":"", "repair_guide":""},
    "intake_manifold": {"name":"Впускной коллектор", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["впускной коллектор"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_manifold": {"name":"Выпускной коллектор", "group":"Выпуск", "system":"exhaust", "keywords":["выпускной коллектор"], "diagnostic_flow":"", "repair_guide":""},
    "catalytic_converter": {"name":"Катализатор", "group":"Выпуск", "system":"exhaust", "keywords":["катализатор"], "diagnostic_flow":"", "repair_guide":""},
    "oxygen_sensor": {"name":"Лямбда-зонд", "group":"Выпуск", "system":"exhaust", "keywords":["лямбда-зонд"], "diagnostic_flow":"", "repair_guide":""},
    "rear_muffler": {"name":"Глушитель", "group":"Выпуск", "system":"exhaust", "keywords":["глушитель"], "diagnostic_flow":"", "repair_guide":""},
    "gearbox": {"name":"Коробка передач", "group":"Коробка передач", "system":"transmission", "keywords":["коробка передач"], "diagnostic_flow":"", "repair_guide":""},
    "clutch": {"name":"Сцепление", "group":"Коробка передач", "system":"transmission", "keywords":["сцепление"], "diagnostic_flow":"", "repair_guide":""},
    "flywheel": {"name":"Маховик", "group":"Коробка передач", "system":"transmission", "keywords":["маховик"], "diagnostic_flow":"", "repair_guide":""},
    "selector_mechanism": {"name":"Механизм выбора передач", "group":"Коробка передач", "system":"transmission", "keywords":["механизм выбора передач"], "diagnostic_flow":"", "repair_guide":""},
    "transmission_mount": {"name":"Опора коробки", "group":"Коробка передач", "system":"transmission", "keywords":["опора коробки"], "diagnostic_flow":"", "repair_guide":""},
    "drive_shaft": {"name":"Приводной вал", "group":"Привод", "system":"drive", "keywords":["приводной вал", "привод", "полуось"], "diagnostic_flow":"turn_click", "repair_guide":""},
    "cv_joint_inner": {"name":"Внутренний ШРУС", "group":"Привод", "system":"drive", "keywords":["внутренний шрус", "шрус", "внутренний шрус", "граната"], "diagnostic_flow":"turn_click", "repair_guide":""},
    "cv_joint_outer": {"name":"Наружный ШРУС", "group":"Привод", "system":"drive", "keywords":["наружный шрус", "шрус", "наружный шрус", "граната", "хруст при повороте"], "diagnostic_flow":"turn_click", "repair_guide":""},
    "hub": {"name":"Ступица", "group":"Привод", "system":"drive", "keywords":["ступица", "колесо"], "diagnostic_flow":"road_hum", "repair_guide":""},
    "wheel_bearing": {"name":"Ступичный подшипник", "group":"Привод", "system":"drive", "keywords":["ступичный подшипник", "подшипник", "гул", "люфт колеса"], "diagnostic_flow":"road_hum", "repair_guide":""},
    "strut": {"name":"Амортизационная стойка", "group":"Подвеска", "system":"suspension", "keywords":["амортизационная стойка", "подвеска", "стук подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "spring": {"name":"Пружина", "group":"Подвеска", "system":"suspension", "keywords":["пружина", "подвеска", "стук подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "control_arm": {"name":"Нижний рычаг", "group":"Подвеска", "system":"suspension", "keywords":["нижний рычаг", "подвеска", "стук подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "ball_joint": {"name":"Шаровая опора", "group":"Подвеска", "system":"suspension", "keywords":["шаровая опора", "подвеска", "стук подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "stabilizer_link": {"name":"Стойка стабилизатора", "group":"Подвеска", "system":"suspension", "keywords":["стойка стабилизатора", "подвеска", "стук подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "wheel": {"name":"Колесо", "group":"Подвеска", "system":"suspension", "keywords":["колесо", "колесо"], "diagnostic_flow":"road_hum", "repair_guide":""},
    "steering_rack": {"name":"Рулевой механизм", "group":"Рулевое", "system":"steering", "keywords":["рулевой механизм", "рейка", "рулевой механизм", "стук рулевого"], "diagnostic_flow":"steering_play", "repair_guide":""},
    "steering_tie_rod": {"name":"Рулевая тяга", "group":"Рулевое", "system":"steering", "keywords":["рулевая тяга", "рулевая тяга", "люфт руля"], "diagnostic_flow":"steering_play", "repair_guide":""},
    "tie_rod_end": {"name":"Рулевой наконечник", "group":"Рулевое", "system":"steering", "keywords":["рулевой наконечник", "наконечник", "люфт руля", "стук рулевого"], "diagnostic_flow":"steering_play", "repair_guide":""},
    "steering_column": {"name":"Рулевая колонка", "group":"Рулевое", "system":"steering", "keywords":["рулевая колонка"], "diagnostic_flow":"", "repair_guide":""},
    "power_steering_motor": {"name":"Электроусилитель руля", "group":"Рулевое", "system":"steering", "keywords":["электроусилитель руля"], "diagnostic_flow":"", "repair_guide":""},
    "brake_disc": {"name":"Тормозной диск", "group":"Тормоза", "system":"brakes", "keywords":["тормозной диск", "диск", "биение", "вибрация при торможении"], "diagnostic_flow":"brake_issue", "repair_guide":""},
    "brake_caliper": {"name":"Тормозной суппорт", "group":"Тормоза", "system":"brakes", "keywords":["тормозной суппорт", "суппорт", "направляющие", "поршень суппорта"], "diagnostic_flow":"brake_issue", "repair_guide":""},
    "brake_pads": {"name":"Тормозные колодки", "group":"Тормоза", "system":"brakes", "keywords":["тормозные колодки", "колодки", "скрип тормозов", "тормоза"], "diagnostic_flow":"brake_issue", "repair_guide":"front_brake_pads_replace"},
    "brake_hose": {"name":"Тормозной шланг", "group":"Тормоза", "system":"brakes", "keywords":["тормозной шланг", "тормозной шланг", "тормозная жидкость"], "diagnostic_flow":"brake_issue", "repair_guide":""},
    "brake_master_cylinder": {"name":"Главный тормозной цилиндр", "group":"Тормоза", "system":"brakes", "keywords":["главный тормозной цилиндр"], "diagnostic_flow":"", "repair_guide":""},
    "abs_unit": {"name":"Блок ABS", "group":"Тормоза", "system":"brakes", "keywords":["блок abs"], "diagnostic_flow":"", "repair_guide":""},
    "battery": {"name":"Аккумулятор", "group":"Электрика", "system":"electrical", "keywords":["аккумулятор"], "diagnostic_flow":"", "repair_guide":""},
    "alternator": {"name":"Генератор", "group":"Электрика", "system":"electrical", "keywords":["генератор"], "diagnostic_flow":"", "repair_guide":""},
    "starter": {"name":"Стартер", "group":"Электрика", "system":"electrical", "keywords":["стартер"], "diagnostic_flow":"", "repair_guide":""},
    "fuse_box": {"name":"Блок предохранителей", "group":"Электрика", "system":"electrical", "keywords":["блок предохранителей"], "diagnostic_flow":"", "repair_guide":""},
    "body_control_module": {"name":"Блок управления кузовом", "group":"Электрика", "system":"electrical", "keywords":["блок управления кузовом"], "diagnostic_flow":"", "repair_guide":""},
    "front_bumper": {"name":"Передний бампер", "group":"Кузов", "system":"body", "keywords":["передний бампер"], "diagnostic_flow":"", "repair_guide":""},
    "hood": {"name":"Капот", "group":"Кузов", "system":"body", "keywords":["капот"], "diagnostic_flow":"", "repair_guide":""},
    "front_fender": {"name":"Переднее крыло", "group":"Кузов", "system":"body", "keywords":["переднее крыло"], "diagnostic_flow":"", "repair_guide":""},
    "tailgate": {"name":"Крышка багажника", "group":"Кузов", "system":"body", "keywords":["крышка багажника"], "diagnostic_flow":"", "repair_guide":""},
    "driver_seat": {"name":"Сиденье водителя", "group":"Салон", "system":"interior", "keywords":["сиденье водителя"], "diagnostic_flow":"", "repair_guide":""},
    "passenger_seat": {"name":"Переднее пассажирское сиденье", "group":"Салон", "system":"interior", "keywords":["переднее пассажирское сиденье"], "diagnostic_flow":"", "repair_guide":""},
    "rear_seat": {"name":"Задний диван", "group":"Салон", "system":"interior", "keywords":["задний диван"], "diagnostic_flow":"", "repair_guide":""},
    "instrument_cluster": {"name":"Комбинация приборов", "group":"Салон", "system":"interior", "keywords":["комбинация приборов"], "diagnostic_flow":"", "repair_guide":""},
    "infotainment": {"name":"Мультимедиа", "group":"Салон", "system":"interior", "keywords":["мультимедиа"], "diagnostic_flow":"", "repair_guide":""},
    "ac_compressor": {"name":"Компрессор кондиционера", "group":"Климат", "system":"climate", "keywords":["компрессор кондиционера"], "diagnostic_flow":"", "repair_guide":""},
    "condenser": {"name":"Конденсер кондиционера", "group":"Климат", "system":"climate", "keywords":["конденсер кондиционера"], "diagnostic_flow":"", "repair_guide":""},
    "heater_core": {"name":"Радиатор отопителя", "group":"Климат", "system":"climate", "keywords":["радиатор отопителя"], "diagnostic_flow":"", "repair_guide":""},
    "blower_motor": {"name":"Вентилятор печки", "group":"Климат", "system":"climate", "keywords":["вентилятор печки"], "diagnostic_flow":"", "repair_guide":""},
    "climate_control_unit": {"name":"Блок управления климатом", "group":"Климат", "system":"climate", "keywords":["блок управления климатом"], "diagnostic_flow":"", "repair_guide":""},
}

static func all_systems() -> Array:
    var result: Array = []
    for key in SYSTEMS.keys():
        var row: Dictionary = SYSTEMS[key].duplicate(true)
        row["id"] = str(key)
        result.append(row)
    return result

static func parts_for_system(system_id: String) -> Array:
    var result: Array = []
    var system: Dictionary = SYSTEMS.get(system_id, {})
    for part_value in system.get("parts", []):
        var row := get_part(str(part_value))
        if not row.is_empty():
            result.append(row)
    return result

static func all_parts() -> Array:
    var result: Array = []
    for key in PARTS.keys():
        var row: Dictionary = PARTS[key].duplicate(true)
        row["id"] = str(key)
        result.append(row)
    result.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
    return result

static func get_part(part_id: String) -> Dictionary:
    if not PARTS.has(part_id):
        return {}
    var row: Dictionary = PARTS[part_id].duplicate(true)
    row["id"] = part_id
    return row

static func diagnostic_flow_for_part(part_id: String) -> String:
    return str(get_part(part_id).get("diagnostic_flow", ""))

static func repair_guide_for_part(part_id: String) -> String:
    return str(get_part(part_id).get("repair_guide", ""))

static func search(query: String) -> Array:
    var q := _normalize(query)
    if q == "":
        return []
    var scored: Array = []
    for row_value in all_parts():
        var row: Dictionary = row_value
        var name := _normalize(str(row.get("name", "")))
        var group := _normalize(str(row.get("group", "")))
        var score := 0
        if name == q:
            score += 100
        elif name.begins_with(q):
            score += 70
        elif name.contains(q):
            score += 55
        if group.contains(q):
            score += 20
        for keyword_value in row.get("keywords", []):
            var keyword := _normalize(str(keyword_value))
            if keyword == q:
                score = maxi(score, 90)
            elif keyword.contains(q) or q.contains(keyword):
                score = maxi(score, 45)
        if score > 0:
            row["score"] = score
            scored.append(row)
    scored.sort_custom(func(a, b):
        var score_a := int(a.get("score", 0))
        var score_b := int(b.get("score", 0))
        if score_a == score_b:
            return str(a.get("name", "")) < str(b.get("name", ""))
        return score_a > score_b
    )
    return scored

static func _normalize(value: String) -> String:
    var result := value.strip_edges().to_lower().replace("ё", "е")
    var separators := [".", ",", ";", ":", "!", "?", "(", ")", "[", "]", "{", "}", "\"", "'", "«", "»", "/", "\\", "-", "—", "–", "\n", "\r", "\t"]
    for separator_value in separators:
        result = result.replace(str(separator_value), " ")
    while result.contains("  "):
        result = result.replace("  ", " ")
    return result.strip_edges()
