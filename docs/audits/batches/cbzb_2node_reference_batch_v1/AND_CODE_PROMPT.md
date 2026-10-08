# PROMPT ДЛЯ AND CODE — YETI GARAGE / ТОЛЬКО ЧАСТИЧНАЯ КОРРЕКЦИЯ 2 УЗЛОВ

Действуй внутри существующего проекта `/root/yeti-garage`. GitHub: `aleksvolov74-web/yeti-garage2`. НЕ начинай проект заново. Перед правками восстанови состояние текущей ветки и сверь с main.

## ПАКЕТ
- ZIP: `YetiGarage_CBZB_2node_reference_batch_v1.zip`
- Путь на Android после скачивания: `/storage/emulated/0/Download/YetiGarage_CBZB_2node_reference_batch_v1.zip` (`/sdcard/Download/YetiGarage_CBZB_2node_reference_batch_v1.zip`)
- Распаковывай в отдельную временную папку, проверь SHA256SUMS и manifest.json.
- Интегрируй ТОЛЬКО на ветке `validation/full-marker-audit-android-ux`, НЕ на main.
- Опорный main HEAD при подготовке: `e3008862fa901886e56587056200347a90258fdc`; validation commit `172652a`. Если HEAD изменились, сначала выведи diff и убедись, что не перезаписываешь более новые исправления.
- Автомобиль: Škoda Yeti 5L MY2011, 1.2 TSI CBZB, FWD, DSG7 0AM-DQ200.
- Версия перед интеграцией: `0.20.29`, versionCode `69`. На этой ЧАСТИЧНОЙ интеграции НЕ поднимай версию, НЕ выпускай финальный APK, НЕ сливай в main.
- Текущие счётчики: sections=24; nodes=90; nodes_with_images=90; nodes_without_images=0; markers_total=376; VERIFIED_ARCHITECTURE=57; REFERENCE_ONLY=33.

## ЧТО ИМЕННО МЕНЯТЬ
**node_id `engine_bottom_end`**, визуал `assets/technical_catalog/engine/engine_bottom_end.webp`.
- Статус `REFERENCE_ONLY`; 4 маркера: 1 engine_block (0.48,0.55); 2 crankshaft (0.51,0.84); 3 piston_group (0.44,0.09); 4 connecting_rods (0.44,0.25).
- Названия: Блок двигателя, Коленчатый вал, Поршневая группа, Шатуны.

**node_id `boost_group`**, визуал `assets/technical_catalog/intake/boost_group.webp`.
- Статус `REFERENCE_ONLY`; 6 маркеров: 1 turbocharger (0.62,0.43); 2 exhaust_manifold (0.31,0.28); 3 charge_pressure_regulator_v465 (0.80,0.23); 4 turbo_oil_feed_line (0.49,0.135); 5 turbo_coolant_lines (0.245,0.63); 6 charge_air_pipe (0.82,0.74).
- Названия: Турбокомпрессор, Выпускной коллектор, Электрический регулятор наддува V465, Трубка подачи масла турбины, Трубки охлаждения турбины, Патрубок наддувочного воздуха.

СУЩЕСТВУЮЩИЕ part_id сохранить. НОВЫХ part_id НЕТ; new_part_ids=[]; никаких заглушек. Новых изображений в смысле пустых узлов 0, замен изображений 2, переназначений координат 10, новых маркеров 0. У каждого node_id собственный файл WebP. Не допускается перенос чужих WebP в узлы.

Обязательные ожидаемые TOTAL после интеграции: `nodes_with_images=90`, `nodes_without_images=0`, `markers=376`, `VERIFIED_ARCHITECTURE=55`, `REFERENCE_ONLY=35` (если стартовые 57/33 действительно не изменились). Изменены только `engine_bottom_end` и `boost_group`. `images_added=0`, `images_replaced=2`, `markers_added=0`, `markers_repositioned=10`.

**Важная ловушка:** файл `tools/validate_visual_audit.py` на ветке validation проверяет побайтовую неизменность всех исходных WebP и ровно 33 прежних исправления координат. Он, естественно, начнёт падать после корректной замены ДВУХ WebP. Обнови тест осторожно: сохрани подтверждение прежних 33 правок, выдели ровно 2 явно разрешённых замены по SHA в manifest и дополни аудит только этих двух узлов. НЕ объявляй остальные ошибки исправленными. Не изменяй неизменяемый исходный historical review так, будто раньше данные были правильными: сделай внятную историю изменений. Отдельно проверь, что сведения аудита не ссылаются на старые пиксели.

ОСТАЛИСЬ НЕГОТОВЫМИ три узла: `engine_block_group`, `engine_upper_end`, `cylinder_head_group`; у них была FAIL_ARCHITECTURE, эта работа их НЕ исправляет. Количество FAIL_ARCHITECTURE должно уменьшиться с 5 до 3, если больше ошибок не найдено; никогда не ставь этим трём PASS без новых подтверждённых изображений. Статус `REFERENCE_ONLY` означает ориентир для пользователя, а не доказанную VIN-точность.

## ЗАПРЕТЫ
Не проводить глобальный аудит снова; не генерировать и не искать изображений; не модифицировать WebP; не менять модель данных за пределами manifest; не создавать dummy part_id; не менять DQ200/CBZB или AWD/FWD-секции, кроме указанного. Не делать промежуточный APK до полной интеграции, не тянуть неподтверждённые картинки в этот batch. Не выпускай этот частичный результат как финальное исправление пяти архитектурных ошибок.

## UI / РЕГРЕССИЯ
Оба экрана проверить: загрузка изображения; zoom; pan; reset zoom; показать/скрыть номера; tap marker; выбор строки списка; marker/list synchronization в обе стороны; карточка детали; back-navigation; поиск каждой существующей детали. Нет `Изображение готовится`.
Проверить прокрутку списков и ошибок, открытие выпадающего списка «Схемы» (OptionButton, не отдельный экран), формат номеров без `.0`, горизонтальные переполнения, реальные жесты для 360/420 px, безопасные области и сохранение масштабирования. Никаких ошибок в уже интегрированных CBZB, DQ200, подвеске, рулевом, тормозах/ABS, впуске, топливе, охлаждении, выпуске, климате, электрике, освещении.

## VALIDATION
`git diff --check` → Godot import → catalog validation → startup smoke-check → visual catalog smoke-check → validate fault catalog / Android UX → Android export проверять только ПОСЛЕ полной интеграции. Поскольку это частичный 2-узловой batch из пяти, без отдельного разрешения НЕ коммить в main, НЕ повышай version/versionCode, НЕ публикуй релиз. Если нужны GitHub Actions для validation APK, используй validation-ветку и явно подпиши сборку как неполную.

## ФИНАЛЬНЫЙ ОТЧЁТ
Верни: images_added; images_replaced; markers_added; markers_repositioned; nodes_with_images TOTAL; nodes_without_images TOTAL; markers TOTAL; new_part_ids=[]; modified_node_ids; VERIFIED_ARCHITECTURE total; REFERENCE_ONLY total; FAIL_ARCHITECTURE remaining; version; versionCode; final commit (если есть); GitHub Actions run (если есть); APK artifact (если есть). Если не запускалось — укажи NOT_RUN, не выдумывай успех. Укажи точные результаты всех проверок и незакрытые три node_id. Если counts не совпали — задача НЕ DONE.
