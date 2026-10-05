# Body + Glass/Wipers batch — architecture sources

Vehicle scope: Škoda Yeti 5L, MY2011, CBZB 1.2 TSI 77 kW, FWD, 0AM/DQ200. The linked service documents describe Yeti platform architecture; they do not establish the target VIN's exact PR-code configuration.

Verification meanings: `VERIFIED_ARCHITECTURE` confirms the documented type/layout only; it is not VIN-exact. `REFERENCE_ONLY` is retained wherever option, PR-code, production revision, market, or exact fitment is unresolved.

## body_front

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `front_bumper`, `hood`, `front_fender`
- Primary source: [Кузов Yeti 5L: передняя часть, бампер и крыло](https://workshop-manuals.com/skoda/yeti/body/body_work/body_front/front_body/)
- Related sources:
  - [Переднее крыло — состав и снятие](https://workshop-manuals.com/skoda/yeti/body/body_work/body_front/front_wing/)
  - [Передний бампер](https://workshop-manuals.com/skoda/yeti/body/body_work/bumper/front_bumper/)
  - [Капот и его компоненты](https://workshop-manuals.com/skoda/yeti/body/body_work/bonnet_flaps_cab_central_locking/engine_bonnet/)
- What the sources confirm: Документация Yeti описывает переднюю несущую часть, отдельное переднее крыло, передний бампер и капот как отдельные кузовные детали; руководство описывает взаимное освобождение угла бампера при снятии крыла.
- Accuracy limits: Изображение показывает только наружные панели и минимальный кузовной фрагмент. Не заявляет VIN-точную форму, крепёж, датчики парковки, омыватели фар, окраску или комплектацию.
- VIN / PR / market / production revision caveats: Бамперные накладки/вырезы, ПТФ, парктроники, омыватели фар, PR-коды, рынок и ревизия зависят от исполнения; год/месяц производства и VIN не проверены.

## doors

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `front_left_door`, `front_right_door`, `rear_left_door`, `rear_right_door`
- Primary source: [Двери Škoda Yeti 5L](https://workshop-manuals.com/skoda/yeti/body/body_work/front_door_central_locking/front_door/)
- Related sources:
  - [Задняя дверь — Yeti](https://workshop-manuals.com/skoda/yeti/body/body_work/rear_doorsliding_doorwing_doorscentral_locking/rear_door/)
  - [Задние двери: стекло и механизм](https://workshop-manuals.com/skoda/yeti/body/body_work/rear_doorsliding_doorwing_doorscentral_locking/rear_door/)
- What the sources confirm: Руководство Yeti подтверждает отдельные передние и задние двери, петли, ограничители, разъёмы и процедуру снятия. Визуал показывает четыре двери у соответствующих проёмов; сторона обозначена по виду сверху: перед автомобиля сверху, левый/правый борт слева/справа кадра.
- Accuracy limits: Не заявляет точные внутренние замки, стеклоподъёмники, проводку, боковые подушки или VIN-точную геометрию. Зеркала на передних дверях — лишь контекст комплекта двери, не отдельные markers этого node.
- VIN / PR / market / production revision caveats: Форма молдингов, зеркал, остекления, замков и электрического оснащения зависит от PR-кода, рынка, руля, производства и ревизии.

## body_rear

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `tailgate`, `roof_rails`
- Primary source: [Кузов Yeti 5L: дверь багажника и roof rack](https://workshop-manuals.com/skoda/yeti/body/body_work/bonnet_flaps_cab_central_locking/tailgate/summary_of_components_of_tailgate/)
- Related sources:
  - [Roof rack — Yeti, состав и снятие](https://workshop-manuals.com/skoda/yeti/body/body_work/exterior_equipment/roof_rack/)
  - [Roof strips / водоотводная накладка крыши (отличается от рейлинга)](https://workshop-manuals.com/skoda/yeti/body/body_work/exterior_equipment/roof_strips/)
- What the sources confirm: Сервисное руководство отдельно описывает дверь багажника и roof rack с парой продольных направляющих/креплением; отдельно описаны roof strips, поэтому их не смешиваем с рейлингами.
- Accuracy limits: Изображение даёт общую кузовную архитектуру и не претендует на точные крепления/вариант рейлингов или заднего стекла.
- VIN / PR / market / production revision caveats: Тип roof rack, его наличие/отделка и крепёж зависят от комплектации, рынка, PR-кодов и ревизии; номерной VIN не подтверждает конфигурацию.

## body_protection

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `front_wheel_arch_liner`, `rear_wheel_arch_liner`, `underbody_guard`
- Primary source: [Защита кузова и подкрылки Yeti 5L](https://workshop-manuals.com/skoda/yeti/body/body_work/exterior_equipment/wheelhouse_liner/removing_and_installing_the_front_wheelhouse_liner/)
- Related sources:
  - [Задний подкрылок — Yeti](https://workshop-manuals.com/skoda/yeti/body/body_work/exterior_equipment/wheelhouse_liner/removing_and_installing_the_rear_wheelhouse_liner/)
  - [Передняя кузовная часть, снятие noise insulation](https://workshop-manuals.com/skoda/yeti/body/body_work/body_front/front_body/)
  - [Noise insulation в операции по переднему крылу](https://workshop-manuals.com/skoda/yeti/body/body_work/body_front/front_wing/)
- What the sources confirm: Yeti workshop information перечисляет передний и задний wheelhouse liner как отдельные детали и описывает съём шумоизоляции/нижней защиты передней части.
- Accuracy limits: Точная конфигурация нижней защиты не подтверждена по данному VIN; рендер показывает только общий защитный щит без двигателя, трансмиссии и подвески.
- VIN / PR / market / production revision caveats: Подкрылки, шумоизоляция и нижние панели могут различаться по двигателю, коробке, приводу, рынку, PR-кодам, месяцу выпуска и ревизии; статус оставлен REFERENCE_ONLY.

## mirrors

- Verification: `VERIFIED_ARCHITECTURE`
- Existing part IDs: `side_mirrors`
- Primary source: [Наружные зеркала Yeti 5L](https://workshop-manuals.com/skoda/yeti/body/body_work/exterior_equipment/rear-view_mirror/)
- Related sources:
  - [Поворотный сигнал в наружном зеркале — Yeti](https://workshop-manuals.com/skoda/yeti/vehicle_electrics/electrical_system/lights_lamps_switches_outside/side_turn_signal_in_the_exterior_mirror/)
- What the sources confirm: Прямая документация Yeti содержит наружное зеркало как обслуживаемую сборку и отдельно описывает сигнал в зеркале; базовая архитектура пары наружных зеркал подтверждена.
- Accuracy limits: VERIFIED_ARCHITECTURE подтверждает тип и общую сборку, но не VIN-точную геометрию и не конкретный привод/опции.
- VIN / PR / market / production revision caveats: Крышка, повторитель, подогрев, электропривод, складывание и память зависят от PR-кода, рынка и комплектации; конкретное оснащение не утверждается.

## glazing

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `windshield`, `rear_window`
- Primary source: [Остекление кузова Yeti 5L](https://workshop-manuals.com/skoda/yeti/body/body_work/glazing/window_mechanism/glued_windows/)
- Related sources:
  - [Компоненты двери багажника Yeti (контекст заднего стекла)](https://workshop-manuals.com/skoda/yeti/body/body_work/bonnet_flaps_cab_central_locking/tailgate/summary_of_components_of_tailgate/)
  - [Оглавление раздела Glued windows Yeti](https://workshop-manuals.com/skoda/yeti/fullindex/)
- What the sources confirm: Документация Yeti подтверждает вклеенное ветровое стекло, клей/уплотнение и процедуру glazing; документация двери багажника подтверждает отдельную заднюю дверь со стеклом.
- Accuracy limits: Визуал показывает только формы двух стёкол. Не изображает/не утверждает антенну, подогрев, sight window, датчики, оттенок или VIN-маркировку.
- VIN / PR / market / production revision caveats: Стёкла, окна для датчика дождя/света, обогрев, антенны, оттенок и маркировка зависят от PR-кода, рынка, даты выпуска и замены по VIN.

## front_wipers

- Verification: `VERIFIED_ARCHITECTURE`
- Existing part IDs: `wiper_motor_front`, `wiper_linkage`, `wiper_blades_front`
- Primary source: [Передний стеклоочиститель Yeti 5L](https://workshop-manuals.com/skoda/yeti/vehicle_electrics/electrical_system/windscreen_wipe/wash_system/windscreen_wiper_and_washer_system/)
- Related sources:
  - [Yeti 2010/2011 Electrical System workshop manual, chapters 2.2–2.4](https://dms.kfz-verlag.de/pub/more_downloads/en-ebook-skoda-yeti-5l-0040.pdf)
- What the sources confirm: Yeti service information описывает передние щётки/рычаги, motor with linkage, frame, кривошип и электромотор; архитектура единого привода подтверждена.
- Accuracy limits: Рендер показывает общую архитектуру, не точный размер щёток, парковочное положение, сторону руля или индекс мотора.
- VIN / PR / market / production revision caveats: Щётки, motor revisions, RHD/LHD arrangement и настройки зависят от даты/ревизии, рынка и PR; точный VIN fitment не заявлен.

## rear_wiper

- Verification: `VERIFIED_ARCHITECTURE`
- Existing part IDs: `wiper_motor_rear`
- Primary source: [Задний стеклоочиститель Yeti 5L](https://dms.kfz-verlag.de/pub/more_downloads/en-ebook-skoda-yeti-5l-0040.pdf)
- Related sources:
  - [Yeti 2010/2011 Electrical System, chapter 3.2 rear window wiper motor](https://dms.kfz-verlag.de/pub/more_downloads/en-ebook-skoda-yeti-5l-0040.pdf)
  - [Форсунка омывателя заднего стекла Yeti (контекст вала)](https://workshop-manuals.com/skoda/yeti/vehicle_electrics/electrical_system/windscreen_wipe/wash_system/windscreen_washer_system/removing_and_installing_the_spray_nozzle_for_rear_window_washer_system/)
- What the sources confirm: Yeti 2010/2011 Electrical System manual отдельно содержит раздел rear window wiper system и операцию снятия/установки rear window wiper motor; компоновка через заднее стекло подтверждается также обслуживанием оси/форсунки.
- Accuracy limits: Изображение показывает общий прямой привод мотора; точная ревизия, электроразъём и washer integration не проверялись по VIN.
- VIN / PR / market / production revision caveats: Опции заднего стеклоочистителя и ревизии мотора могут зависеть от рынка, кузова/комплектации и даты производства.

## washers

- Verification: `REFERENCE_ONLY`
- Existing part IDs: `washer_pump`, `washer_reservoir`, `rain_sensor`
- Primary source: [Омыватель Yeti и optional rain/light sensor](https://workshop-manuals.com/skoda/yeti/vehicle_electrics/electrical_system/windscreen_wipe/wash_system/windscreen_washer_system/remove_and_install_reservoir_pumps_and_sensor_for_washer_fluid_level/)
- Related sources:
  - [Yeti 2011 wiring diagram: rain and light sensor G397 — special equipment](https://portal-diagnostov.com/en/2021/01/24/6685833-skoda-yeti-2011-body-electrical-l0r-wiring-diagrams-pin-connector-loca/)
  - [Yeti 2011 wiring diagram: V59 windscreen/rear window washer pump](https://portal-diagnostov.com/en/2021/01/24/6685833-skoda-yeti-2011-body-electrical-l0r-wiring-diagrams-pin-connector-loca/)
- What the sources confirm: Заводская процедура Yeti подтверждает бачок, насосы и датчик уровня; отдельно предупреждает, что расположение зависит от версии и дополнительно отопителя. Электросхема Yeti 2011 перечисляет G397 rain/light sensor как special equipment и V59 как насос омывателя ветрового/заднего стекла.
- Accuracy limits: Датчик дождя на рендере показан отдельной опциональной reference-деталью, не как установленный на целевой машине. Рендер не задаёт точную форму/позицию бачка и насоса.
- VIN / PR / market / production revision caveats: Rain/light sensor зависит от special equipment/PR-кода и стекла. Расположение насосов/шлангов зависит от версии и дополнительного отопителя; рынок, production month, VIN и конкретная комплектация не подтверждены.

## Visual appearance reference

[2011 Škoda Yeti S TSi 1.2 Front](https://commons.wikimedia.org/wiki/File:2011_Skoda_Yeti_S_TSi_1.2_Front.jpg) — Vauxford, CC BY-SA 4.0. Used only as a visual silhouette reference for generating original renderings; it is not evidence of component fitment and is not included in this batch.

All nine WebP files are original generated visuals. Workshop manuals were consulted for architecture only; their protected diagrams are not copied or included. The CBZB/FWD/0AM-DQ200 profile is retained as project scope, but these body/glazing/wiper assemblies are documented at the Yeti platform level and are not asserted to be exact to the stored VIN.
