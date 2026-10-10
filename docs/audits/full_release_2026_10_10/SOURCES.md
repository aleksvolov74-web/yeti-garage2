# Источники и пределы применимости

Автомобиль: Škoda Yeti 5L MY2011 CBZB FWD DSG7 DQ200/0AM. PR-коды, точный код коробки и ревизии не установлены. Генератор изображений доступен, Magnific не использовался. Новые технические изображения не генерировались: отсутствие достоверного внутреннего G85 нельзя компенсировать выдуманной геометрией.

Прочитаны внешние `/sdcard/Download/YETI_GARAGE_MASTER_RULES.md` и `/sdcard/Download/YETI_GARAGE_CURRENT_STATE.json`. Второй файл — исторический checkpoint 0.20.26/66 от 2026-10-02; фактическая ветка 0.20.29/69. Правила найдены вне Git; в истории всех локальных refs этих имён не найдено. Содержание сохранено в snapshots, исходные файлы не перезаписаны.

Существующие источники всех узлов: `assets/technical_catalog/SOURCES.md`, aggregate manifest, `data/technical_catalog.json`, `docs/technical_catalog_sources.md`, batch SOURCES и `docs/audits/known_marker_remediation_v1/IMAGE_REPLACEMENT_REQUESTS.md`. Реестр архивов: archive_inventory.json. Наличие файла и старого ACCEPTED не приравнивается к новой приёмке.

Проверены в этом запуске:

- Volkswagen Service Training SSP 390, [0AM Design and Function](https://content.datarunners.net/content/SSP/SSP390C.pdf), печатные стр. 14–21. Просмотрены схема сухого двойного сцепления на стр.15 и рисунки концентрических первичных валов на стр.21. Это подтверждает общую архитектуру 0AM, а не конкретную ревизию Yeti. PDF и фрагменты загружены в /tmp для проверки; не включены в приложение или архив.
- Копия сервисного содержания Škoda, [Yeti FWD overview](https://workshop-manuals.com/skoda/yeti/axles_steering/rear_suspension_drive_shaft/repairing_rear_wheel_suspension_%28vehicles_with_front-wheel_drive%29/overview_of_rear_axle/). Раздел различает версии до CW21/2010 и с CW22/2010. Просмотрен оригинальный рисунок S42-0347 (yeti-172.png). Общий обзор не доказывает геометрию каждого отдельного сгенерированного рычага.
- Копия сервисного содержания Škoda, [Yeti Gen3 steering](https://workshop-manuals.com/skoda/yeti/axles_steering/steering/electro-mechanical_steering_gear_lhd_vehicles_with_left-hand_drive/summary_of_components_for_electro-mechanical_steering_gear_lhd_aluminium_assembly_carrier/): G85 интегрирован в рулевой механизм. Идентифицированный внутренний вид G85, применимый к данному Yeti, не установлен.
- Копия сервисного содержания Škoda, [ABS Mark60EC fitting locations](https://workshop-manuals.com/skoda/yeti/brake_systems/abs_adr_tcs_edl_esp/electrical/electronic_components_and_fitting_locations_abs_mark_60_ec_%28abs/edl/tcs/esp%29/): кольцо ABS интегрировано в ступицу; отдельные позиции для FWD/AWD. Это не подтверждает произвольный зубчатый венец сгенерированной ступицы.

Авторские сервисные рисунки не распространяются в приложении. Ни одна новая схема не объявлена VERIFIED_EXACT. angle_drive, haldex и остальные AWD материалы остаются отдельными REFERENCE_ONLY и скрыты в профиле FWD.
