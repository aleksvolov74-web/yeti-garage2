# Yeti Garage / технические источники — частичная коррекция 2 из 5

Автомобиль: Škoda Yeti 5L MY2011 / CBZB / FWD / DQ200.

## engine_bottom_end
- Сервисная архитектура: четыре цилиндра, четыре поршня, четыре шатуна и один коленвал.
- Архитектура CBZB: https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/enginecrankshaft_group_pistons/crankshaft/
- Engine characteristics (4 цилиндра, 2 клапана/ц.): https://workshop-manuals.com/skoda/octavia-mk2/power_unit/12/63;_77_kw_tsi_engine/technical_data/technical_data/engine_characteristics/
- Изображение: новая оригинальная AI-визуализация, не копия заводского чертежа.
- Статус: REFERENCE_ONLY — размеры, крепления, номера OEM и ревизия не подтверждены.

## boost_group
- Турбокомпрессор с выпускным коллектором и регулятором V465; источник: https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/exhaust_system/removing_and_installing_parts_of_the_exhaust_system/catalytic_converter_and_component_parts_summary_of_components/
- Контекст V465: https://workshop-manuals.com/skoda/yeti/power_unit/12/63;_77_kw_tsi_engine/mixture_preparation_system_electronic_inj.gas/fitting_location_of_the_injection_system/fitting_location_of_the_injection_system/
- Изображение: новая оригинальная AI-визуализация, не копия заводского чертежа.
- Статус: REFERENCE_ONLY — точная форма привода, трассы масла/ОЖ и подключения требуют OEM-документации; не руководство по монтажу.

**Важно:** источники подтверждают устройство агрегатов, но не подтверждают пиксельную точность синтетических визуалов. Дополнительная проверка по VIN/PR обязательна при подборе деталей и ремонте.

**Три неготовых узла**: `engine_block_group`, `engine_upper_end`, `cylinder_head_group`. Их AI-визуалы не прошли архитектурную проверку, не включены в этот пакет.
