# Запрос единого пакета новых WebP

Только существующие замечания. Изображения не изменялись. Сохранить part_id и номера. Все новые визуалы — REFERENCE_ONLY; точная применимость к VIN/PR не подтверждена.

22 узла комплектации FWD и 2 отдельных справочных узла AWD. Для AWD фильтрация FWD должна оставаться включённой.

## air_path — Воздушный тракт

**Текущий файл:** `res://assets/technical_catalog/intake/air_path.webp`

**Ошибка и необходимые детали:** Два разных датчика G71/G42 и G31/G299 нельзя различить по неидентифицированным корпусам. Нужны явно различимые места установки CBZB.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `air_filter` | Воздушный фильтр |
| 2 | `air_filter_housing` | Корпус воздушного фильтра |
| 3 | `throttle_body` | Дроссельная заслонка |
| 4 | `intake_manifold` | Впускной коллектор |
| 5 | `charge_air_cooler` | Жидкостный охладитель наддувочного воздуха во впускном коллекторе CBZB |
| 6 | `intake_manifold_pressure_sensor` | Датчик давления во впускном коллекторе |
| 7 | `charge_pressure_sensor` | Датчик давления наддува |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/mixture_preparation_system_electronic_inj.gas/air_filter/

## fuel_delivery — Магистрали, рампа и форсунки

**Текущий файл:** `res://assets/technical_catalog/fuel/fuel_delivery.webp`

**Ошибка и необходимые детали:** N276 относится к ТНВД CBZB, не к торцу рампы. На текущем синтетическом изображении назначение электрического узла насоса и отдельного датчика G247 не доказано. Показать ТНВД с N276 и рампу с G247 раздельно.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `high_pressure_fuel_pump` | Насос высокого давления топлива |
| 2 | `fuel_rail` | Топливная рампа |
| 3 | `fuel_pressure_sensor_g247` | Датчик давления топлива G247 |
| 4 | `fuel_pressure_control_valve_n276` | Клапан регулирования давления топлива N276 |
| 5 | `injectors` | Форсунки |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/mixture_preparation_system_electronic_inj.gas/intake_manifold_and_fuel_distributor/intake_manifold_summary_of_components/part_ii/
- https://workshop-manuals.com/skoda/yeti/power_unit/12/63%3B_77_kw_tsi_engine/mixture_preparation_system_electronic_inj.gas/fitting_location_of_the_injection_system/fitting_location_of_the_injection_system/

## exhaust_aftertreatment — Катализатор и кислородные датчики

**Текущий файл:** `res://assets/technical_catalog/exhaust/exhaust_aftertreatment.webp`

**Ошибка и необходимые детали:** Четырёхпортовый коллектор прямо связан с катализатором без необходимого турбокомпрессора CBZB. Нужна правильная последовательность выпускного тракта.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `catalytic_converter` | Катализатор |
| 2 | `oxygen_sensor` | Лямбда-зонд |
| 3 | `catalyst_heat_shield` | Тепловой экран каталитического нейтрализатора |
| 4 | `exhaust_flex_joint` | Гибкая секция передней трубы выпуска |
| 5 | `front_exhaust_pipe` | Передняя часть выпуска |
| 6 | `exhaust_clamp` | Хомут соединения системы выпуска |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/exhaust_system/removing_and_installing_parts_of_the_exhaust_system/catalytic_converter_and_component_parts_summary_of_components/

## clutch_group — Сцепление и маховик

**Текущий файл:** `res://assets/technical_catalog/dsg/clutch_group.webp`

**Ошибка и необходимые детали:** Два последовательных обычных диска не дают подтверждённой конструкции сухого двойного сцепления 0AM. K1/K2 не идентифицированы. Показать правильную коаксиальную сборку и механизмы включения.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `flywheel` | Маховик |
| 2 | `dsg_dual_clutch` | Двойное сцепление DSG 0AM |
| 3 | `clutch_k1` | Сцепление K1 DSG 0AM |
| 4 | `clutch_k2` | Сцепление K2 DSG 0AM |
| 5 | `clutch_engagement_levers` | Рычаги включения двойного сцепления DSG |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_0am-dsg/clutch_control/removing_and_installing_the_double_clutch/double_clutch_summary_of_components_(as_of_06.11)/
- https://vehiclelifetimesolutions.schaeffler.com/medias/BR-0012-en.PDF?context=bWFzdGVyfGRvY3VtZW50c3w1MTA3MjMzfGFwcGxpY2F0aW9uL3BkZnxkb2N1bWVudHMvaGZjL2g2NS85MzA1ODYxOTE0NjU0LnBkZnwwOTc0ZTg2ZmE3ZjdiNDkwMTMwMWViYWJjNjhhNzY3NGQ5MDBmYTA2YzBmYTE4NGJiYWJlYjg5ZDMwOWRmOTcz

## gearbox_group — Коробка передач и дифференциал

**Текущий файл:** `res://assets/technical_catalog/dsg/gearbox_group.webp`

**Ошибка и необходимые детали:** Два концентрических первичных вала 0AM не различимы. Нужен разрез или разнесённая схема с обоими валами.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `gearbox_housing` | Корпус коробки DSG 0AM |
| 2 | `dsg_input_shafts` | Первичные валы DSG 0AM |
| 3 | `dsg_output_shafts` | Выходные валы DSG 0AM |
| 4 | `differential` | Дифференциал |
| 5 | `dsg_mechatronics` | Мехатроник DSG 0AM / DQ200 |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_0am-dsg/technical_data/technical_data_for_the_gearbox/transmission_system_overview/

## front_left_corner — Левая передняя сторона

**Текущий файл:** `res://assets/technical_catalog/front_suspension/front_left_corner.webp`

**Ошибка и необходимые детали:** Подшипник скрыт. Нижнее двухболтовое крепление стойки не соответствует зажимному соединению стойки с кулаком Yeti. Нужна правильная сборка и видимый ступичный подшипник.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `control_arm` | Нижний рычаг |
| 2 | `ball_joint` | Шаровая опора |
| 3 | `strut` | Амортизационная стойка |
| 4 | `spring` | Пружина |
| 5 | `strut_mount` | Верхняя опора стойки |
| 6 | `stabilizer_link` | Стойка стабилизатора |
| 7 | `hub` | Ступица |
| 8 | `wheel_bearing` | Ступичный подшипник |
| 9 | `wheel` | Колесо |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/repairing_front_axle/front_axle_overview/

## front_axle_carrier — Подрамник и стабилизатор

**Текущий файл:** `res://assets/technical_catalog/front_suspension/front_axle_carrier.webp`

**Ошибка и необходимые детали:** Подвесочный сайлентблок не отделён от втулки стабилизатора; перенос на похожее резиновое кольцо недоказуем.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `subframe` | Подрамник |
| 2 | `anti_roll_bar` | Стабилизатор поперечной устойчивости |
| 3 | `suspension_bushings` | Сайлентблоки подвески |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/front_axle_with_assembly_carrier_made_of_steel_sheet/

## front_strut — Амортизационная стойка и пружина

**Текущий файл:** `res://assets/technical_catalog/front_suspension/front_strut.webp`

**Ошибка и необходимые детали:** Нижняя двухболтовая вилка стойки не соответствует соединению Yeti с зажимом в кулаке. Видимые категории деталей можно обозначить, но сборку нужно заменить.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `strut_mount` | Верхняя опора стойки |
| 2 | `strut_bearing` | Опорный подшипник стойки |
| 3 | `spring` | Пружина |
| 4 | `bump_stop` | Отбойник амортизационной стойки |
| 5 | `strut_dust_boot` | Пыльник амортизационной стойки |
| 6 | `strut` | Амортизационная стойка |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/repairing_front_axle/front_axle_overview/

## front_knuckle_hub — Поворотный кулак и ступица

**Текущий файл:** `res://assets/technical_catalog/front_suspension/front_knuckle_hub.webp`

**Ошибка и необходимые детали:** Показан отдельный запрессовываемый подшипник вместо подтверждённого болтового ступично-подшипникового узла Yeti. Нужна правильная сборка с зажимом стойки.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `cv_joint_outer` | Наружный ШРУС |
| 2 | `steering_knuckle` | Поворотный кулак |
| 3 | `wheel_bearing` | Ступичный подшипник |
| 4 | `hub` | Ступица |
| 5 | `dust_shield` | Защитный щиток тормозного диска |
| 6 | `ball_joint` | Шаровая опора |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/summary_of_components_of_the_wheel_bearing/
- https://workshop-manuals.com/skoda/yeti/axles_steering/front_suspension_drive_shafts/summary_of_components_of_the_wheel_bearing/sticky-snack.php

## rear_suspension_overview — Задняя подвеска в сборе

**Текущий файл:** `res://assets/technical_catalog/rear_suspension/rear_suspension_overview.webp`

**Ошибка и необходимые детали:** Не заданы направление движения и стороны автомобиля; назначения верхнего, нижнего, продольного рычагов и тяги нельзя доказать. Нужна ориентированная схема многорычажной подвески FWD.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `rear_subframe` | Подрамник задней подвески |
| 2 | `rear_upper_control_arm` | Верхний поперечный рычаг задней подвески |
| 3 | `rear_lower_control_arm` | Нижний поперечный рычаг задней подвески |
| 4 | `rear_trailing_arm` | Продольный рычаг задней подвески |
| 5 | `rear_track_rod` | Поперечная тяга задней подвески |
| 6 | `spring` | Пружина |
| 7 | `rear_shock_absorber` | Задний амортизатор |
| 8 | `rear_anti_roll_bar` | Задний стабилизатор поперечной устойчивости |
| 9 | `rear_hub_carrier` | Держатель ступицы заднего колеса |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel-drive%29/overview_of_rear_axle/

## rear_carrier — Подрамник / балка и рычаги

**Текущий файл:** `res://assets/technical_catalog/rear_suspension/rear_carrier.webp`

**Ошибка и необходимые детали:** Продольный рычаг не идентифицируется однозначно; нужна ориентация и видимые отдельные рычаги многорычажной подвески FWD.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `rear_subframe` | Подрамник задней подвески |
| 2 | `rear_upper_control_arm` | Верхний поперечный рычаг задней подвески |
| 3 | `rear_lower_control_arm` | Нижний поперечный рычаг задней подвески |
| 4 | `rear_trailing_arm` | Продольный рычаг задней подвески |
| 5 | `rear_track_rod` | Поперечная тяга задней подвески |
| 6 | `rear_suspension_bushings` | Сайлентблоки задней подвески |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel-drive%29/overview_of_rear_axle/

## rear_springs_dampers — Пружины и амортизаторы

**Текущий файл:** `res://assets/technical_catalog/rear_suspension/rear_springs_dampers.webp`

**Ошибка и необходимые детали:** Изображена соединяющая колёса балка. Yeti FWD имеет независимую многорычажную подвеску. Показать отдельно пружину на нижнем рычаге и амортизатор с опорой/отбойником.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `rear_spring_upper_seat` | Верхняя прокладка задней пружины |
| 2 | `spring` | Пружина |
| 3 | `rear_spring_lower_seat` | Нижняя прокладка задней пружины |
| 4 | `rear_shock_absorber` | Задний амортизатор |
| 5 | `rear_shock_upper_mount` | Верхнее крепление заднего амортизатора |
| 6 | `rear_shock_bump_stop` | Отбойник заднего амортизатора |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel-drive%29/overview_of_rear_axle/
- https://cdn.skoda-storyboard.com/2016/12/TD_YETI_en.pdf
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/summary_of_components_wheel-bearing_housing_trailing_arm_%28vehicles_with_front-wheel_drive%29/

## rear_hub — Задние ступицы и подшипники

**Текущий файл:** `res://assets/technical_catalog/rear_suspension/rear_hub.webp`

**Ошибка и необходимые детали:** Подшипник скрыт внутри ступицы; зубчатое кольцо не подтверждает магнитный ABS-энкодер. Нужен разрез неприводного ступичного узла FWD с различимой стороной энкодера.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `rear_hub_carrier` | Держатель ступицы заднего колеса |
| 2 | `hub` | Ступица |
| 3 | `wheel_bearing` | Ступичный подшипник |
| 4 | `rear_abs_encoder_ring` | Магнитный энкодер заднего ступичного подшипника |
| 5 | `rear_wheel_speed_sensor` | Задний датчик скорости колеса ABS |
| 6 | `dust_shield` | Защитный щиток тормозного диска |
| 7 | `brake_disc` | Тормозной диск |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel-drive%29/overview_of_rear_axle/

## steering_column — Рулевое колесо и колонка

**Текущий файл:** `res://assets/technical_catalog/steering/steering_column.webp`

**Ошибка и необходимые детали:** Узел подрулевой электроники/контактного кольца не позволяет отдельно идентифицировать G85. Показать документально подтверждённое исполнение MY2011, не смешивать датчик с контактным кольцом.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `steering_wheel` | Рулевое колесо |
| 2 | `steering_column` | Рулевая колонка |
| 3 | `steering_angle_sensor` | Датчик угла поворота руля |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/axles_steering/steering/steering_column_lhd_vehicles_with_left-hand_drive/

## front_brake_assembly — Диск, суппорт и колодки

**Текущий файл:** `res://assets/technical_catalog/front_suspension/front_brake_assembly.webp`

**Ошибка и необходимые детали:** Тормозной шланг отсутствует, ступица скрыта диском/колпачком. Нужна схема с отдельно видимыми шлангом и ступицей и оговоркой PR тормозов.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `brake_caliper` | Тормозной суппорт |
| 2 | `brake_pads` | Тормозные колодки |
| 3 | `brake_carrier` | Скоба суппорта |
| 4 | `brake_guide_pins` | Направляющие суппорта |
| 5 | `brake_disc` | Тормозной диск |
| 6 | `brake_hose` | Тормозной шланг |
| 7 | `hub` | Ступица |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/brake_systems/brake_brake_mechanics/repairing_the_front_brake/

## wheel_sensors — Датчики скорости колёс

**Текущий файл:** `res://assets/technical_catalog/brakes/wheel_sensors.webp`

**Ошибка и необходимые детали:** Зубчатое кольцо не подтверждает правильный встроенный ABS-энкодер ступичного узла Yeti. Показать датчик и соответствующий встроенный энкодер; корпус кулака wheel-bearing housing уже идентифицирован по документации, новый part_id не нужен.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `wheel_speed_sensor` | Датчик скорости колеса ABS |
| 2 | `wheel_speed_sensor_connector` | Разъём датчика скорости колеса |
| 3 | `hub` | Ступица |
| 4 | `abs_encoder_ring` | Магнитный энкодер ступичного подшипника |
| 5 | `wheel_bearing_housing` | Корпус ступичного подшипника |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/brake_systems/abs_adr_tcs_edl_esp/electrical/electronic_components_and_fitting_locations_abs_mark_60_ec_%28abs/edl/tcs/esp%29/
- https://workshop-manuals.com/skoda/yeti/brake_systems/abs_adr_tcs_edl_esp/electrical/electronic_components_and_fitting_locations_abs_mark_60_ec_(abs/edl/tcs/esp)/

## angle_drive — Угловая передача

**Текущий файл:** `res://assets/technical_catalog/4x4_reference/angle_drive.webp`

**Ошибка и необходимые детали:** Узел AWD не применяется к FWD. gearbox и drive_shaft указывают на части угловой передачи вместо своих деталей. Для необязательного AWD материала показать коробку и соответствующий вал как отдельные детали, не менять существующие ID.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** AWD reference only; not applicable to FWD

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `gearbox` | Коробка передач |
| 2 | `drive_shaft` | Приводной вал |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_02e-dsg/gearbox_mechanicsoperation_constructiondiff./removing_and_installing_angle_gearbox/

## haldex — Муфта Haldex

**Текущий файл:** `res://assets/technical_catalog/4x4_reference/haldex.webp`

**Ошибка и необходимые детали:** Узел AWD не применяется к FWD. Изображение не позволяет уверенно выделить муфту Haldex; требуется отдельный корректный AWD визуал, вне комплектации FWD.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** AWD reference only; not applicable to FWD

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `haldex_coupling` | Муфта полного привода Haldex |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_transmission/gearbox_02q/final_drive_differential_differential_lock/disassembling_and_assembling_haldex_coupling/

## ac_circuit — Компрессор, конденсер и испаритель

**Текущий файл:** `res://assets/technical_catalog/climate/ac_circuit.webp`

**Ошибка и необходимые детали:** Вместо испарителя изображён второй наружный конденсор; G65 нельзя доказанно идентифицировать. Нужны конденсор, испаритель в HVAC и G65 на стороне высокого давления.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `ac_compressor` | Компрессор кондиционера |
| 2 | `condenser` | Конденсер кондиционера |
| 3 | `receiver_drier` | Осушитель кондиционера |
| 4 | `ac_expansion_valve` | Расширительный клапан кондиционера |
| 5 | `ac_pressure_sensor_g65` | Датчик давления кондиционера G65 |
| 6 | `evaporator` | Испаритель кондиционера |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/heating_ventilation_air_conditioning_system/heating_air_conditioning/air_conditioner/climatronic_air_conditioner_with_automatic_regulation%29/summary_of_components/
- https://workshop-manuals.com/skoda/yeti/heating_ventilation_air_conditioning_system/heating_air_conditioning/air_conditioner/repairing_the_air_conditioning_system_engine_compartment/

## control_units — Блоки управления и датчики двигателя

**Текущий файл:** `res://assets/technical_catalog/electrical/control_units.webp`

**Ошибка и необходимые детали:** Блок предохранителей не является BCM. Два похожих датчика не позволяют различить G28/G40. Показать BCM/J519 и датчики с подтверждёнными местами установки.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `engine_ecu` | ЭБУ двигателя |
| 2 | `body_control_module` | Блок бортовой сети (BCM) |
| 3 | `crankshaft_position_sensor` | Датчик положения коленвала |
| 4 | `camshaft_position_sensor` | Датчик положения распредвала |
| 5 | `control_unit_connectors` | Разъёмы блоков управления |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/fullindex/

## ignition — Система зажигания

**Текущий файл:** `res://assets/technical_catalog/ignition/ignition.webp`

**Ошибка и необходимые детали:** Неидентифицированные датчики не дают соответствия G28/G40. Показать их отдельно с правильными местами установки CBZB, сохранить один N152 и четыре свечи/провода.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `ignition_coil` | Модуль / трансформатор зажигания N152 |
| 2 | `ignition_cables` | Высоковольтные провода зажигания |
| 3 | `spark_plugs` | Свечи зажигания |
| 4 | `camshaft_position_sensor` | Датчик положения распредвала |
| 5 | `crankshaft_position_sensor` | Датчик положения коленвала |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/ignition_system_glow_plug_system/ignition_system/ignition_system_summary_of_components/

## front_lamps — Передние фары и противотуманные фонари

**Текущий файл:** `res://assets/technical_catalog/lighting/front_lamps.webp`

**Ошибка и необходимые детали:** Форма фары не подтверждает Yeti до рестайлинга MY2011; мотор корректора не виден. Нужны правильная фара, отдельная лампа и мотор с оговоркой PR/галоген-ксенон.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `headlamp_left` | Левая фара |
| 2 | `headlamp_right` | Правая фара |
| 3 | `fog_lamp_left` | Левая противотуманная фара |
| 4 | `fog_lamp_right` | Правая противотуманная фара |
| 5 | `headlamp_bulbs` | Лампы передних фар |
| 6 | `headlamp_level_actuator` | Электрокорректор фары |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/fullindex/

## seats — Передние и задние сиденья

**Текущий файл:** `res://assets/technical_catalog/interior/seats.webp`

**Ошибка и необходимые детали:** Ориентация отдельных передних сидений не позволяет различить водительское/пассажирское. Задний диван не соответствует трём отдельным сиденьям VarioFlex Yeti. Нужна ориентация автомобиля и три задних сиденья.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

**Применимость:** Yeti 5L MY2011 CBZB FWD DQ200; PR-dependent revisions must remain explicit

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `driver_seat` | Сиденье водителя |
| 2 | `passenger_seat` | Переднее пассажирское сиденье |
| 3 | `rear_seat` | Задний диван |

Все перечисленные детали должны быть реально видимы; без произвольных координат и деталей-заменителей.

**Источники архитектуры:**
- https://workshop-manuals.com/skoda/yeti/fullindex/
- https://cdn.skoda-storyboard.com/2020/07/10_%C5%A0KODA-YETI_First-member-of-%C5%A0KODAs-popular-SUV-family.pdf

## rear_brake_assembly — Задний тормозной механизм

**Текущий файл:** `res://assets/technical_catalog/rear_brakes/rear_brake_assembly.webp`

**Ошибка и необходимые детали:** Прежний active audit уже отмечает вентилируемый диск и отсутствие различимого привода ручника. Перемещение маркера скобы не подтверждает весь задний тормоз MY2011 FWD. Нужен правильный задний суппорт с видимым механическим приводом стояночного тормоза, диск/скоба по оговорённому PR-коду; без неподтверждённого назначения переднего тормоза задним.

**verification status:** NEEDS_IMAGE_REPLACEMENT__REFERENCE_ONLY_NOT_VIN_EXACT

| № | part_id | Видимая деталь |
|---|---|---|
| 1 | `brake_disc` | Тормозной диск |
| 2 | `brake_caliper` | Тормозной суппорт |
| 3 | `brake_carrier` | Скоба суппорта |
| 4 | `brake_guide_pins` | Направляющие суппорта |
| 5 | `brake_pads` | Тормозные колодки |
| 6 | `brake_hose` | Тормозной шланг |
| 7 | `abs_wheel_sensor_rl` | Датчик ABS заднего левого колеса |

Дополнительно показать механический привод стояночного тормоза как часть суппорта; новый part_id не создавать.

**Источники и ограничения:** Yeti 5L MY2011 FWD; rear brake PR revision unconfirmed. The additional workshop cable illustration is AWD context only and does not prove the FWD brake revision.

- https://workshop-manuals.com/skoda/yeti/brake_systems/brake_brake_mechanics/repairing_rear_brake/
- https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/summary_of_components_assembly_carrier_final_drive_%28vehicles_with_four-wheel_drive%29/
