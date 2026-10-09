# Исправление известных замечаний — промежуточный результат

База: `3cd1b892be568aaac5aea1fe5b2f3bf448427da9`. Новый глобальный аудит не выполнялся. Пять исправленных узлов CBZB, все WebP, part_id, версия 0.20.29 / 69 и main сохранены.

35 координат исправлены по реально видимым категориям деталей. Все эти позиции остаются REFERENCE_ONLY по точному исполнению. Исправление локальной позиции не делает ошибочную сборку пригодной: для таких схем весь overlay отключён.

Остаются 12 исходных FAIL_MARKER и 22 исходных NEEDS_REVIEW. Координаты для них не придуманы, статусы не заменены на PASS. Нужен единый пакет для 21 узла FWD и 2 справочных узлов AWD.

Обнаружены 7 явно неверных архитектур изображений; ещё 16 схем требуют замены из-за отсутствующих/неидентифицированных деталей или недоказанной сборки. 16 прежних VERIFIED_ARCHITECTURE понижены до REFERENCE_ONLY. Итог: 36 VERIFIED_ARCHITECTURE / 54 REFERENCE_ONLY, 90/90 изображений, 376 записей маркеров.

## Изменённые координаты

| node_id | № | part_id (не изменён) | Было x/y | Стало x/y | Доказательство |
|---|---|---|---|---|---|
| timing_drive_node | 1 | `timing_drive` | [0.46, 0.47] | [0.38, 0.5] | Видимая левая ветвь цепи; категория цепного привода, не точная геометрия CBZB. |
| air_path | 5 | `charge_air_cooler` | [0.67, 0.31] | [0.73, 0.42] | Ребристый теплообменный сердечник охладителя; G71 и G31 по похожим датчикам не идентифицируются. |
| fuel_storage | 3 | `fuel_level_sender` | [0.395, 0.33] | [0.398, 0.345] | Виден поплавок на рычаге датчика уровня справа от модуля насоса; прежнее замечание об отсутствии поплавка неточно. |
| radiator_pack | 1 | `radiator` | [0.47, 0.45] | [0.52, 0.27] | Открытая оребрённая часть радиатора над кожухом вентиляторов. |
| oil_pump_circuit | 2 | `oil_pump_drive` | [0.63, 0.3] | [0.58, 0.38] | Видимая левая ветвь роликовой цепи привода насоса. |
| exhaust_aftertreatment | 6 | `exhaust_clamp` | [0.54, 0.53] | [0.467, 0.542] | Стяжной хомут на соединении труб слева от муфты. |
| exhaust_rear | 3 | `exhaust_clamp` | [0.47, 0.47] | [0.52, 0.55] | Хомут соединения средней трубы. |
| exhaust_rear | 4 | `exhaust_mounts` | [0.65, 0.35] | [0.472, 0.31] | Резиновый подвес над средним глушителем, а не крепление теплового экрана. |
| clutch_group | 1 | `flywheel` | [0.16, 0.33] | [0.1, 0.31] | Открытая металлическая поверхность маховика слева; сцепление в целом не соответствует DQ200. |
| clutch_group | 5 | `clutch_engagement_levers` | [0.67, 0.5] | [0.654, 0.626] | Нижний рычаг включения справа; распознаётся категория рычага, не точное исполнение 0AM. |
| gear_selector | 2 | `gear_selector_cables` | [0.6, 0.27] | [0.81, 0.145] | Чёрная оболочка троса в верхней правой части, не кронштейн. |
| front_left_corner | 7 | `hub` | [0.69, 0.72] | [0.635, 0.676] | Видимый фланец ступицы со шпильками; подшипник внутри не виден. |
| front_subframe_arms | 5 | `ball_joint` | [0.81, 0.8] | [0.88, 0.88] | Шаровой шарнир с резиновым пыльником справа внизу. |
| front_strut | 1 | `strut_mount` | [0.48, 0.15] | [0.29, 0.12] | Верхняя опора в левой разнесённой сборке. |
| front_strut | 2 | `strut_bearing` | [0.5, 0.25] | [0.294, 0.214] | Отдельное опорное кольцо под верхней опорой; показана категория подшипника, точное исполнение не доказано. |
| front_strut | 3 | `spring` | [0.4, 0.6] | [0.29, 0.825] | Витки пружины в нижней части левой разнесённой сборки. |
| front_strut | 4 | `bump_stop` | [0.64, 0.39] | [0.295, 0.625] | Жёлтый вспененный отбойник слева; он виден, несмотря на прежнее замечание. |
| front_strut | 5 | `strut_dust_boot` | [0.64, 0.52] | [0.294, 0.465] | Чёрный гофрированный защитный чехол слева. |
| front_knuckle_hub | 1 | `cv_joint_outer` | [0.18, 0.42] | [0.84, 0.43] | Корпус наружного ШРУС справа у пыльника. |
| front_knuckle_hub | 2 | `steering_knuckle` | [0.52, 0.49] | [0.6, 0.65] | Литое тело поворотного кулака ниже отверстия. |
| front_knuckle_hub | 3 | `wheel_bearing` | [0.63, 0.47] | [0.425, 0.45] | Отдельно показанный подшипник слева от кулака; такая разнесённая сборка не подтверждает ступичный узел Yeti. |
| front_knuckle_hub | 4 | `hub` | [0.76, 0.47] | [0.266, 0.48] | Ступичный фланец со шпильками слева. |
| front_knuckle_hub | 5 | `dust_shield` | [0.8, 0.61] | [0.181, 0.243] | Чёрный защитный щиток сверху слева. |
| rear_carrier | 6 | `rear_suspension_bushings` | [0.5, 0.6] | [0.617, 0.667] | Отдельная резинометаллическая втулка ниже подрамника справа. |
| rear_springs_dampers | 5 | `rear_shock_upper_mount` | [0.67, 0.16] | [0.625, 0.075] | Верхний литой кронштейн амортизатора. |
| rear_springs_dampers | 6 | `rear_shock_bump_stop` | [0.67, 0.26] | [0.628, 0.18] | Жёлтый отбойник на штоке; изображение всей подвески ошибочно. |
| front_brake_assembly | 4 | `brake_guide_pins` | [0.5, 0.76] | [0.331, 0.808] | Нижний отдельный направляющий палец слева от скобы. |
| rear_brake_assembly | 3 | `brake_carrier` | [0.78, 0.62] | [0.714, 0.51] | Литая скоба слева от корпуса суппорта, не пыльник поршня. |
| wheel_sensors | 1 | `wheel_speed_sensor` | [0.59, 0.23] | [0.494, 0.227] | Чёрный корпус датчика над отверстием кулака. |
| wheel_sensors | 5 | `wheel_bearing_housing` | [0.31, 0.48] | [0.232, 0.3] | Литое тело кулака слева сверху. Документация Yeti называет его wheel-bearing housing; это соответствует существующему part_id wheel_bearing_housing, отдельный фиктивный корпус не нужен. Ступичный энкодер на всей схеме остаётся неверным. |
| heater_box | 4 | `hvac_housing` | [0.44, 0.53] | [0.18, 0.72] | Чёрная пластиковая стенка корпуса, не металлический теплообменник. |
| wiring | 5 | `bulkhead_wiring_grommet` | [0.85, 0.37] | [0.76, 0.375] | Широкий резиновый уплотнитель вокруг ветви жгута справа. |
| front_lamps | 5 | `headlamp_bulbs` | [0.29, 0.14] | [0.197, 0.143] | Отдельная лампа сверху слева; форма фары не подтверждает MY2011. |
| interior_lamps | 4 | `interior_light_bulbs` | [0.5, 0.29] | [0.083, 0.493] | Отдельная софитная лампа слева по центру, не закрытый рассеиватель. |
| console | 1 | `center_console` | [0.72, 0.7] | [0.615, 0.54] | Пластиковая боковая стенка консоли вокруг селектора, не чехол рычага. |

## Нерешённые привязки

| node_id | № | part_id | Исходный статус | Категория |
|---|---|---|---|---|
| air_path | 6 | `intake_manifold_pressure_sensor` | FAIL_MARKER | C |
| air_path | 7 | `charge_pressure_sensor` | FAIL_MARKER | C |
| fuel_delivery | 3 | `fuel_pressure_sensor_g247` | NEEDS_REVIEW | C |
| fuel_delivery | 4 | `fuel_pressure_control_valve_n276` | FAIL_MARKER | C |
| clutch_group | 2 | `dsg_dual_clutch` | NEEDS_REVIEW | C |
| clutch_group | 3 | `clutch_k1` | NEEDS_REVIEW | C |
| clutch_group | 4 | `clutch_k2` | NEEDS_REVIEW | C |
| gearbox_group | 2 | `dsg_input_shafts` | NEEDS_REVIEW | C |
| front_left_corner | 8 | `wheel_bearing` | NEEDS_REVIEW | C |
| front_axle_carrier | 3 | `suspension_bushings` | FAIL_MARKER | C |
| rear_suspension_overview | 2 | `rear_upper_control_arm` | NEEDS_REVIEW | C |
| rear_suspension_overview | 3 | `rear_lower_control_arm` | FAIL_MARKER | C |
| rear_suspension_overview | 4 | `rear_trailing_arm` | NEEDS_REVIEW | C |
| rear_suspension_overview | 5 | `rear_track_rod` | NEEDS_REVIEW | C |
| rear_carrier | 4 | `rear_trailing_arm` | NEEDS_REVIEW | C |
| rear_hub | 3 | `wheel_bearing` | NEEDS_REVIEW | C |
| rear_hub | 4 | `rear_abs_encoder_ring` | FAIL_MARKER | C |
| steering_column | 3 | `steering_angle_sensor` | NEEDS_REVIEW | C |
| front_brake_assembly | 6 | `brake_hose` | FAIL_MARKER | C |
| front_brake_assembly | 7 | `hub` | NEEDS_REVIEW | C |
| wheel_sensors | 4 | `abs_encoder_ring` | FAIL_MARKER | C |
| angle_drive | 1 | `gearbox` | FAIL_MARKER | D |
| angle_drive | 2 | `drive_shaft` | NEEDS_REVIEW | D |
| haldex | 1 | `haldex_coupling` | NEEDS_REVIEW | D |
| ac_circuit | 5 | `ac_pressure_sensor_g65` | FAIL_MARKER | C |
| ac_circuit | 6 | `evaporator` | NEEDS_REVIEW | C |
| control_units | 2 | `body_control_module` | NEEDS_REVIEW | C |
| control_units | 3 | `crankshaft_position_sensor` | NEEDS_REVIEW | C |
| control_units | 4 | `camshaft_position_sensor` | NEEDS_REVIEW | C |
| ignition | 4 | `camshaft_position_sensor` | NEEDS_REVIEW | C |
| ignition | 5 | `crankshaft_position_sensor` | FAIL_MARKER | C |
| front_lamps | 6 | `headlamp_level_actuator` | FAIL_MARKER | C |
| seats | 1 | `driver_seat` | NEEDS_REVIEW | C |
| seats | 2 | `passenger_seat` | NEEDS_REVIEW | C |

Номера и все детали остаются в списке и поиске. Неподтверждённые позиции не рисуются и не получают клики. При выборе строки карточка открывается по существующему part_id без ложного выделения на схеме.

## Новые изображения

[Единый запрос всех новых WebP](IMAGE_REPLACEMENT_REQUESTS.md). Полные машинные данные, source SHA256 и исходные/новые координаты: [remediation.json](remediation.json). Исходный active audit сохранён в baseline_active_audit.json; исторический full_marker_visual_review.json не изменён.

## Валидация

Статические проверки scope/JSON/SHA256/неизменности активов прошли. Godot runtime и UX должны быть проверены в Ubuntu x86_64 CI; локальный ARM64 импорт ранее аварийно завершался. Физическое устройство: NOT TESTED. Реальная Android-клавиатура и system bars: NOT TESTED.

Даже при успешных программных проверках техническая готовность каталога остаётся INCOMPLETE. APK экспорт блокируется отдельной проверкой --require-ready. Ни промежуточная APK, ни release не разрешены до замены изображений и подтверждения всех привязок.
