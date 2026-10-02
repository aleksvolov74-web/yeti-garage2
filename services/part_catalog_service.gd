class_name PartCatalogService
extends RefCounted

# Единый каталог систем и компонентов автомобиля.
# Точные процедуры ремонта добавляются только после проверки источника.

const SYSTEMS := {
    "engine": {"name":"Двигатель", "parts":["engine_block", "cylinder_head", "timing_drive", "turbocharger", "engine_mount", "oil_system", "crankshaft", "piston_group", "connecting_rods", "camshafts", "valve_cover", "oil_filter", "oil_pan", "accessory_belt_drive", "timing_chain", "timing_chain_tensioner", "timing_chain_guides", "timing_sprockets", "timing_cover", "oil_pump", "oil_pump_drive", "oil_pickup", "turbo_oil_feed_line"]},
    "cooling": {"name":"Охлаждение", "parts":["radiator", "water_pump", "thermostat", "cooling_fan", "coolant_expansion_tank", "coolant_hoses", "coolant_temperature_sensor", "turbo_coolant_lines", "low_temperature_radiator", "cooling_fan_secondary", "coolant_recirculation_pump_v50", "engine_oil_cooler"]},
    "fuel_intake": {"name":"Топливо и впуск", "parts":["fuel_pump", "fuel_filter", "injectors", "throttle_body", "intake_manifold", "air_filter", "mass_air_flow_sensor", "fuel_rail", "fuel_tank", "fuel_level_sender", "fuel_pressure_sensor", "high_pressure_fuel_pump", "air_filter_housing", "charge_air_cooler", "intake_manifold_pressure_sensor", "charge_pressure_sensor", "charge_pressure_regulator_v465", "charge_air_pipe", "fuel_pressure_sensor_g247", "fuel_pressure_control_valve_n276", "evap_charcoal_canister", "fuel_tank_straps"]},
    "exhaust": {"name":"Выпуск", "parts":["exhaust_manifold", "catalytic_converter", "oxygen_sensor", "rear_muffler", "front_exhaust_pipe", "exhaust_resonator", "turbo_heat_shield", "exhaust_flex_joint", "catalyst_heat_shield", "exhaust_clamp", "exhaust_mounts", "exhaust_heat_shield"]},
    "transmission": {"name":"Коробка передач", "parts":["gearbox", "clutch", "flywheel", "selector_mechanism", "transmission_mount", "differential", "gear_selector_cables", "dsg_dual_clutch", "dsg_mechatronic", "dsg_input_shafts", "dsg_output_shafts", "dsg_sensors", "dsg_selector_module", "gearbox_housing", "dsg_mechatronics", "dsg_mechatronics_connector", "dsg_mechatronics_actuators", "clutch_k1", "clutch_k2", "clutch_engagement_levers", "gearbox_selector_lever", "selector_cable_support", "haldex_coupling", "propshaft", "propshaft_center_bearing", "rear_drive_shaft_left", "rear_drive_shaft_right"]},
    "drive": {"name":"Привод", "parts":["drive_shaft", "cv_joint_inner", "cv_joint_outer", "hub", "wheel_bearing", "outer_cv_boot", "inner_cv_boot"]},
    "suspension": {"name":"Подвеска", "parts":["strut", "spring", "control_arm", "control_arm_left", "control_arm_right", "ball_joint", "stabilizer_link", "wheel", "subframe", "anti_roll_bar", "strut_mount", "strut_bearing", "bump_stop", "strut_dust_boot", "suspension_bushings", "steering_knuckle", "front_stabilizer_bushings", "rear_suspension_arm", "rear_suspension_track_rod", "rear_shock_absorber", "rear_axle_carrier", "rear_subframe", "rear_upper_control_arm", "rear_lower_control_arm", "rear_trailing_arm", "rear_track_rod", "rear_anti_roll_bar", "rear_hub_carrier", "rear_suspension_bushings", "rear_spring_upper_seat", "rear_spring_lower_seat", "rear_shock_upper_mount", "rear_shock_bump_stop", "wheel_bearing_housing"]},
    "steering": {"name":"Рулевое", "parts":["steering_rack", "steering_tie_rod", "tie_rod_end", "steering_column", "power_steering_motor", "steering_wheel", "steering_angle_sensor", "steering_input_shaft", "steering_rack_boot", "tie_rod_lock_nut"]},
    "brakes": {"name":"Тормоза", "parts":["brake_disc", "brake_caliper", "brake_pads", "brake_hose", "brake_master_cylinder", "abs_unit", "brake_booster", "brake_fluid_reservoir", "abs_wheel_sensor_fl", "abs_wheel_sensor_fr", "abs_wheel_sensor_rl", "abs_wheel_sensor_rr", "brake_carrier", "brake_guide_pins", "dust_shield", "parking_brake_cable", "rear_abs_encoder_ring", "rear_wheel_speed_sensor", "abs_hydraulic_unit", "abs_control_unit", "abs_pump_motor", "abs_mounting_bracket", "brake_pushrod", "brake_lines", "wheel_speed_sensor", "wheel_speed_sensor_connector", "abs_encoder_ring"]},
    "electrical": {"name":"Электрика", "parts":["battery", "alternator", "starter", "fuse_box", "body_control_module", "ignition_coil", "spark_plugs", "engine_ecu", "wiring_harness", "crankshaft_position_sensor", "camshaft_position_sensor", "battery_positive_cable", "battery_ground_cable", "battery_terminal_clamps", "relay_carrier", "high_current_fuse_block", "automotive_relays", "blade_fuses", "control_unit_connectors", "engine_bay_wiring_harness", "cabin_wiring_harness", "ground_straps", "bulkhead_wiring_grommet", "ignition_cables"]},
    "body": {"name":"Кузов", "parts":["front_bumper", "hood", "front_fender", "tailgate", "front_left_door", "front_right_door", "rear_left_door", "rear_right_door", "windshield", "rear_window", "side_mirrors", "roof_rails", "front_wheel_arch_liner", "rear_wheel_arch_liner", "underbody_guard"]},
    "interior": {"name":"Салон", "parts":["driver_seat", "passenger_seat", "rear_seat", "instrument_cluster", "infotainment", "dashboard", "center_console", "glove_box", "pedal_assembly", "cabin_filter"]},
    "climate": {"name":"Климат", "parts":["ac_compressor", "condenser", "heater_core", "blower_motor", "climate_control_unit", "evaporator", "receiver_drier", "air_flap_actuators", "hvac_housing", "fresh_air_blower_control_unit_j126", "recirculation_air_flap", "ac_expansion_valve", "ac_pressure_sensor_g65"]},
    "lighting": {"name":"Освещение", "parts":["headlamp_left", "headlamp_right", "fog_lamp_left", "fog_lamp_right", "tail_lamp_left", "tail_lamp_right", "license_plate_lamp", "interior_lights", "headlamp_bulbs", "headlamp_level_actuator", "tail_lamp_bulb_carrier", "rear_lamp_connector", "rear_interior_light", "luggage_compartment_lamp", "interior_light_bulbs", "interior_light_connector"]},
    "safety": {"name":"Безопасность", "parts":["driver_airbag", "passenger_airbag", "side_airbags", "seat_belts", "belt_pretensioners", "crash_sensors_front", "crash_sensors_side"]},
    "wipers_glass": {"name":"Стекло и очистители", "parts":["wiper_motor_front", "wiper_linkage", "wiper_blades_front", "wiper_motor_rear", "washer_pump", "washer_reservoir", "rain_sensor"]},
}

# Подсистемы каталога. Остальные позиции автоматически попадают в общий
# логический узел системы, поэтому ни одна из 140 деталей не теряется.
const ASSEMBLY_GROUPS := {
    "brakes": [
        {"id":"front_left_brake", "name":"Левый передний тормозной механизм", "parts":["wheel", "brake_disc", "brake_caliper", "brake_pads", "brake_hose", "hub", "wheel_bearing", "brake_carrier", "brake_guide_pins", "dust_shield"]},
        {"id":"brake_hydraulics", "name":"Гидравлика и ABS", "parts":["brake_master_cylinder", "abs_unit", "brake_booster", "brake_fluid_reservoir", "abs_wheel_sensor_fl", "abs_wheel_sensor_fr", "abs_wheel_sensor_rl", "abs_wheel_sensor_rr"]}
    ],
    "suspension": [
        {"id":"front_left_suspension", "name":"Левая передняя подвеска", "parts":["strut", "spring", "control_arm", "ball_joint", "stabilizer_link", "strut_mount", "strut_bearing", "bump_stop", "strut_dust_boot", "suspension_bushings"]},
        {"id":"front_axle_control_arms", "name":"Подрамник и нижние рычаги передней оси", "parts":["subframe", "control_arm_left", "control_arm_right", "suspension_bushings", "ball_joint"]},
        {"id":"front_axle_suspension", "name":"Передняя ось", "parts":["subframe", "anti_roll_bar"]},
        {"id":"wheels", "name":"Колёса", "parts":["wheel"]}
    ],
    "drive": [
        {"id":"front_left_drive", "name":"Передний левый привод", "parts":["drive_shaft", "cv_joint_inner", "cv_joint_outer", "hub", "wheel_bearing", "outer_cv_boot", "inner_cv_boot"]}
    ],
    "steering": [
        {"id":"steering_rack_assembly", "name":"Рулевая рейка и тяги", "parts":["steering_rack", "steering_tie_rod", "tie_rod_end"]},
        {"id":"steering_column_assembly", "name":"Рулевая колонка", "parts":["steering_column", "power_steering_motor", "steering_wheel", "steering_angle_sensor"]}
    ],
    "engine": [
        {"id":"engine_front", "name":"Передняя часть двигателя", "model_id":"engine_front", "camera_focus":Vector3(0.0, 0.0, 0.0), "camera_distance":4.2, "focus_points":{"engine_block":Vector3(0.0, -0.24, 0.0), "cylinder_head":Vector3(0.0, 0.36, 0.0), "valve_cover":Vector3(0.0, 0.74, 0.0), "turbocharger":Vector3(0.94, 0.03, 0.12), "alternator":Vector3(-0.88, -0.52, 0.28), "accessory_belt_drive":Vector3(-0.1, -0.62, 0.5)}, "parts":["engine_block", "cylinder_head", "valve_cover", "turbocharger", "alternator", "accessory_belt_drive"]},
        {"id":"engine_long_block", "name":"Кривошипно-шатунный механизм", "parts":["crankshaft", "piston_group", "connecting_rods", "camshafts"]},
        {"id":"timing_assembly", "name":"Привод ГРМ", "parts":["timing_drive"]},
        {"id":"lubrication", "name":"Система смазки", "parts":["oil_system", "oil_filter", "oil_pan"]},
        {"id":"intake", "name":"Турбонаддув и опора двигателя", "parts":["engine_mount"]}
    ],
    "cooling": [
        {"id":"radiator_pack", "name":"Пакет радиаторов", "parts":["radiator", "cooling_fan"]},
        {"id":"coolant_circuit", "name":"Контур охлаждения", "parts":["water_pump", "thermostat", "coolant_expansion_tank", "coolant_hoses", "coolant_temperature_sensor"]}
    ],
    "transmission": [
        {"id":"gearbox_clutch", "name":"Коробка и сцепление", "parts":["gearbox", "gearbox_housing", "clutch", "flywheel", "dsg_dual_clutch", "clutch_k1", "clutch_k2", "clutch_engagement_levers", "transmission_mount", "differential", "dsg_input_shafts", "dsg_output_shafts", "dsg_sensors", "dsg_mechatronic", "dsg_mechatronics", "dsg_mechatronics_connector", "dsg_mechatronics_actuators"]},
        {"id":"selector", "name":"Выбор передач", "parts":["selector_mechanism", "gear_selector_cables", "gearbox_selector_lever", "selector_cable_support", "dsg_selector_module"]}
    ],
    "interior": [
        {"id":"dashboard", "name":"Передняя панель", "parts":["dashboard", "instrument_cluster", "infotainment", "glove_box", "pedal_assembly", "cabin_filter"]},
        {"id":"seats", "name":"Сиденья", "parts":["driver_seat", "passenger_seat", "rear_seat"]},
        {"id":"center_console", "name":"Центральная консоль", "parts":["center_console"]}
    ],
    "climate": [
        {"id":"hvac_box", "name":"Отопитель и вентиляция", "parts":["heater_core", "blower_motor", "climate_control_unit", "evaporator", "air_flap_actuators", "cabin_filter", "hvac_housing", "fresh_air_blower_control_unit_j126", "recirculation_air_flap"]},
        {"id":"ac_circuit", "name":"Контур кондиционера", "parts":["ac_compressor", "condenser", "receiver_drier", "evaporator", "ac_expansion_valve", "ac_pressure_sensor_g65"]}
    ],
    "electrical": [
        {"id":"engine_bay_electrical", "name":"Электрика моторного отсека", "parts":["battery", "alternator", "starter", "fuse_box", "ignition_coil", "spark_plugs", "engine_ecu", "wiring_harness", "crankshaft_position_sensor", "camshaft_position_sensor", "battery_positive_cable", "battery_ground_cable", "battery_terminal_clamps", "high_current_fuse_block", "automotive_relays", "blade_fuses", "relay_carrier", "engine_bay_wiring_harness", "ground_straps", "ignition_cables"]},
        {"id":"cabin_electrical", "name":"Электрика салона", "parts":["body_control_module", "control_unit_connectors", "cabin_wiring_harness", "bulkhead_wiring_grommet"]}
    ],
    "body": [
        {"id":"front_body", "name":"Передняя часть кузова", "parts":["front_bumper", "hood", "front_fender"]},
        {"id":"doors", "name":"Двери", "parts":["front_left_door", "front_right_door", "rear_left_door", "rear_right_door"]},
        {"id":"rear_body", "name":"Задняя часть кузова", "parts":["tailgate", "rear_window", "side_mirrors", "windshield", "roof_rails"]}
    ],
    "lighting": [
        {"id":"front_lighting", "name":"Передняя светотехника", "parts":["headlamp_left", "headlamp_right", "fog_lamp_left", "fog_lamp_right", "headlamp_bulbs", "headlamp_level_actuator"]},
        {"id":"rear_lighting", "name":"Задняя светотехника", "parts":["tail_lamp_left", "tail_lamp_right", "license_plate_lamp", "interior_lights", "tail_lamp_bulb_carrier", "rear_lamp_connector", "rear_interior_light", "luggage_compartment_lamp", "interior_light_bulbs", "interior_light_connector"]}
    ],
    "wipers_glass": [
        {"id":"front_wiper_system", "name":"Передние стеклоочистители", "parts":["wiper_motor_front", "wiper_linkage", "wiper_blades_front", "washer_pump", "washer_reservoir", "rain_sensor"]},
        {"id":"rear_wiper_system", "name":"Задний стеклоочиститель", "parts":["wiper_motor_rear"]}
    ],
    "safety": [
        {"id":"passive_safety", "name":"Подушки и ремни", "parts":["driver_airbag", "passenger_airbag", "side_airbags", "seat_belts", "belt_pretensioners", "crash_sensors_front", "crash_sensors_side"]}
    ]
}

const PARTS := {
    "interior_light_connector": {"name":"Разъём плафона освещения салона", "group":"Освещение", "system":"lighting", "keywords":["разъём плафона","разъем плафона"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "interior_light_bulbs": {"name":"Лампы освещения салона", "group":"Освещение", "system":"lighting", "keywords":["лампы салона","лампа салонного освещения"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "luggage_compartment_lamp": {"name":"Плафон багажного отделения", "group":"Освещение", "system":"lighting", "keywords":["лампа багажника","плафон багажного отделения"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "rear_interior_light": {"name":"Задний плафон освещения салона", "group":"Освещение", "system":"lighting", "keywords":["задний плафон","заднее освещение салона"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "rear_lamp_connector": {"name":"Разъём заднего фонаря", "group":"Освещение", "system":"lighting", "keywords":["разъём заднего фонаря","разъем заднего фонаря"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "tail_lamp_bulb_carrier": {"name":"Плата держателя ламп заднего фонаря", "group":"Освещение", "system":"lighting", "keywords":["плата заднего фонаря","держатель ламп фонаря"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "headlamp_level_actuator": {"name":"Электрокорректор фары", "group":"Освещение", "system":"lighting", "keywords":["электрокорректор фары","корректор фар"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "headlamp_bulbs": {"name":"Лампы передних фар", "group":"Освещение", "system":"lighting", "keywords":["лампы передних фар","лампа фары"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "ignition_cables": {"name":"Высоковольтные провода зажигания", "group":"Зажигание", "system":"electrical", "keywords":["высоковольтные провода зажигания","провода зажигания"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "bulkhead_wiring_grommet": {"name":"Уплотнитель прохода жгута через щит передка", "group":"Электрика", "system":"electrical", "keywords":["уплотнитель жгута щита передка","ввод проводки в салон"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "ground_straps": {"name":"Провода массы кузова и двигателя", "group":"Электрика", "system":"electrical", "keywords":["провода массы","масса кузова","масса двигателя"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "cabin_wiring_harness": {"name":"Жгут электропроводки салона", "group":"Электрика", "system":"electrical", "keywords":["жгут проводки салона","проводка салона"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "engine_bay_wiring_harness": {"name":"Жгут электропроводки моторного отсека", "group":"Электрика", "system":"electrical", "keywords":["жгут моторного отсека","проводка моторного отсека"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "control_unit_connectors": {"name":"Разъёмы блоков управления", "group":"Электрика", "system":"electrical", "keywords":["разъёмы блоков управления","разъем эбу"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "blade_fuses": {"name":"Плоские автомобильные предохранители", "group":"Электрика", "system":"electrical", "keywords":["плоские предохранители","ножевые предохранители"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "automotive_relays": {"name":"Автомобильные реле", "group":"Электрика", "system":"electrical", "keywords":["автомобильные реле","реле автомобиля"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "high_current_fuse_block": {"name":"Блок силовых предохранителей", "group":"Электрика", "system":"electrical", "keywords":["силовой блок предохранителей","силовые предохранители"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "relay_carrier": {"name":"Панель реле", "group":"Электрика", "system":"electrical", "keywords":["панель реле","держатель реле"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "battery_terminal_clamps": {"name":"Клеммы аккумулятора", "group":"Электрика", "system":"electrical", "keywords":["клеммы аккумулятора","клемма аккумулятора"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "battery_ground_cable": {"name":"Кабель массы аккумулятора", "group":"Электрика", "system":"electrical", "keywords":["массовый провод аккумулятора","минусовой кабель аккумулятора"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "battery_positive_cable": {"name":"Положительный кабель аккумулятора", "group":"Электрика", "system":"electrical", "keywords":["положительный провод аккумулятора","плюсовой кабель аккумулятора"], "diagnostic_flow":"", "repair_guide":"", "requires_years":[2009,2017]},
    "rear_subframe": {"name":"Подрамник задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["подрамник задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_upper_control_arm": {"name":"Верхний поперечный рычаг задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["верхний рычаг задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_lower_control_arm": {"name":"Нижний поперечный рычаг задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["нижний рычаг задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_trailing_arm": {"name":"Продольный рычаг задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["продольный рычаг задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_track_rod": {"name":"Поперечная тяга задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["поперечная тяга задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_anti_roll_bar": {"name":"Задний стабилизатор поперечной устойчивости", "group":"Передняя подвеска", "system":"suspension", "keywords":["задний стабилизатор"], "diagnostic_flow":"", "repair_guide":""},
    "rear_hub_carrier": {"name":"Держатель ступицы заднего колеса", "group":"Передняя подвеска", "system":"suspension", "keywords":["задний держатель ступицы"], "diagnostic_flow":"", "repair_guide":""},
    "rear_suspension_bushings": {"name":"Сайлентблоки задней подвески", "group":"Передняя подвеска", "system":"suspension", "keywords":["сайлентблоки задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_spring_upper_seat": {"name":"Верхняя прокладка задней пружины", "group":"Передняя подвеска", "system":"suspension", "keywords":["верхняя опора задней пружины"], "diagnostic_flow":"", "repair_guide":""},
    "rear_spring_lower_seat": {"name":"Нижняя прокладка задней пружины", "group":"Передняя подвеска", "system":"suspension", "keywords":["нижняя опора задней пружины"], "diagnostic_flow":"", "repair_guide":""},
    "rear_shock_upper_mount": {"name":"Верхнее крепление заднего амортизатора", "group":"Передняя подвеска", "system":"suspension", "keywords":["верхняя опора заднего амортизатора"], "diagnostic_flow":"", "repair_guide":""},
    "rear_shock_bump_stop": {"name":"Отбойник заднего амортизатора", "group":"Передняя подвеска", "system":"suspension", "keywords":["отбойник заднего амортизатора"], "diagnostic_flow":"", "repair_guide":""},
    "rear_abs_encoder_ring": {"name":"Магнитный энкодер заднего ступичного подшипника", "group":"Передние тормоза", "system":"brakes", "keywords":["энкодер задней ступицы"], "diagnostic_flow":"", "repair_guide":""},
    "rear_wheel_speed_sensor": {"name":"Задний датчик скорости колеса ABS", "group":"Передние тормоза", "system":"brakes", "keywords":["задний датчик abs"], "diagnostic_flow":"", "repair_guide":""},
    "steering_input_shaft": {"name":"Входной вал рулевой рейки", "group":"Рулевое управление", "system":"steering", "keywords":["входной вал рулевой рейки"], "diagnostic_flow":"", "repair_guide":""},
    "steering_rack_boot": {"name":"Пыльник рулевой рейки", "group":"Рулевое управление", "system":"steering", "keywords":["пыльник рулевой рейки"], "diagnostic_flow":"", "repair_guide":""},
    "tie_rod_lock_nut": {"name":"Контргайка рулевой тяги", "group":"Рулевое управление", "system":"steering", "keywords":["контргайка рулевой тяги"], "diagnostic_flow":"", "repair_guide":""},
    "abs_hydraulic_unit": {"name":"Гидравлический блок ABS/ESP", "group":"Передние тормоза", "system":"brakes", "keywords":["гидравлический блок abs"], "diagnostic_flow":"", "repair_guide":""},
    "abs_control_unit": {"name":"Электронный блок управления ABS/ESP", "group":"Передние тормоза", "system":"brakes", "keywords":["блок управления abs"], "diagnostic_flow":"", "repair_guide":""},
    "abs_pump_motor": {"name":"Электродвигатель насоса ABS", "group":"Передние тормоза", "system":"brakes", "keywords":["насос abs"], "diagnostic_flow":"", "repair_guide":""},
    "abs_mounting_bracket": {"name":"Кронштейн блока ABS/ESP", "group":"Передние тормоза", "system":"brakes", "keywords":["кронштейн abs"], "diagnostic_flow":"", "repair_guide":""},
    "brake_pushrod": {"name":"Толкатель вакуумного усилителя тормозов", "group":"Передние тормоза", "system":"brakes", "keywords":["толкатель тормозного усилителя"], "diagnostic_flow":"", "repair_guide":""},
    "brake_lines": {"name":"Тормозные трубопроводы", "group":"Передние тормоза", "system":"brakes", "keywords":["тормозные трубки"], "diagnostic_flow":"", "repair_guide":""},
    "wheel_speed_sensor": {"name":"Датчик скорости колеса ABS", "group":"Передние тормоза", "system":"brakes", "keywords":["датчик скорости колеса"], "diagnostic_flow":"", "repair_guide":""},
    "wheel_speed_sensor_connector": {"name":"Разъём датчика скорости колеса", "group":"Передние тормоза", "system":"brakes", "keywords":["разъем датчика abs"], "diagnostic_flow":"", "repair_guide":""},
    "abs_encoder_ring": {"name":"Магнитный энкодер ступичного подшипника", "group":"Передние тормоза", "system":"brakes", "keywords":["энкодер ступичного подшипника"], "diagnostic_flow":"", "repair_guide":""},
    "wheel_bearing_housing": {"name":"Корпус ступичного подшипника", "group":"Передняя подвеска", "system":"suspension", "keywords":["корпус ступичного подшипника"], "diagnostic_flow":"", "repair_guide":""},
    "air_filter_housing": {"name":"Корпус воздушного фильтра", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["корпус воздушного фильтра"], "diagnostic_flow":"", "repair_guide":""},
    "charge_air_cooler": {"name":"Жидкостный охладитель наддувочного воздуха во впускном коллекторе CBZB", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["охладитель наддувочного воздуха cbzb"], "diagnostic_flow":"", "repair_guide":""},
    "intake_manifold_pressure_sensor": {"name":"Датчик давления во впускном коллекторе", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["датчик давления впускного коллектора"], "diagnostic_flow":"", "repair_guide":""},
    "charge_pressure_sensor": {"name":"Датчик давления наддува", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["датчик давления наддува"], "diagnostic_flow":"", "repair_guide":""},
    "charge_pressure_regulator_v465": {"name":"Регулятор давления наддува V465", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["регулятор наддува v465"], "diagnostic_flow":"", "repair_guide":""},
    "turbo_oil_feed_line": {"name":"Маслоподающая трубка турбокомпрессора", "group":"Двигатель", "system":"engine", "keywords":["маслоподача турбины"], "diagnostic_flow":"", "repair_guide":""},
    "turbo_coolant_lines": {"name":"Трубки охлаждения турбокомпрессора", "group":"Охлаждение", "system":"cooling", "keywords":["охлаждение турбокомпрессора"], "diagnostic_flow":"", "repair_guide":""},
    "charge_air_pipe": {"name":"Трубопровод наддувочного воздуха", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["патрубок наддува"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_pressure_sensor_g247": {"name":"Датчик давления топлива G247", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["датчик g247"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_pressure_control_valve_n276": {"name":"Клапан регулирования давления топлива N276", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["клапан n276"], "diagnostic_flow":"", "repair_guide":""},
    "evap_charcoal_canister": {"name":"Адсорбер паров топлива", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["адсорбер паров бензина"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_tank_straps": {"name":"Крепёжные ленты топливного бака", "group":"Впуск и турбонаддув", "system":"fuel_intake", "keywords":["ленты топливного бака"], "diagnostic_flow":"", "repair_guide":""},
    "low_temperature_radiator": {"name":"Низкотемпературный радиатор охладителя наддува", "group":"Охлаждение", "system":"cooling", "keywords":["низкотемпературный радиатор"], "diagnostic_flow":"", "repair_guide":""},
    "cooling_fan_secondary": {"name":"Дополнительный вентилятор охлаждения", "group":"Охлаждение", "system":"cooling", "keywords":["второй вентилятор охлаждения"], "diagnostic_flow":"", "repair_guide":""},
    "coolant_recirculation_pump_v50": {"name":"Насос циркуляции охлаждающей жидкости V50", "group":"Охлаждение", "system":"cooling", "keywords":["насос охлаждения v50"], "diagnostic_flow":"", "repair_guide":""},
    "engine_oil_cooler": {"name":"Масляный охладитель двигателя", "group":"Охлаждение", "system":"cooling", "keywords":["масляный охладитель"], "diagnostic_flow":"", "repair_guide":""},
    "turbo_heat_shield": {"name":"Тепловой экран турбокомпрессора", "group":"Выпуск", "system":"exhaust", "keywords":["экран турбины"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_flex_joint": {"name":"Гибкая секция передней трубы выпуска", "group":"Выпуск", "system":"exhaust", "keywords":["гофра выхлопа"], "diagnostic_flow":"", "repair_guide":""},
    "catalyst_heat_shield": {"name":"Тепловой экран каталитического нейтрализатора", "group":"Выпуск", "system":"exhaust", "keywords":["экран катализатора"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_clamp": {"name":"Хомут соединения системы выпуска", "group":"Выпуск", "system":"exhaust", "keywords":["хомут выхлопной системы"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_mounts": {"name":"Подвесы системы выпуска", "group":"Выпуск", "system":"exhaust", "keywords":["резиновые подвесы глушителя"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_heat_shield": {"name":"Тепловой экран системы выпуска", "group":"Выпуск", "system":"exhaust", "keywords":["экран выхлопной системы"], "diagnostic_flow":"", "repair_guide":""},


    "oil_pump_drive": {"name":"Цепной привод масляного насоса CBZB", "group":"Двигатель", "system":"engine", "keywords":["привод масляного насоса", "цепь масляного насоса"], "diagnostic_flow":"", "repair_guide":""},
    "gearbox_housing": {"name":"Корпус коробки DSG 0AM", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["корпус коробки dsg", "корпус dq200"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_mechatronics": {"name":"Мехатроник DSG 0AM / DQ200", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["мехатроник dsg", "мехатроник dq200", "j743"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_mechatronics_connector": {"name":"Электрический разъём мехатроника DSG", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["разъём мехатроника", "разъем j743"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_mechatronics_actuators": {"name":"Исполнительные элементы мехатроника DSG", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["актуаторы мехатроника", "исполнительные элементы dsg"], "diagnostic_flow":"", "repair_guide":""},
    "clutch_k1": {"name":"Сцепление K1 DSG 0AM", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["сцепление k1", "dq200 k1"], "diagnostic_flow":"", "repair_guide":""},
    "clutch_k2": {"name":"Сцепление K2 DSG 0AM", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["сцепление k2", "dq200 k2"], "diagnostic_flow":"", "repair_guide":""},
    "clutch_engagement_levers": {"name":"Рычаги включения двойного сцепления DSG", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["рычаги включения сцепления", "вилки сцепления dsg"], "diagnostic_flow":"", "repair_guide":""},
    "gearbox_selector_lever": {"name":"Рычаг выбора передач на коробке DSG", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["рычаг выбора передач на коробке", "селектор dsg"], "diagnostic_flow":"", "repair_guide":""},
    "selector_cable_support": {"name":"Опора троса выбора передач DSG", "group":"Коробка передач", "system":"transmission", "requires_transmission_families":["0AM"], "keywords":["опора троса селектора", "кронштейн троса dsg"], "diagnostic_flow":"", "repair_guide":""},
    "engine_block": {"name":"Блок двигателя", "group":"Двигатель", "system":"engine", "keywords":["блок двигателя"], "diagnostic_flow":"", "repair_guide":""},
    "cylinder_head": {"name":"Головка блока цилиндров", "group":"Двигатель", "system":"engine", "keywords":["головка блока цилиндров"], "diagnostic_flow":"", "repair_guide":""},
    "timing_drive": {"name":"Привод ГРМ", "group":"Двигатель", "system":"engine", "keywords":["привод грм"], "diagnostic_flow":"", "repair_guide":""},
    "turbocharger": {"name":"Турбокомпрессор", "group":"Двигатель", "system":"engine", "keywords":["турбокомпрессор"], "diagnostic_flow":"", "repair_guide":""},
    "engine_mount": {"name":"Опора двигателя", "group":"Двигатель", "system":"engine", "keywords":["опора двигателя"], "diagnostic_flow":"", "repair_guide":""},
    "accessory_belt_drive": {"name":"Ременной привод навесных агрегатов", "group":"Двигатель", "system":"engine", "keywords":["ременной привод", "ремень генератора", "ремень навесных агрегатов"], "diagnostic_flow":"", "repair_guide":""},
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
    "control_arm_left": {"name":"Левый нижний рычаг", "group":"Передняя подвеска", "system":"suspension", "keywords":["левый нижний рычаг", "левый рычаг передней подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "control_arm_right": {"name":"Правый нижний рычаг", "group":"Передняя подвеска", "system":"suspension", "keywords":["правый нижний рычаг", "правый рычаг передней подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
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
    "body_control_module": {"name":"Блок бортовой сети (BCM)", "group":"Электрика", "system":"electrical", "keywords":["блок бортовой сети", "bcm", "блок управления кузовом"], "diagnostic_flow":"", "repair_guide":""},
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
    "crankshaft": {"name":"Коленчатый вал", "group":"Двигатель", "system":"engine", "keywords":["коленвал", "коленчатый вал"], "diagnostic_flow":"", "repair_guide":""},
    "piston_group": {"name":"Поршневая группа", "group":"Двигатель", "system":"engine", "keywords":["поршневая группа", "поршни"], "diagnostic_flow":"", "repair_guide":""},
    "connecting_rods": {"name":"Шатуны", "group":"Двигатель", "system":"engine", "keywords":["шатуны", "шатун"], "diagnostic_flow":"", "repair_guide":""},
    "camshafts": {"name":"Распределительные валы", "group":"Двигатель", "system":"engine", "keywords":["распредвал", "распределительный вал"], "diagnostic_flow":"", "repair_guide":""},
    "valve_cover": {"name":"Клапанная крышка", "group":"Двигатель", "system":"engine", "keywords":["клапанная крышка"], "diagnostic_flow":"", "repair_guide":""},
    "oil_filter": {"name":"Масляный фильтр", "group":"Двигатель", "system":"engine", "keywords":["масляный фильтр"], "diagnostic_flow":"", "repair_guide":""},
    "oil_pan": {"name":"Масляный поддон", "group":"Двигатель", "system":"engine", "keywords":["масляный поддон"], "diagnostic_flow":"", "repair_guide":""},
    "coolant_hoses": {"name":"Патрубки охлаждения", "group":"Охлаждение", "system":"cooling", "keywords":["патрубки охлаждения", "патрубок"], "diagnostic_flow":"", "repair_guide":""},
    "coolant_temperature_sensor": {"name":"Датчик температуры охлаждающей жидкости", "group":"Охлаждение", "system":"cooling", "keywords":["датчик температуры ож", "датчик температуры охлаждающей жидкости"], "diagnostic_flow":"", "repair_guide":""},
    "air_filter": {"name":"Воздушный фильтр", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["воздушный фильтр"], "diagnostic_flow":"", "repair_guide":""},
    "mass_air_flow_sensor": {"name":"Расходомер воздуха", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["расходомер", "датчик массового расхода воздуха", "дмрв"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_rail": {"name":"Топливная рампа", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["топливная рампа"], "diagnostic_flow":"", "repair_guide":""},
    "front_exhaust_pipe": {"name":"Передняя часть выпуска", "group":"Выпуск", "system":"exhaust", "keywords":["передняя часть выпуска", "приёмная труба"], "diagnostic_flow":"", "repair_guide":""},
    "exhaust_resonator": {"name":"Резонатор", "group":"Выпуск", "system":"exhaust", "keywords":["резонатор"], "diagnostic_flow":"", "repair_guide":""},
    "differential": {"name":"Дифференциал", "group":"Коробка передач", "system":"transmission", "keywords":["дифференциал"], "diagnostic_flow":"", "repair_guide":""},
    "gear_selector_cables": {"name":"Трос выбора передач DSG", "group":"Коробка передач", "system":"transmission", "keywords":["тросы выбора передач", "трос кулисы"], "diagnostic_flow":"", "repair_guide":""},
    "outer_cv_boot": {"name":"Наружный пыльник ШРУСа", "group":"Привод", "system":"drive", "keywords":["наружный пыльник шруса", "пыльник наружного шруса"], "diagnostic_flow":"turn_click", "repair_guide":""},
    "inner_cv_boot": {"name":"Внутренний пыльник ШРУСа", "group":"Привод", "system":"drive", "keywords":["внутренний пыльник шруса", "пыльник внутреннего шруса"], "diagnostic_flow":"", "repair_guide":""},
    "subframe": {"name":"Подрамник", "group":"Подвеска", "system":"suspension", "keywords":["подрамник"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "anti_roll_bar": {"name":"Стабилизатор поперечной устойчивости", "group":"Подвеска", "system":"suspension", "keywords":["стабилизатор поперечной устойчивости", "стабилизатор"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "strut_mount": {"name":"Верхняя опора стойки", "group":"Подвеска", "system":"suspension", "keywords":["верхняя опора стойки", "опора амортизатора"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "strut_bearing": {"name":"Опорный подшипник стойки", "group":"Подвеска", "system":"suspension", "keywords":["опорный подшипник стойки", "подшипник верхней опоры"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "bump_stop": {"name":"Отбойник амортизационной стойки", "group":"Подвеска", "system":"suspension", "keywords":["отбойник стойки", "отбойник амортизатора"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "strut_dust_boot": {"name":"Пыльник амортизационной стойки", "group":"Подвеска", "system":"suspension", "keywords":["пыльник стойки", "пыльник амортизатора"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "suspension_bushings": {"name":"Сайлентблоки подвески", "group":"Подвеска", "system":"suspension", "keywords":["сайлентблоки", "сайлентблок подвески"], "diagnostic_flow":"suspension_knock", "repair_guide":""},
    "steering_wheel": {"name":"Рулевое колесо", "group":"Рулевое", "system":"steering", "keywords":["рулевое колесо", "руль"], "diagnostic_flow":"", "repair_guide":""},
    "steering_angle_sensor": {"name":"Датчик угла поворота руля", "group":"Рулевое", "system":"steering", "keywords":["датчик угла руля", "датчик угла поворота руля"], "diagnostic_flow":"", "repair_guide":""},
    "brake_booster": {"name":"Вакуумный усилитель тормозов", "group":"Тормоза", "system":"brakes", "keywords":["вакуумный усилитель тормозов", "вакуумный усилитель"], "diagnostic_flow":"brake_issue", "repair_guide":""},
    "brake_fluid_reservoir": {"name":"Бачок тормозной жидкости", "group":"Тормоза", "system":"brakes", "keywords":["бачок тормозной жидкости"], "diagnostic_flow":"brake_issue", "repair_guide":""},
    "abs_wheel_sensor_fl": {"name":"Датчик ABS переднего левого колеса", "group":"Тормоза", "system":"brakes", "keywords":["датчик abs передний левый", "датчик абс"], "diagnostic_flow":"", "repair_guide":""},
    "abs_wheel_sensor_fr": {"name":"Датчик ABS переднего правого колеса", "group":"Тормоза", "system":"brakes", "keywords":["датчик abs передний правый", "датчик абс"], "diagnostic_flow":"", "repair_guide":""},
    "abs_wheel_sensor_rl": {"name":"Датчик ABS заднего левого колеса", "group":"Тормоза", "system":"brakes", "keywords":["датчик abs задний левый", "датчик абс"], "diagnostic_flow":"", "repair_guide":""},
    "abs_wheel_sensor_rr": {"name":"Датчик ABS заднего правого колеса", "group":"Тормоза", "system":"brakes", "keywords":["датчик abs задний правый", "датчик абс"], "diagnostic_flow":"", "repair_guide":""},
    "ignition_coil": {"name":"Модуль / трансформатор зажигания N152", "group":"Зажигание", "system":"electrical", "keywords":["модуль зажигания n152", "трансформатор зажигания", "катушка n152"], "diagnostic_flow":"engine_misfire", "repair_guide":""},
    "spark_plugs": {"name":"Свечи зажигания", "group":"Электрика", "system":"electrical", "keywords":["свечи зажигания", "свечи"], "diagnostic_flow":"engine_misfire", "repair_guide":""},
    "engine_ecu": {"name":"ЭБУ двигателя", "group":"Электрика", "system":"electrical", "keywords":["эбу двигателя", "блок управления двигателем"], "diagnostic_flow":"", "repair_guide":""},
    "wiring_harness": {"name":"Жгуты электропроводки", "group":"Электрика", "system":"electrical", "keywords":["жгут проводов", "электропроводка"], "diagnostic_flow":"", "repair_guide":""},
    "crankshaft_position_sensor": {"name":"Датчик положения коленвала", "group":"Электрика", "system":"electrical", "keywords":["датчик коленвала", "дпкв"], "diagnostic_flow":"", "repair_guide":""},
    "camshaft_position_sensor": {"name":"Датчик положения распредвала", "group":"Электрика", "system":"electrical", "keywords":["датчик распредвала", "дпрв"], "diagnostic_flow":"", "repair_guide":""},
    "front_left_door": {"name":"Передняя левая дверь", "group":"Кузов", "system":"body", "keywords":["передняя левая дверь"], "diagnostic_flow":"", "repair_guide":""},
    "front_right_door": {"name":"Передняя правая дверь", "group":"Кузов", "system":"body", "keywords":["передняя правая дверь"], "diagnostic_flow":"", "repair_guide":""},
    "rear_left_door": {"name":"Задняя левая дверь", "group":"Кузов", "system":"body", "keywords":["задняя левая дверь"], "diagnostic_flow":"", "repair_guide":""},
    "rear_right_door": {"name":"Задняя правая дверь", "group":"Кузов", "system":"body", "keywords":["задняя правая дверь"], "diagnostic_flow":"", "repair_guide":""},
    "windshield": {"name":"Лобовое стекло", "group":"Кузов", "system":"body", "keywords":["лобовое стекло", "ветровое стекло"], "diagnostic_flow":"", "repair_guide":""},
    "rear_window": {"name":"Заднее стекло", "group":"Кузов", "system":"body", "keywords":["заднее стекло"], "diagnostic_flow":"", "repair_guide":""},
    "side_mirrors": {"name":"Наружные зеркала", "group":"Кузов", "system":"body", "keywords":["зеркала", "боковые зеркала"], "diagnostic_flow":"", "repair_guide":""},
    "roof_rails": {"name":"Рейлинги крыши", "group":"Кузов", "system":"body", "keywords":["рейлинги", "рейлинги крыши"], "diagnostic_flow":"", "repair_guide":""},
    "dashboard": {"name":"Панель приборов", "group":"Салон", "system":"interior", "keywords":["панель приборов", "торпедо", "dashboard"], "diagnostic_flow":"", "repair_guide":""},
    "center_console": {"name":"Центральная консоль", "group":"Салон", "system":"interior", "keywords":["центральная консоль"], "diagnostic_flow":"", "repair_guide":""},
    "glove_box": {"name":"Перчаточный ящик", "group":"Салон", "system":"interior", "keywords":["перчаточный ящик", "бардачок"], "diagnostic_flow":"", "repair_guide":""},
    "pedal_assembly": {"name":"Педальный узел", "group":"Салон", "system":"interior", "keywords":["педальный узел", "педали"], "diagnostic_flow":"", "repair_guide":""},
    "cabin_filter": {"name":"Салонный фильтр", "group":"Салон", "system":"interior", "keywords":["салонный фильтр", "фильтр салона"], "diagnostic_flow":"", "repair_guide":""},
    "evaporator": {"name":"Испаритель кондиционера", "group":"Климат", "system":"climate", "keywords":["испаритель кондиционера"], "diagnostic_flow":"", "repair_guide":""},
    "receiver_drier": {"name":"Осушитель кондиционера", "group":"Климат", "system":"climate", "keywords":["осушитель кондиционера", "ресивер осушитель"], "diagnostic_flow":"", "repair_guide":""},
    "hvac_housing": {"name":"Корпус климатической установки / отопителя", "group":"Климат", "system":"climate", "keywords":["корпус климатической установки", "корпус отопителя"], "diagnostic_flow":"", "repair_guide":""},
    "fresh_air_blower_control_unit_j126": {"name":"Блок управления вентилятором приточного воздуха J126", "group":"Климат", "system":"climate", "keywords":["блок управления вентилятором j126", "регулятор вентилятора печки"], "diagnostic_flow":"", "repair_guide":""},
    "recirculation_air_flap": {"name":"Заслонка рециркуляции воздуха", "group":"Климат", "system":"climate", "keywords":["заслонка рециркуляции", "рециркуляция воздуха"], "diagnostic_flow":"", "repair_guide":""},
    "ac_expansion_valve": {"name":"Расширительный клапан кондиционера", "group":"Климат", "system":"climate", "keywords":["расширительный клапан кондиционера", "клапан испарителя"], "diagnostic_flow":"", "repair_guide":""},
    "ac_pressure_sensor_g65": {"name":"Датчик давления кондиционера G65", "group":"Климат", "system":"climate", "keywords":["датчик давления кондиционера", "датчик g65"], "diagnostic_flow":"", "repair_guide":""},
    "air_flap_actuators": {"name":"Заслонки и актуаторы климата", "group":"Климат", "system":"climate", "keywords":["заслонки климата", "актуатор заслонки"], "diagnostic_flow":"", "repair_guide":""},
    "headlamp_left": {"name":"Левая фара", "group":"Освещение", "system":"lighting", "keywords":["левая фара", "фара"], "diagnostic_flow":"", "repair_guide":""},
    "headlamp_right": {"name":"Правая фара", "group":"Освещение", "system":"lighting", "keywords":["правая фара", "фара"], "diagnostic_flow":"", "repair_guide":""},
    "fog_lamp_left": {"name":"Левая противотуманная фара", "group":"Освещение", "system":"lighting", "keywords":["левая противотуманка", "птф"], "diagnostic_flow":"", "repair_guide":""},
    "fog_lamp_right": {"name":"Правая противотуманная фара", "group":"Освещение", "system":"lighting", "keywords":["правая противотуманка", "птф"], "diagnostic_flow":"", "repair_guide":""},
    "tail_lamp_left": {"name":"Левый задний фонарь", "group":"Освещение", "system":"lighting", "keywords":["левый задний фонарь", "задний фонарь"], "diagnostic_flow":"", "repair_guide":""},
    "tail_lamp_right": {"name":"Правый задний фонарь", "group":"Освещение", "system":"lighting", "keywords":["правый задний фонарь", "задний фонарь"], "diagnostic_flow":"", "repair_guide":""},
    "license_plate_lamp": {"name":"Подсветка номерного знака", "group":"Освещение", "system":"lighting", "keywords":["подсветка номера", "лампа номера"], "diagnostic_flow":"", "repair_guide":""},
    "interior_lights": {"name":"Салонное освещение", "group":"Освещение", "system":"lighting", "keywords":["салонное освещение", "плафон"], "diagnostic_flow":"", "repair_guide":""},
    "driver_airbag": {"name":"Подушка безопасности водителя", "group":"Безопасность", "system":"safety", "keywords":["подушка водителя", "airbag"], "diagnostic_flow":"", "repair_guide":""},
    "passenger_airbag": {"name":"Подушка безопасности пассажира", "group":"Безопасность", "system":"safety", "keywords":["подушка пассажира", "airbag"], "diagnostic_flow":"", "repair_guide":""},
    "side_airbags": {"name":"Боковые подушки безопасности", "group":"Безопасность", "system":"safety", "keywords":["боковые подушки", "airbag"], "diagnostic_flow":"", "repair_guide":""},
    "seat_belts": {"name":"Ремни безопасности", "group":"Безопасность", "system":"safety", "keywords":["ремни безопасности", "ремень"], "diagnostic_flow":"", "repair_guide":""},
    "belt_pretensioners": {"name":"Преднатяжители ремней", "group":"Безопасность", "system":"safety", "keywords":["преднатяжители ремней", "преднатяжитель"], "diagnostic_flow":"", "repair_guide":""},
    "crash_sensors_front": {"name":"Передние датчики удара", "group":"Безопасность", "system":"safety", "keywords":["датчики удара", "датчик столкновения"], "diagnostic_flow":"", "repair_guide":""},
    "crash_sensors_side": {"name":"Боковые датчики удара", "group":"Безопасность", "system":"safety", "keywords":["боковой датчик удара", "датчик столкновения"], "diagnostic_flow":"", "repair_guide":""},
    "wiper_motor_front": {"name":"Мотор стеклоочистителя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["мотор дворников", "мотор стеклоочистителя"], "diagnostic_flow":"", "repair_guide":""},
    "wiper_linkage": {"name":"Трапеция стеклоочистителя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["трапеция дворников", "трапеция стеклоочистителя"], "diagnostic_flow":"", "repair_guide":""},
    "wiper_blades_front": {"name":"Передние щётки стеклоочистителя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["передние щетки", "дворники"], "diagnostic_flow":"", "repair_guide":""},
    "wiper_motor_rear": {"name":"Задний мотор стеклоочистителя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["задний дворник", "мотор заднего стеклоочистителя"], "diagnostic_flow":"", "repair_guide":""},
    "washer_pump": {"name":"Насос омывателя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["насос омывателя"], "diagnostic_flow":"", "repair_guide":""},
    "washer_reservoir": {"name":"Бачок омывателя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["бачок омывателя", "бачок стеклоомывателя"], "diagnostic_flow":"", "repair_guide":""},
    "rain_sensor": {"name":"Датчик дождя", "group":"Стекло и очистители", "system":"wipers_glass", "keywords":["датчик дождя"], "diagnostic_flow":"", "repair_guide":""},

    "timing_chain": {"name":"Цепь ГРМ", "group":"Двигатель", "system":"engine", "keywords":["цепь грм", "цепь cbzb"], "diagnostic_flow":"", "repair_guide":""},
    "timing_chain_tensioner": {"name":"Натяжитель цепи ГРМ", "group":"Двигатель", "system":"engine", "keywords":["натяжитель цепи"], "diagnostic_flow":"", "repair_guide":""},
    "timing_chain_guides": {"name":"Направляющие цепи ГРМ", "group":"Двигатель", "system":"engine", "keywords":["направляющие цепи"], "diagnostic_flow":"", "repair_guide":""},
    "timing_sprockets": {"name":"Звёздочки привода ГРМ", "group":"Двигатель", "system":"engine", "keywords":["звездочки грм"], "diagnostic_flow":"", "repair_guide":""},
    "timing_cover": {"name":"Крышка привода ГРМ", "group":"Двигатель", "system":"engine", "keywords":["крышка грм"], "diagnostic_flow":"", "repair_guide":""},
    "oil_pump": {"name":"Масляный насос", "group":"Двигатель", "system":"engine", "keywords":["масляный насос"], "diagnostic_flow":"", "repair_guide":""},
    "oil_pickup": {"name":"Маслоприёмник", "group":"Двигатель", "system":"engine", "keywords":["маслоприемник"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_tank": {"name":"Топливный бак", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["топливный бак"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_level_sender": {"name":"Датчик уровня топлива", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["датчик уровня топлива"], "diagnostic_flow":"", "repair_guide":""},
    "fuel_pressure_sensor": {"name":"Датчик давления топлива", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["датчик давления топлива", "g247"], "diagnostic_flow":"", "repair_guide":""},
    "high_pressure_fuel_pump": {"name":"Насос высокого давления топлива", "group":"Топливо и впуск", "system":"fuel_intake", "keywords":["тнвд", "насос высокого давления"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_dual_clutch": {"name":"Двойное сцепление DSG 0AM", "group":"Коробка передач", "system":"transmission", "keywords":["двойное сцепление dsg", "dq200 сцепление"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_mechatronic": {"name":"Мехатроник DSG 0AM", "group":"Коробка передач", "system":"transmission", "keywords":["мехатроник dsg", "мехатроник dq200"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_input_shafts": {"name":"Первичные валы DSG 0AM", "group":"Коробка передач", "system":"transmission", "keywords":["первичные валы dsg"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_output_shafts": {"name":"Выходные валы DSG 0AM", "group":"Коробка передач", "system":"transmission", "keywords":["выходные валы dsg"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_sensors": {"name":"Датчики DSG 0AM", "group":"Коробка передач", "system":"transmission", "keywords":["датчики dsg"], "diagnostic_flow":"", "repair_guide":""},
    "dsg_selector_module": {"name":"Электронный модуль селектора DSG", "group":"Коробка передач", "system":"transmission", "keywords":["модуль селектора dsg"], "diagnostic_flow":"", "repair_guide":""},
    "steering_knuckle": {"name":"Поворотный кулак", "group":"Подвеска", "system":"suspension", "keywords":["поворотный кулак"], "diagnostic_flow":"", "repair_guide":""},
    "front_stabilizer_bushings": {"name":"Втулки переднего стабилизатора", "group":"Подвеска", "system":"suspension", "keywords":["втулки стабилизатора"], "diagnostic_flow":"", "repair_guide":""},
    "rear_suspension_arm": {"name":"Рычаг задней подвески FWD", "group":"Подвеска", "system":"suspension", "keywords":["рычаг задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_suspension_track_rod": {"name":"Поперечная тяга задней подвески FWD", "group":"Подвеска", "system":"suspension", "keywords":["поперечная тяга задней подвески"], "diagnostic_flow":"", "repair_guide":""},
    "rear_shock_absorber": {"name":"Задний амортизатор", "group":"Подвеска", "system":"suspension", "keywords":["задний амортизатор"], "diagnostic_flow":"", "repair_guide":""},
    "rear_axle_carrier": {"name":"Носитель задней оси FWD", "group":"Подвеска", "system":"suspension", "keywords":["носитель задней оси"], "diagnostic_flow":"", "repair_guide":""},
    "brake_carrier": {"name":"Скоба суппорта", "group":"Тормоза", "system":"brakes", "keywords":["скоба суппорта"], "diagnostic_flow":"", "repair_guide":""},
    "dust_shield": {"name":"Защитный щиток тормозного диска", "group":"Тормоза", "system":"brakes", "keywords":["защитный щиток тормозного диска", "пыльник тормозного диска"], "diagnostic_flow":"", "repair_guide":""},
    "brake_guide_pins": {"name":"Направляющие суппорта", "group":"Тормоза", "system":"brakes", "keywords":["направляющие суппорта"], "diagnostic_flow":"", "repair_guide":""},
    "parking_brake_cable": {"name":"Трос стояночного тормоза", "group":"Тормоза", "system":"brakes", "keywords":["трос ручника", "трос стояночного тормоза"], "diagnostic_flow":"", "repair_guide":""},
    "haldex_coupling": {"name":"Муфта полного привода Haldex", "group":"Коробка передач", "system":"transmission", "requires_drivetrain":"AWD", "keywords":["муфта haldex"], "diagnostic_flow":"", "repair_guide":""},
    "propshaft": {"name":"Карданный вал полного привода", "group":"Коробка передач", "system":"transmission", "requires_drivetrain":"AWD", "keywords":["карданный вал"], "diagnostic_flow":"", "repair_guide":""},
    "propshaft_center_bearing": {"name":"Промежуточная опора карданного вала", "group":"Коробка передач", "system":"transmission", "requires_drivetrain":"AWD", "keywords":["опора кардана"], "diagnostic_flow":"", "repair_guide":""},
    "rear_drive_shaft_left": {"name":"Левый задний привод 4×4", "group":"Коробка передач", "system":"transmission", "requires_drivetrain":"AWD", "keywords":["левый задний привод"], "diagnostic_flow":"", "repair_guide":""},
    "rear_drive_shaft_right": {"name":"Правый задний привод 4×4", "group":"Коробка передач", "system":"transmission", "requires_drivetrain":"AWD", "keywords":["правый задний привод"], "diagnostic_flow":"", "repair_guide":""},
    "front_wheel_arch_liner": {"name":"Передний подкрылок", "group":"Кузов", "system":"body", "keywords":["передний подкрылок"], "diagnostic_flow":"", "repair_guide":""},
    "rear_wheel_arch_liner": {"name":"Задний подкрылок", "group":"Кузов", "system":"body", "keywords":["задний подкрылок"], "diagnostic_flow":"", "repair_guide":""},
    "underbody_guard": {"name":"Нижняя защита кузова", "group":"Кузов", "system":"body", "keywords":["защита днища"], "diagnostic_flow":"", "repair_guide":""},
}

static func assemblies_for_system(system_id: String) -> Array:
    var system: Dictionary = SYSTEMS.get(system_id, {})
    if system.is_empty():
        return []
    var result: Array[Dictionary] = []
    var assigned: Dictionary = {}
    for source_value in ASSEMBLY_GROUPS.get(system_id, []):
        var source: Dictionary = source_value
        var assembly := source.duplicate(true)
        assembly["system"] = system_id
        assembly["focus"] = Vector3(0.0, 1.0, 0.0)
        assembly["distance"] = 6.5
        result.append(assembly)
        for part_id in assembly.get("parts", []):
            assigned[str(part_id)] = true
    var remaining: Array[String] = []
    for part_id in system.get("parts", []):
        if not assigned.has(str(part_id)):
            remaining.append(str(part_id))
    if not remaining.is_empty():
        result.append({"id":system_id + "_components", "name":"Остальные компоненты", "system":system_id, "parts":remaining, "focus":Vector3(0.0, 1.0, 0.0), "distance":6.5})
    return result

static func all_assemblies() -> Array:
    var result: Array[Dictionary] = []
    for system_id in SYSTEMS.keys():
        result.append_array(assemblies_for_system(str(system_id)))
    return result

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
