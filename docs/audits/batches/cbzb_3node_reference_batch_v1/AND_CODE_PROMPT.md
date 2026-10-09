# AND CODE — YETI GARAGE / ЗАВЕРШЕНИЕ ПЯТИ УЗЛОВ CBZB

Продолжай текущий проект, НЕ начинай заново. Нового глобального аудита не требуется. Это **ТРЕТИЙ ЭТАП** после частичного интегрированного batch из 2 узлов (`engine_bottom_end`, `boost_group`), и он исправляет ОСТАВШИЕСЯ 3 архитектурно ошибочных узла.

## 1. Источник и границы

Репозиторий: `aleksvolov74-web/yeti-garage2`.
Источник: **validation/full-marker-audit-android-ux** @ `ff73f211e73db4d3f8f72838eebc97eb0a57810b` (а не main!).
Текущий main: `e3008862fa901886e56587056200347a90258fdc` — НЕ менять до проверки пользователем.
Текущая версия: `0.20.29`; `versionCode=69`.
Автомобиль: **Škoda Yeti 5L MY2011 / 1.2 TSI CBZB / FWD / DSG7 0AM-DQ200**.

Архив: **`YetiGarage_CBZB_3node_REFERENCE_ONLY_batch_v1.zip`**.
Путь на телефоне: **`/sdcard/Download/YetiGarage_CBZB_3node_REFERENCE_ONLY_batch_v1.zip`** (он же `/storage/emulated/0/Download/YetiGarage_CBZB_3node_REFERENCE_ONLY_batch_v1.zip`).

Сначала сверить точный HEAD обеих веток с указанными выше; если изменились — остановиться и объяснить конфликт, не перетирать чужие изменения. Распаковать архив самостоятельно, пользователю файлы вручную раскладывать не нужно. Проверить SHA256 из `SHA256SUMS`; затем проверить JSON/файлы/размеры/part_ids и целостность.

## 2. Базовые и ожидаемые counts

| Метрика | Сейчас (validation) | После интеграции |
|---|---:|---:|
| sections | 24 | 24 |
| nodes TOTAL | 90 | 90 |
| nodes_with_images TOTAL | 90 | 90 |
| nodes_without_images TOTAL | 0 | 0 |
| markers TOTAL | 376 | 376 |
| VERIFIED_ARCHITECTURE total | 55 | **52** |
| REFERENCE_ONLY total | 35 | **38** |
| Active FAIL_ARCHITECTURE | 3 | **0** |
| images_added (ранее пустые узлы) | — | **0** |
| images_replaced (назначения узлов) | — | **3** |
| physical_webp_added | — | **3** |
| physical_webp_replaced | — | **0** |
| markers_added | — | **0** |
| markers_repositioned | — | **10** |

Новых `part_id`: **0**; ничего не переименовывать глобально и не создавать dummy.

## 3. Разрешённые node_id и точные marker positions

Для каждого node_id назначить только указанный новый WebP по своему уникальному пути. Не редактировать байты WebP.

**engine_block_group** — «Блок и кривошипно-шатунный механизм»; `REFERENCE_ONLY`.
Файл `assets/technical_catalog/engine/engine_block_group_cbzb_reference_v1.webp`.
Было `res://assets/technical_catalog/engine/engine_bottom_end.webp`; СТАРЫЙ файл не менять.
Маркеров 4:
- №1 `engine_block` — «Блок двигателя» — x=0.47, y=0.58.
- №2 `crankshaft` — «Коленчатый вал» — x=0.51, y=0.805.
- №3 `piston_group` — «Поршневая группа» — x=0.27, y=0.082.
- №4 `connecting_rods` — «Шатуны» — x=0.255, y=0.27.

**engine_upper_end** — «Головка и клапанный механизм»; `REFERENCE_ONLY`.
Файл `assets/technical_catalog/engine/engine_upper_end_cbzb_reference_v1.webp`.
Было `res://assets/technical_catalog/engine/engine_upper_end.webp`; СТАРЫЙ файл не менять.
Маркеров 3:
- №1 `cylinder_head` — «Головка блока цилиндров» — x=0.18, y=0.73.
- №2 `camshafts` — «Распределительные валы» (в CBZB один вал) — x=0.52, y=0.39.
- №3 `valve_cover` — «Клапанная крышка» — x=0.51, y=0.13.

**cylinder_head_group** — «Головка блока и клапанный механизм»; `REFERENCE_ONLY`.
Файл `assets/technical_catalog/engine/cylinder_head_group_cbzb_reference_v1.webp`.
Было `res://assets/technical_catalog/engine/engine_upper_end.webp`; СТАРЫЙ файл не менять.
Маркеров 3:
- №1 `cylinder_head` — «Головка блока цилиндров» — x=0.13, y=0.78.
- №2 `camshafts` — «Распределительные валы» (в CBZB один вал) — x=0.61, y=0.34.
- №3 `valve_cover` — «Клапанная крышка» — x=0.50, y=0.16.

ВСЕ координаты строго 0..1, номера уникальны внутри node_id. Проверить каждый маркер на наложении: он обязан попадать на ВИДИМУЮ названную деталь. Временные отладочные оверлеи не добавлять в приложение. Если реальная точка не совпадает из-за способа отображения на устройстве — исправить код координат/масштабирования, не менять WebP без разрешения.

## 4. Изменения проекта

По `manifest.json`:
1. Скопировать 3 WebP в точные новые пути проекта; сверить SHA256 исходников и размещённых файлов.
2. Изменить **только** три узла в `data/technical_catalog.json`: `diagram.image`, `diagram.markers[].x/y`, `diagram.verification_level=REFERENCE_ONLY`, `diagram.source` (новая ссылочная информация, автор AI-оригинала, предупреждение о неточной геометрии), `diagram.asset_note`; сохранить `part_ids`, номера и старые данные других полей.
3. Изменить **только** соответствующие три node-записи в `data/technical_visual_audit.json`: новая картинка/хеш, marker positions, architecture_status=REFERENCE_ONLY, визуальные заметки и запись `change_history`; СОХРАНИТЬ исходный исторический аудит и существующие два частичных исправления.
4. При необходимости обновить документацию об этом batch в `docs/audits/batches/` и не менять каталог вне цели.
5. Исторические файлы `engine_bottom_end.webp`, `engine_upper_end.webp`, а также новые `engine_bottom_end_cbzb_reference_v1.webp` и существующий `boost_group.webp` НЕ трогать ни байтом. `engine_block_group` НЕ должен больше ссылаться на изображение `engine_bottom_end`.
6. Никаких дополнительных узлов, новых part_id, dummy, placeholder, пересчёта других маркеров, переименования engine parts.

## 5. Архитектура / ограничения достоверности

CBZB: 4 цилиндра, 8 клапанов, **один** распредвал, роликовые коромысла, крышка ГБЦ с подшипниковой опорой распредвала. Три изображения являются СИНТЕТИЧЕСКИМИ справочными видами. Для всех установить `REFERENCE_ONLY`, не `VERIFIED_ARCHITECTURE` и не `VIN_EXACT`. Схемы не использовать как инструкцию по разборке/ремонту. Информация о снятии коленвала должна сверяться с заводским руководством: нарушение затяжки коренных опор может испортить блок.

`camshafts` — СУЩЕСТВУЮЩИЙ ID, хоть в имени множественное число. **Не создавать второй вал** и не переименовывать общую сущность без отдельного запроса.

## 6. Обязательные UI checks на реальном приложении

Для **каждого** из трёх новых экранов: image load; zoom; pan; reset zoom; show markers; hide markers; tap marker (проверить совпадение номера, part_id и детали); select list row; marker/list synchronization в обе стороны; part card; back navigation; поиск существующих `part_id` и русских названий. Проверить на 360x780 и 420x780 и, если есть доступ, на Android телефоне. Ни один экран не должен показывать «Изображение готовится».

Проверить нативный выпадающий список схем (не отдельный экран), прокрутку во ВСЕХ секциях, особенно «Ошибки», отображение текста без обрезки, значки ошибок, клавиатуру, Android системные панели, отсутствие «.0» у номеров маркеров. При невозможности проверки на физическом телефоне так и написать в отчёте; не ставить PASS физическому тесту.

Регрессия: `engine_bottom_end`, `boost_group`, `engine_complete`, двигатель CBZB целиком, DQ200, подвеска, рулевое, тормоза/ABS, впуск, топливо, охлаждение, выпуск, климат, электрика, освещение, поиск, диагностика. Следить, чтобы старые рабочие секции не изменились.

## 7. Validation / Build / GitHub Actions

Сборку APK **НЕ делать до полной интеграции всех трёх изображений и завершения проверок**.

Порядок:
1. Проверить `git status`, `git diff --check`, SHA256SUMS, JSON, ограничения файлов.
2. Godot import.
3. catalog validation и валидация маркеров, включая 3 новых node_id.
4. startup smoke-check.
5. visual catalog smoke-check (все 10 маркеров с реальными видимыми деталями).
6. Android UX + scroll/focus tests, fault search + warnings tests.
7. Android export (ОДНА validation APK после полного PASS).
8. **Ещё раз** сверить точные counts и список изменённых файлов; при любом расхождении STOP, без релиза.
9. Сделать commit/push в `validation/full-marker-audit-android-ux`, запустить GitHub Actions, добиться `SUCCESS` и ссылки на downloadable **validation APK artifact**, явно обозначить её как `CBZB-5node-VALIDATION` или аналогично.
10. **НЕ** мерджить main, **НЕ** повышать version/versionCode, **НЕ** выпускать release на этом шаге: два предыдущих узла и три новых должны быть проверены пользователем на физическом телефоне. После явного одобрения пользователь даст отдельную команду: merge, один bump `0.20.30 / 70`, финальные regression/Actions/release.

## 8. Финальный отчёт в ответе

Верни строго фактические данные: `images_added`, `images_replaced`, `physical_webp_added`, `markers_added`, `markers_repositioned`, `nodes_with_images TOTAL`, `nodes_without_images TOTAL`, `markers TOTAL`, `new_part_ids`, `modified_node_ids`, `VERIFIED_ARCHITECTURE total`, `REFERENCE_ONLY total`, `active FAIL_ARCHITECTURE`, `version`, `versionCode`, `validation commit`, `main commit`, `GitHub Actions run + SUCCESS/FAIL`, `APK artifact + SHA256 + ссылка`, `физический телефон: TESTED/NOT TESTED`, `список реально изменённых файлов`, `проверки PASS/FAIL и все оставшиеся проблемы`.

Если все counts не совпали, архитектура сомнительна или маркеры не привязаны к деталям — не объявлять batch завершённым, не делать релиз.
