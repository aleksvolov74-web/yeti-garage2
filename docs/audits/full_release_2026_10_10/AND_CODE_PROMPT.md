Продолжи Yeti Garage из сохранённой контрольной точки, не объявляя её release candidate.

Проект: /sdcard/Download/YetiGarage-0.20.0-local-3d/YetiGarage-0.20.0-local-3d
Архив исправлений/журнала: /storage/emulated/0/Download/YetiGarage_audit_checkpoint_2026-10-10.zip
Репозиторий: https://github.com/aleksvolov74-web/yeti-garage2
Ветка: validation/full-marker-audit-android-ux; не менять main, не force-push.
База a9c83e2; исправления сохранения ad7e63f; manual/four-size suite 3bdeae2.
Remote main e300886. Приложение 0.20.29 / versionCode 69. Проверяй фактический HEAD перед продолжением.
Автомобиль: Yeti 5L MY2011 CBZB FWD DSG7 0AM/DQ200.

Архив — только code/audit checkpoint. Он не содержит принятый технический kit и APK. Пользователь ничего вручную не раскладывает: сверяй Git и SHA, применяй только отсутствующие изменения. Не затри пользовательские данные, незакоммиченные отчёты, текущие картинки или координаты. Сначала прочитай QA_REPORT.md, ISSUES.json, PROGRESS.json, SOURCES.md и required_24_review.json. В архиве snapshots внешних MASTER_RULES и старого CURRENT_STATE; старый checkpoint 0.20.26/66 не заменяет фактический репозиторий.

Текущий каталог: 90 узлов/изображений, 376 маркеров, 253 уникальные marker part_id. Новых part_id/маркеров/замен в этой контрольной точке: 0. Исторический комплект /sdcard/Download/YetiGarage_24_resume_work содержит 23 WebP, 130 обязательных связей и 127 подготовленных координат. integration_allowed=false. Старый ACCEPTED не считать независимой новой приёмкой. Не переноcи координаты на другие пиксели.

24 обязательных node_id и все их точные part_id/координаты сохранены в required_24_review.json и исходном manifest. steering_column остаётся BLOCKED_SOURCE_UNVERIFIED: получить разрешённый идентифицированный внутренний вид G85 применимого Yeti Gen3. Корпус, G269 или контактное кольцо не являются заменой. До этого не генерировать выдуманную геометрию и не открывать gate. angle_drive/haldex только AWD REFERENCE_ONLY, скрытые для FWD. Никаких новых dummy ID и удаления существующих деталей.

После устранения source blocker самостоятельно завершить независимую проверку каждого из 127 ранее подготовленных targets, все необходимые исправления отдельных изображений, 3 рулевых targets и полный комплект. Показывать каждую новую генерацию сразу. Magnific запрещён. Исходные забракованные картинки не возвращать. Затем интегрировать kit целиком с сохранением ID, обновить aggregate/batch manifests и SHA, проверить все 24 экрана: image load, zoom/pan/reset, marker/list synchronization, tap, card, поиск, back, FWD/AWD.

Проверки: git diff --check; Godot import; validate_project_resources.gd; validate_storage.gd; validate_3d_catalog.gd; validate_fault_catalog.gd; desktop validate_android_ux.gd (4 размера); validate_manual_pages.gd (246 страниц ×4 и главы); статические marker/visual validators; --require-ready. На ARM64 использовать sh tools/run_godot_arm64.sh и подготовку tools/prepare_godot_arm64_runtime.py --graphics, при необходимости Xvfb. Не заменять реальные тесты анализом.

Только после полной интеграции и всех обязательных проверок: повысить version/versionCode один раз, проверить signing, собрать APK через доступный CI, проверить содержимое/SHA256; установить через ADB и выполнить Android UX с системной клавиатурой. При отсутствии устройства NOT_RUN. До готовности release gate запрещены промежуточные APK и merge. Поддерживать журнал и обновлять draft PR, не публиковать релиз автоматически.

Финальный отчёт: реальные commit/branch/version; image/node/marker/part_id totals; отдельные visual/structural/device результаты PASS/FAIL/NOT_RUN/BLOCKED; Actions/PR ссылки; APK/SHA или точный blocker. Не объявлять полный аудит и релиз готовыми без доказательств.
