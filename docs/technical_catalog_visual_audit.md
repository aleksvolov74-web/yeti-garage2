# Technical catalog visual audit — 2026-10-06

## Result

All 90 image assignments were opened and visually reviewed with marker overlays. The two `srs_sensors` marker coordinates were corrected after full-resolution inspection; its image was not changed. Static file, JSON, part-ID and marker checks passed. Runtime UI and Android export could not be run because Godot is unavailable in this environment.

Sections: 24; nodes: 90; images: 90; empty: 0; unique paths: 88; markers: 376.

- PASS: 57
- NEEDS_REVIEW: 33
- FAIL_IMAGE: 0
- FAIL_MARKERS: 0
- FAIL_ARCHITECTURE: 0
- FAIL_DATA: 0

`airbags` is now `REFERENCE_ONLY`, matching its documented unconfirmed PR/market fitment. All four AWD nodes remain `REFERENCE_ONLY` and explicitly not installed on this FWD vehicle.

## Node-by-node visual audit

| node_id | Название | Image | Verification | Part IDs | Markers | Visual / marker status |
|---|---|---|---|---:|---:|---|
| `engine_complete` | Двигатель в сборе | `assets/technical_catalog/engine/engine_complete.webp` | VERIFIED_ARCHITECTURE | `engine_block`, `cylinder_head`, `engine_mount`, `turbocharger`, `alternator`, `accessory_belt_drive`, `starter` | 7 | PASS / marker targets visually checked |
| `engine_bottom_end` | Блок цилиндров и кривошипный механизм | `assets/technical_catalog/engine/engine_bottom_end.webp` | VERIFIED_ARCHITECTURE | `engine_block`, `crankshaft`, `piston_group`, `connecting_rods` | 4 | PASS / marker targets visually checked |
| `engine_upper_end` | Головка и клапанный механизм | `assets/technical_catalog/engine/engine_upper_end.webp` | VERIFIED_ARCHITECTURE | `cylinder_head`, `camshafts`, `valve_cover` | 3 | PASS / marker targets visually checked |
| `engine_block_group` | Блок и кривошипно-шатунный механизм | `assets/technical_catalog/engine/engine_bottom_end.webp` | VERIFIED_ARCHITECTURE | `engine_block`, `crankshaft`, `piston_group`, `connecting_rods` | 4 | PASS / marker targets visually checked |
| `cylinder_head_group` | Головка блока и клапанный механизм | `assets/technical_catalog/engine/engine_upper_end.webp` | VERIFIED_ARCHITECTURE | `cylinder_head`, `camshafts`, `valve_cover` | 3 | PASS / marker targets visually checked |
| `engine_mounts` | Опоры двигателя | `assets/technical_catalog/engine/engine_mounts.webp` | VERIFIED_ARCHITECTURE | `engine_mount` | 1 | PASS / marker targets visually checked |
| `engine_accessories` | Навесное оборудование | `assets/technical_catalog/engine/engine_accessories.webp` | VERIFIED_ARCHITECTURE | `alternator`, `accessory_belt_drive`, `starter` | 3 | PASS / marker targets visually checked |
| `timing_drive_node` | Привод ГРМ | `assets/technical_catalog/timing/timing_drive_node.webp` | VERIFIED_ARCHITECTURE | `timing_drive`, `timing_chain`, `timing_chain_tensioner`, `timing_chain_guides`, `timing_sprockets`, `timing_cover` | 6 | PASS / marker targets visually checked |
| `timing_chain` | Цепь, натяжитель и направляющие | `assets/technical_catalog/timing/timing_chain.webp` | VERIFIED_ARCHITECTURE | `timing_chain`, `timing_chain_tensioner`, `timing_chain_guides` | 3 | PASS / marker targets visually checked |
| `timing_gears` | Звёздочки и крышка привода | `assets/technical_catalog/timing/timing_gears.webp` | VERIFIED_ARCHITECTURE | `timing_sprockets`, `timing_cover` | 2 | PASS / marker targets visually checked |
| `air_path` | Воздушный тракт | `assets/technical_catalog/intake/air_path.webp` | VERIFIED_ARCHITECTURE | `air_filter`, `air_filter_housing`, `throttle_body`, `intake_manifold`, `charge_air_cooler`, `intake_manifold_pressure_sensor`, `charge_pressure_sensor` | 7 | PASS / marker targets visually checked |
| `boost_group` | Турбокомпрессор и управление наддувом | `assets/technical_catalog/intake/boost_group.webp` | VERIFIED_ARCHITECTURE | `turbocharger`, `exhaust_manifold`, `charge_pressure_regulator_v465`, `turbo_oil_feed_line`, `turbo_coolant_lines`, `charge_air_pipe` | 6 | PASS / marker targets visually checked |
| `fuel_storage` | Бак, модуль и насос | `assets/technical_catalog/fuel/fuel_storage.webp` | REFERENCE_ONLY | `fuel_tank`, `fuel_pump`, `fuel_level_sender`, `fuel_filter`, `evap_charcoal_canister`, `fuel_tank_straps` | 6 | NEEDS_REVIEW / marker targets visually checked |
| `fuel_delivery` | Магистрали, рампа и форсунки | `assets/technical_catalog/fuel/fuel_delivery.webp` | VERIFIED_ARCHITECTURE | `high_pressure_fuel_pump`, `fuel_rail`, `fuel_pressure_sensor_g247`, `fuel_pressure_control_valve_n276`, `injectors` | 5 | PASS / marker targets visually checked |
| `fuel_sensors` | Датчики топливной системы | `assets/technical_catalog/fuel/fuel_sensors.webp` | VERIFIED_ARCHITECTURE | `fuel_pressure_sensor`, `fuel_level_sender` | 2 | PASS / marker targets visually checked |
| `radiator_pack` | Радиатор и вентилятор | `assets/technical_catalog/cooling/radiator_pack.webp` | VERIFIED_ARCHITECTURE | `radiator`, `low_temperature_radiator`, `cooling_fan`, `cooling_fan_secondary`, `coolant_expansion_tank`, `coolant_hoses` | 6 | PASS / marker targets visually checked |
| `coolant_circuit` | Контур охлаждения двигателя | `assets/technical_catalog/cooling/coolant_circuit.webp` | REFERENCE_ONLY | `coolant_expansion_tank`, `radiator`, `water_pump`, `thermostat`, `coolant_recirculation_pump_v50`, `charge_air_cooler`, `engine_oil_cooler`, `turbocharger`, `coolant_hoses` | 9 | NEEDS_REVIEW / marker targets visually checked |
| `coolant_reservoir` | Расширительный бачок | `assets/technical_catalog/cooling/coolant_reservoir.webp` | VERIFIED_ARCHITECTURE | `coolant_expansion_tank` | 1 | PASS / marker targets visually checked |
| `oil_pump_circuit` | Масляный насос и магистрали | `assets/technical_catalog/engine/oil_pump_circuit.webp` | VERIFIED_ARCHITECTURE | `oil_pump`, `oil_pump_drive`, `oil_pickup` | 3 | PASS / marker targets visually checked |
| `oil_filter_node` | Масляный фильтр | `assets/technical_catalog/engine/oil_filter.webp` | VERIFIED_ARCHITECTURE | `oil_filter` | 1 | PASS / marker targets visually checked |
| `oil_pan_node` | Масляный поддон | `assets/technical_catalog/engine/oil_pan.webp` | VERIFIED_ARCHITECTURE | `oil_pan` | 1 | PASS / marker targets visually checked |
| `exhaust_front` | Коллектор и передняя часть выпуска | `assets/technical_catalog/exhaust/exhaust_front.webp` | VERIFIED_ARCHITECTURE | `exhaust_manifold`, `turbocharger`, `turbo_heat_shield`, `front_exhaust_pipe`, `exhaust_flex_joint` | 5 | PASS / marker targets visually checked |
| `exhaust_aftertreatment` | Катализатор и кислородные датчики | `assets/technical_catalog/exhaust/exhaust_aftertreatment.webp` | VERIFIED_ARCHITECTURE | `catalytic_converter`, `oxygen_sensor`, `catalyst_heat_shield`, `exhaust_flex_joint`, `front_exhaust_pipe`, `exhaust_clamp` | 6 | PASS / marker targets visually checked |
| `exhaust_rear` | Трубы, резонатор и глушитель | `assets/technical_catalog/exhaust/exhaust_rear.webp` | VERIFIED_ARCHITECTURE | `exhaust_resonator`, `rear_muffler`, `exhaust_clamp`, `exhaust_mounts`, `exhaust_heat_shield` | 5 | PASS / marker targets visually checked |
| `clutch_group` | Сцепление и маховик | `assets/technical_catalog/dsg/clutch_group.webp` | VERIFIED_ARCHITECTURE | `flywheel`, `dsg_dual_clutch`, `clutch_k1`, `clutch_k2`, `clutch_engagement_levers`, `clutch` | 5 | PASS / marker targets visually checked |
| `gearbox_group` | Коробка передач и дифференциал | `assets/technical_catalog/dsg/gearbox_group.webp` | REFERENCE_ONLY | `gearbox_housing`, `dsg_input_shafts`, `dsg_output_shafts`, `differential`, `dsg_mechatronics`, `gearbox` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `gear_selector` | Механизм и тросы выбора передач | `assets/technical_catalog/dsg/gear_selector.webp` | VERIFIED_ARCHITECTURE | `selector_mechanism`, `gear_selector_cables`, `gearbox_selector_lever`, `selector_cable_support`, `dsg_selector_module` | 4 | PASS / marker targets visually checked |
| `dsg_mechatronics` | Мехатроник DSG 0AM / DQ200 | `assets/technical_catalog/dsg/dsg_mechatronics.webp` | REFERENCE_ONLY | `dsg_mechatronics`, `dsg_mechatronics_connector`, `dsg_mechatronics_actuators` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `left_drive` | Левый передний привод | `assets/technical_catalog/front_drive/left_drive.webp` | VERIFIED_ARCHITECTURE | `drive_shaft`, `cv_joint_inner`, `cv_joint_outer`, `outer_cv_boot`, `inner_cv_boot` | 5 | PASS / marker targets visually checked |
| `right_drive` | Правый передний привод | `assets/technical_catalog/front_drive/right_drive.webp` | VERIFIED_ARCHITECTURE | `drive_shaft`, `cv_joint_inner`, `cv_joint_outer`, `outer_cv_boot`, `inner_cv_boot` | 5 | PASS / marker targets visually checked |
| `front_suspension_overview` | Передняя подвеска в сборе | `assets/technical_catalog/front_suspension/front_suspension_overview.webp` | VERIFIED_ARCHITECTURE | `subframe`, `control_arm`, `ball_joint`, `strut`, `spring`, `strut_mount`, `anti_roll_bar`, `front_stabilizer_bushings`, `steering_knuckle` | 9 | PASS / marker targets visually checked |
| `front_left_corner` | Левая передняя сторона | `assets/technical_catalog/front_suspension/front_left_corner.webp` | VERIFIED_ARCHITECTURE | `control_arm`, `ball_joint`, `strut`, `spring`, `strut_mount`, `stabilizer_link`, `hub`, `wheel_bearing`, `wheel` | 9 | PASS / marker targets visually checked |
| `front_right_corner` | Правая передняя сторона | `assets/technical_catalog/front_suspension/front_right_corner.webp` | VERIFIED_ARCHITECTURE | `control_arm`, `ball_joint`, `strut`, `spring`, `strut_mount`, `stabilizer_link` | 6 | PASS / marker targets visually checked |
| `front_axle_carrier` | Подрамник и стабилизатор | `assets/technical_catalog/front_suspension/front_axle_carrier.webp` | VERIFIED_ARCHITECTURE | `subframe`, `anti_roll_bar`, `suspension_bushings` | 3 | PASS / marker targets visually checked |
| `front_subframe_arms` | Подрамник и нижние рычаги | `assets/technical_catalog/front_suspension/front_subframe_arms.webp` | VERIFIED_ARCHITECTURE | `subframe`, `control_arm_left`, `control_arm_right`, `suspension_bushings`, `ball_joint` | 5 | PASS / marker targets visually checked |
| `front_strut` | Амортизационная стойка и пружина | `assets/technical_catalog/front_suspension/front_strut.webp` | VERIFIED_ARCHITECTURE | `strut_mount`, `strut_bearing`, `spring`, `bump_stop`, `strut_dust_boot`, `strut` | 6 | PASS / marker targets visually checked |
| `front_knuckle_hub` | Поворотный кулак и ступица | `assets/technical_catalog/front_suspension/front_knuckle_hub.webp` | VERIFIED_ARCHITECTURE | `cv_joint_outer`, `steering_knuckle`, `wheel_bearing`, `hub`, `dust_shield`, `ball_joint` | 6 | PASS / marker targets visually checked |
| `front_hub_bearing` | Ступица и подшипник | `assets/technical_catalog/front_suspension/front_hub_bearing.webp` | VERIFIED_ARCHITECTURE | `hub`, `wheel_bearing` | 2 | PASS / marker targets visually checked |
| `front_brake_at_hub` | Тормозной механизм у ступицы | `assets/technical_catalog/front_suspension/front_brake_at_hub.webp` | VERIFIED_ARCHITECTURE | `brake_disc`, `brake_caliper`, `brake_pads`, `brake_hose` | 4 | PASS / marker targets visually checked |
| `front_drive_at_hub` | Наружный шарнир привода | `assets/technical_catalog/front_suspension/front_drive_at_hub.webp` | VERIFIED_ARCHITECTURE | `drive_shaft`, `cv_joint_outer`, `outer_cv_boot` | 3 | PASS / marker targets visually checked |
| `front_stabilizer` | Стабилизатор поперечной устойчивости | `assets/technical_catalog/front_suspension/front_stabilizer.webp` | VERIFIED_ARCHITECTURE | `anti_roll_bar`, `stabilizer_link` | 2 | PASS / marker targets visually checked |
| `rear_suspension_overview` | Задняя подвеска в сборе | `assets/technical_catalog/rear_suspension/rear_suspension_overview.webp` | VERIFIED_ARCHITECTURE | `rear_subframe`, `rear_upper_control_arm`, `rear_lower_control_arm`, `rear_trailing_arm`, `rear_track_rod`, `spring`, `rear_shock_absorber`, `rear_anti_roll_bar`, `rear_hub_carrier` | 9 | PASS / marker targets visually checked |
| `rear_carrier` | Подрамник / балка и рычаги | `assets/technical_catalog/rear_suspension/rear_carrier.webp` | REFERENCE_ONLY | `rear_subframe`, `rear_upper_control_arm`, `rear_lower_control_arm`, `rear_trailing_arm`, `rear_track_rod`, `rear_suspension_bushings` | 6 | NEEDS_REVIEW / marker targets visually checked |
| `rear_springs_dampers` | Пружины и амортизаторы | `assets/technical_catalog/rear_suspension/rear_springs_dampers.webp` | VERIFIED_ARCHITECTURE | `rear_spring_upper_seat`, `spring`, `rear_spring_lower_seat`, `rear_shock_absorber`, `rear_shock_upper_mount`, `rear_shock_bump_stop` | 6 | PASS / marker targets visually checked |
| `rear_hub` | Задние ступицы и подшипники | `assets/technical_catalog/rear_suspension/rear_hub.webp` | VERIFIED_ARCHITECTURE | `rear_hub_carrier`, `hub`, `wheel_bearing`, `rear_abs_encoder_ring`, `rear_wheel_speed_sensor`, `dust_shield`, `brake_disc` | 7 | PASS / marker targets visually checked |
| `steering_column` | Рулевое колесо и колонка | `assets/technical_catalog/steering/steering_column.webp` | VERIFIED_ARCHITECTURE | `steering_wheel`, `steering_column`, `steering_angle_sensor` | 3 | PASS / marker targets visually checked |
| `steering_rack` | Рулевая рейка и усилитель | `assets/technical_catalog/steering/steering_rack.webp` | VERIFIED_ARCHITECTURE | `steering_rack`, `power_steering_motor`, `steering_input_shaft`, `steering_tie_rod`, `tie_rod_end`, `steering_rack_boot` | 6 | PASS / marker targets visually checked |
| `steering_linkage` | Тяги и наконечники | `assets/technical_catalog/steering/steering_linkage.webp` | VERIFIED_ARCHITECTURE | `steering_tie_rod`, `tie_rod_end`, `steering_rack_boot`, `tie_rod_lock_nut` | 4 | PASS / marker targets visually checked |
| `front_brake_assembly` | Диск, суппорт и колодки | `assets/technical_catalog/front_suspension/front_brake_assembly.webp` | VERIFIED_ARCHITECTURE | `brake_caliper`, `brake_pads`, `brake_carrier`, `brake_guide_pins`, `brake_disc`, `brake_hose`, `hub` | 7 | PASS / marker targets visually checked |
| `front_brake_hose` | Скоба, направляющие и шланг | `assets/technical_catalog/front_brakes/front_brake_hose.webp` | VERIFIED_ARCHITECTURE | `brake_carrier`, `brake_guide_pins`, `brake_hose`, `abs_wheel_sensor_fl` | 4 | PASS / marker targets visually checked |
| `rear_brake_assembly` | Задний тормозной механизм | `assets/technical_catalog/rear_brakes/rear_brake_assembly.webp` | VERIFIED_ARCHITECTURE | `brake_disc`, `brake_caliper`, `brake_carrier`, `brake_guide_pins`, `brake_pads`, `brake_hose`, `abs_wheel_sensor_rl` | 7 | PASS / marker targets visually checked |
| `parking_brake` | Стояночный тормоз | `assets/technical_catalog/rear_brakes/parking_brake.webp` | VERIFIED_ARCHITECTURE | `parking_brake_cable`, `brake_caliper` | 2 | PASS / marker targets visually checked |
| `brake_hydraulics` | Главный цилиндр, усилитель и бачок | `assets/technical_catalog/brakes/brake_hydraulics.webp` | REFERENCE_ONLY | `brake_fluid_reservoir`, `brake_master_cylinder`, `brake_booster`, `brake_pushrod`, `brake_lines`, `abs_unit` | 6 | NEEDS_REVIEW / marker targets visually checked |
| `abs_esp_block` | Блок ABS/ESP и магистрали | `assets/technical_catalog/brakes/abs_esp_block.webp` | REFERENCE_ONLY | `abs_unit`, `abs_hydraulic_unit`, `abs_control_unit`, `abs_pump_motor`, `abs_mounting_bracket` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `wheel_sensors` | Датчики скорости колёс | `assets/technical_catalog/brakes/wheel_sensors.webp` | VERIFIED_ARCHITECTURE | `wheel_speed_sensor`, `wheel_speed_sensor_connector`, `hub`, `abs_encoder_ring`, `wheel_bearing_housing` | 5 | PASS / marker targets visually checked |
| `angle_drive` | Угловая передача | `assets/technical_catalog/4x4_reference/angle_drive.webp` | REFERENCE_ONLY | `gearbox`, `drive_shaft` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `propshaft` | Карданный вал и опоры | `assets/technical_catalog/4x4_reference/propshaft.webp` | REFERENCE_ONLY | `propshaft`, `propshaft_center_bearing` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `haldex` | Муфта Haldex | `assets/technical_catalog/4x4_reference/haldex.webp` | REFERENCE_ONLY | `haldex_coupling` | 1 | NEEDS_REVIEW / marker targets visually checked |
| `rear_differential` | Задний редуктор и приводы | `assets/technical_catalog/4x4_reference/rear_differential.webp` | REFERENCE_ONLY | `differential`, `haldex_coupling`, `rear_drive_shaft_left`, `rear_drive_shaft_right` | 4 | NEEDS_REVIEW / marker targets visually checked |
| `heater_box` | Корпус отопителя и радиатор печки | `assets/technical_catalog/climate/heater_box.webp` | VERIFIED_ARCHITECTURE | `heater_core`, `evaporator`, `air_flap_actuators`, `hvac_housing`, `cabin_filter` | 5 | PASS / marker targets visually checked |
| `blower` | Вентилятор и воздушные заслонки | `assets/technical_catalog/climate/blower.webp` | VERIFIED_ARCHITECTURE | `blower_motor`, `air_flap_actuators`, `cabin_filter`, `fresh_air_blower_control_unit_j126`, `recirculation_air_flap` | 5 | PASS / marker targets visually checked |
| `ac_circuit` | Компрессор, конденсер и испаритель | `assets/technical_catalog/climate/ac_circuit.webp` | VERIFIED_ARCHITECTURE | `ac_compressor`, `condenser`, `receiver_drier`, `ac_expansion_valve`, `ac_pressure_sensor_g65`, `evaporator` | 6 | PASS / marker targets visually checked |
| `power_start` | Аккумулятор, генератор и стартер | `assets/technical_catalog/electrical/power_start.webp` | REFERENCE_ONLY | `battery`, `alternator`, `starter`, `battery_positive_cable`, `battery_ground_cable`, `battery_terminal_clamps` | 6 | NEEDS_REVIEW / marker targets visually checked |
| `fuses_relays` | Предохранители и реле | `assets/technical_catalog/electrical/fuses_relays.webp` | REFERENCE_ONLY | `fuse_box`, `relay_carrier`, `high_current_fuse_block`, `automotive_relays`, `blade_fuses` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `control_units` | Блоки управления и датчики двигателя | `assets/technical_catalog/electrical/control_units.webp` | REFERENCE_ONLY | `engine_ecu`, `body_control_module`, `crankshaft_position_sensor`, `camshaft_position_sensor`, `control_unit_connectors` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `wiring` | Жгуты и точки массы | `assets/technical_catalog/electrical/wiring.webp` | REFERENCE_ONLY | `wiring_harness`, `engine_bay_wiring_harness`, `cabin_wiring_harness`, `ground_straps`, `bulkhead_wiring_grommet` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `ignition` | Система зажигания | `assets/technical_catalog/ignition/ignition.webp` | VERIFIED_ARCHITECTURE | `ignition_coil`, `ignition_cables`, `spark_plugs`, `camshaft_position_sensor`, `crankshaft_position_sensor` | 5 | PASS / marker targets visually checked |
| `front_lamps` | Передние фары и противотуманные фонари | `assets/technical_catalog/lighting/front_lamps.webp` | REFERENCE_ONLY | `headlamp_left`, `headlamp_right`, `fog_lamp_left`, `fog_lamp_right`, `headlamp_bulbs`, `headlamp_level_actuator` | 6 | NEEDS_REVIEW / marker targets visually checked |
| `rear_lamps` | Задние фонари и подсветка номера | `assets/technical_catalog/lighting/rear_lamps.webp` | REFERENCE_ONLY | `tail_lamp_left`, `tail_lamp_right`, `tail_lamp_bulb_carrier`, `rear_lamp_connector`, `license_plate_lamp` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `interior_lamps` | Освещение салона | `assets/technical_catalog/lighting/interior_lamps.webp` | REFERENCE_ONLY | `interior_lights`, `rear_interior_light`, `luggage_compartment_lamp`, `interior_light_bulbs`, `interior_light_connector` | 5 | NEEDS_REVIEW / marker targets visually checked |
| `body_front` | Передняя часть, капот и бамперы | `assets/technical_catalog/body/body_front.webp` | REFERENCE_ONLY | `front_bumper`, `hood`, `front_fender` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `doors` | Двери, замки, ручки и стеклоподъёмники | `assets/technical_catalog/body/doors.webp` | REFERENCE_ONLY | `front_left_door`, `front_right_door`, `rear_left_door`, `rear_right_door` | 4 | NEEDS_REVIEW / marker targets visually checked |
| `body_rear` | Дверь багажника и подкрылки | `assets/technical_catalog/body/body_rear.webp` | REFERENCE_ONLY | `tailgate`, `roof_rails` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `body_protection` | Защиты и подкрылки | `assets/technical_catalog/body/body_protection.webp` | REFERENCE_ONLY | `front_wheel_arch_liner`, `rear_wheel_arch_liner`, `underbody_guard` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `mirrors` | Наружные зеркала | `assets/technical_catalog/body/mirrors.webp` | VERIFIED_ARCHITECTURE | `side_mirrors` | 1 | PASS / marker targets visually checked |
| `glazing` | Лобовое и заднее стекло | `assets/technical_catalog/body/glazing.webp` | REFERENCE_ONLY | `windshield`, `rear_window` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `front_wipers` | Передний механизм стеклоочистителя | `assets/technical_catalog/body/front_wipers.webp` | VERIFIED_ARCHITECTURE | `wiper_motor_front`, `wiper_linkage`, `wiper_blades_front` | 3 | PASS / marker targets visually checked |
| `rear_wiper` | Задний стеклоочиститель | `assets/technical_catalog/body/rear_wiper.webp` | VERIFIED_ARCHITECTURE | `wiper_motor_rear` | 1 | PASS / marker targets visually checked |
| `washers` | Омыватели, насос и бачок | `assets/technical_catalog/body/washers.webp` | REFERENCE_ONLY | `washer_pump`, `washer_reservoir`, `rain_sensor` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `dashboard` | Панель приборов и передняя панель | `assets/technical_catalog/interior/dashboard.webp` | REFERENCE_ONLY | `dashboard`, `instrument_cluster`, `infotainment`, `glove_box` | 4 | NEEDS_REVIEW / marker targets visually checked |
| `console` | Центральная консоль и педальный узел | `assets/technical_catalog/interior/console.webp` | REFERENCE_ONLY | `center_console`, `pedal_assembly` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `seats` | Передние и задние сиденья | `assets/technical_catalog/interior/seats.webp` | REFERENCE_ONLY | `driver_seat`, `passenger_seat`, `rear_seat` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `interior_trim` | Дверные карты, потолок и багажник | `assets/technical_catalog/interior/interior_trim.webp` | REFERENCE_ONLY | `front_left_door`, `tailgate` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `airbags` | Подушки безопасности | `assets/technical_catalog/safety/airbags.webp` | REFERENCE_ONLY | `driver_airbag`, `passenger_airbag`, `side_airbags` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `belts` | Ремни и преднатяжители | `assets/technical_catalog/safety/belts.webp` | VERIFIED_ARCHITECTURE | `seat_belts`, `belt_pretensioners` | 2 | PASS / marker targets visually checked |
| `srs_sensors` | Датчики удара и блок SRS | `assets/technical_catalog/safety/srs_sensors.webp` | REFERENCE_ONLY | `crash_sensors_front`, `crash_sensors_side` | 2 | NEEDS_REVIEW / marker targets visually checked |
| `filters` | Фильтры | `assets/technical_catalog/maintenance/filters.webp` | REFERENCE_ONLY | `oil_filter`, `air_filter`, `fuel_filter`, `cabin_filter` | 4 | NEEDS_REVIEW / marker targets visually checked |
| `fluids` | Масла и технические жидкости | `assets/technical_catalog/maintenance/fluids.webp` | REFERENCE_ONLY | `oil_system`, `coolant_expansion_tank`, `brake_fluid_reservoir` | 3 | NEEDS_REVIEW / marker targets visually checked |
| `service_ignition` | Свечи и ременной привод | `assets/technical_catalog/maintenance/service_ignition.webp` | VERIFIED_ARCHITECTURE | `spark_plugs`, `accessory_belt_drive` | 2 | PASS / marker targets visually checked |
| `service_brakes` | Тормозные расходники | `assets/technical_catalog/maintenance/service_brakes.webp` | REFERENCE_ONLY | `brake_pads`, `brake_disc` | 2 | NEEDS_REVIEW / marker targets visually checked |

## Marker correction

### `srs_sensors`

- `crash_sensors_front`, marker 1: moved from `(0.24, 0.60)` to `(0.26, 0.565)`, onto the visible front sensor module.
- `crash_sensors_side`, marker 2: moved from `(0.80, 0.55)` to `(0.82, 0.50)`, onto the visible side sensor module.
- Image path `assets/technical_catalog/safety/srs_sensors.webp` unchanged. Status stays `REFERENCE_ONLY`; exact sensor count and positions are variant-dependent.

## Technical checks

- All 88 WebP files decoded; none is empty and each is at least 256×256.
- All 90 `res://` image paths resolve. Two pairs intentionally share node-appropriate engine visuals.
- All node and marker part IDs resolve to `PartCatalogService`; marker IDs occur in the owning node part list.
- Marker numbers are unique per node; all 376 x/y coordinates are within `[0,1]`.
- `git diff --check` and SHA256 verification passed after metadata generation.
- Godot import, runtime catalog validator, startup/UI interaction smoke, Android export, version bump, commit, push, GitHub Actions and APK artifact remain unrun. No release is claimed.
