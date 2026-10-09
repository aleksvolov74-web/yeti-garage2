# Yeti Garage — следующий batch: 3 узла CBZB

**Статус: подготовлено к полной интеграции в validation-ветку, НЕ релиз.**

Автомобиль: Škoda Yeti 5L MY2011 / CBZB / FWD / 0AM-DQ200.

- Исходная ветка: validation/full-marker-audit-android-ux @ ff73f211e73db4d3f8f72838eebc97eb0a57810b.
- main @ e3008862fa901886e56587056200347a90258fdc (не изменять).
- Версия 0.20.29, versionCode 69.
- Изменить только: engine_block_group, engine_upper_end, cylinder_head_group.
- Внутри архива 3 разных WebP (по одному на каждый node_id), manifest.json, SOURCES.md, SHA256SUMS и AND_CODE_PROMPT.md.
- Визуальные метки: 4 + 3 + 3 = 10. 10 существующих маркеров переместить, 0 добавить.
- Статус всех трёх узлов REFERENCE_ONLY.
- Состояние каталога должно остаться 90/90 изображений, 376 маркеров, 0 пустых узлов.
- Ожидаемые статусы после интеграции: 52 VERIFIED_ARCHITECTURE / 38 REFERENCE_ONLY; 0 активных FAIL_ARCHITECTURE.
- **Нельзя переписывать** общий WebP `engine_upper_end.webp` (раньше был разделён между двумя узлами) и `engine_bottom_end.webp`.
- Окончательный релиз только после проверки готовой APK на физическом телефоне и отдельного разрешения пользователя.

Инструкция для And Code: **AND_CODE_PROMPT.md**.
