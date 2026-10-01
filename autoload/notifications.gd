extends Node

signal status_changed
signal test_result(message: String)
signal maintenance_notification_opened(item_id: String)

const CHANNEL_ID := "yeti_maintenance"
const CHANNEL_NAME := "Обслуживание Yeti"
const CHANNEL_DESCRIPTION := "Напоминания о техническом обслуживании автомобиля"

var _scheduler: Node = null
var _initialized := false
var _channel_ready := false
var _last_sync_signature := ""

func _ready() -> void:
    call_deferred("_setup")

func _setup() -> void:
    if OS.get_name() != "Android":
        status_changed.emit()
        return
    if not _plugin_classes_available():
        status_changed.emit()
        return

    var instance = ClassDB.instantiate("NotificationScheduler")
    if instance == null or not (instance is Node):
        status_changed.emit()
        return

    _scheduler = instance as Node
    _scheduler.name = "YetiNotificationScheduler"
    add_child(_scheduler)

    if _scheduler.has_signal("initialization_completed"):
        _scheduler.connect("initialization_completed", _on_initialized)
    if _scheduler.has_signal("post_notifications_permission_granted"):
        _scheduler.connect("post_notifications_permission_granted", _on_permission_changed)
    if _scheduler.has_signal("post_notifications_permission_denied"):
        _scheduler.connect("post_notifications_permission_denied", _on_permission_changed)
    if _scheduler.has_signal("notification_opened"):
        _scheduler.connect("notification_opened", _on_notification_opened)
    if _scheduler.has_signal("notification_dismissed"):
        _scheduler.connect("notification_dismissed", _on_notification_dismissed)

    if _scheduler.has_method("initialize"):
        _scheduler.call("initialize")
    else:
        _initialized = true
        _ensure_channel()
        status_changed.emit()

func _plugin_classes_available() -> bool:
    return ClassDB.class_exists("NotificationScheduler") \
        and ClassDB.class_exists("NotificationChannel") \
        and ClassDB.class_exists("NotificationData")

func notifications_enabled() -> bool:
    return bool(Storage.data.get("notification_settings", {}).get("enabled", true))

func set_notifications_enabled(enabled: bool) -> void:
    var settings: Dictionary = Storage.data.get("notification_settings", {})
    settings["enabled"] = enabled
    Storage.data["notification_settings"] = settings
    if not enabled:
        _cancel_previous_scheduled()
    Storage.save()
    status_changed.emit()
    if enabled:
        sync_maintenance(true)

func platform_supported() -> bool:
    return OS.get_name() == "Android"

func plugin_available() -> bool:
    return _scheduler != null and is_instance_valid(_scheduler)

func is_initialized() -> bool:
    return plugin_available() and _initialized

func has_permission() -> bool:
    if not is_initialized() or not _scheduler.has_method("has_post_notifications_permission"):
        return false
    return bool(_scheduler.call("has_post_notifications_permission"))

func has_battery_optimization_permission() -> bool:
    if not is_initialized() or not _scheduler.has_method("has_battery_optimizations_permission"):
        return false
    return bool(_scheduler.call("has_battery_optimizations_permission"))

func has_exact_alarm_permission() -> bool:
    if not is_initialized() or not _scheduler.has_method("has_schedule_exact_alarm_permission"):
        return false
    return bool(_scheduler.call("has_schedule_exact_alarm_permission"))

func status_text() -> String:
    if not notifications_enabled():
        return "Системные уведомления выключены в Yeti Garage."
    if OS.get_name() != "Android":
        return "Системные уведомления будут доступны в Android-сборке. В редакторе работает центр напоминаний внутри приложения."
    if not _plugin_classes_available():
        return "Android готов, но Notification Scheduler ещё не установлен в эту сборку. Внутренние напоминания работают без него."
    if not plugin_available() or not _initialized:
        return "Модуль уведомлений загружается…"
    if not has_permission():
        return "Нужно разрешить Yeti Garage показывать уведомления."
    var reliability := ""
    if _scheduler.has_method("has_battery_optimizations_permission") and not has_battery_optimization_permission():
        reliability = " Телефон может задерживать уведомления из-за экономии батареи."
    return "✅ Системные Android-уведомления разрешены." + reliability

func request_permission() -> bool:
    if not is_initialized():
        test_result.emit("Модуль системных уведомлений пока недоступен в этой сборке.")
        return false
    if has_permission():
        test_result.emit("Разрешение на уведомления уже есть.")
        status_changed.emit()
        return true
    if _scheduler.has_method("request_post_notifications_permission"):
        _scheduler.call("request_post_notifications_permission")
        return true
    return false

func request_reliable_delivery() -> bool:
    if not is_initialized():
        test_result.emit("Настройка доступна только в Android-сборке с Notification Scheduler.")
        return false
    if _scheduler.has_method("has_battery_optimizations_permission") and _scheduler.has_method("request_battery_optimizations_permission"):
        if not has_battery_optimization_permission():
            _scheduler.call("request_battery_optimizations_permission")
            test_result.emit("Открыт системный запрос. Разрешение не обязательно, но помогает доставлять напоминания вовремя.")
            return true
    if _scheduler.has_method("has_schedule_exact_alarm_permission") and _scheduler.has_method("request_schedule_exact_alarm_permission"):
        if not has_exact_alarm_permission():
            _scheduler.call("request_schedule_exact_alarm_permission")
            test_result.emit("Открыт системный запрос на точные напоминания.")
            return true
    test_result.emit("Дополнительные разрешения уже выданы или не нужны на этом устройстве.")
    return true

func open_app_notification_settings() -> bool:
    if not is_initialized() or not _scheduler.has_method("open_app_info_settings"):
        test_result.emit("Настройки приложения доступны только в Android-сборке с модулем уведомлений.")
        return false
    var result = _scheduler.call("open_app_info_settings")
    return int(result) == OK if typeof(result) == TYPE_INT else true

func schedule_test(delay_seconds: int = 10) -> bool:
    if not _can_schedule():
        test_result.emit("Системное уведомление пока нельзя отправить. Внутренние напоминания продолжат работать.")
        return false
    var ok := _schedule(
        900001,
        "Yeti Garage",
        "Тестовое уведомление работает 🔧",
        maxi(delay_seconds, 2),
        "test"
    )
    var message := "Тест запланирован через %s сек." % str(maxi(delay_seconds, 2)) if ok else "Не удалось запланировать тест."
    test_result.emit(message)
    return ok

func sync_maintenance(force: bool = false) -> void:
    if not notifications_enabled():
        _cancel_previous_scheduled()
        return
    if not _can_schedule():
        return

    var signature := _maintenance_signature()
    if not force and signature == _last_sync_signature:
        return
    _last_sync_signature = signature

    _cancel_previous_scheduled()
    var scheduled_ids: Array = []

    for item_value in MaintenanceService.items():
        var item: Dictionary = item_value
        var status := str(item.get("status", "unknown"))
        if status == "unknown":
            continue

        var item_key := str(item.get("id", "maintenance"))
        var base_id := 100000 + int(abs(item_key.hash()) % 700000)
        var title := str(item.get("title", "Обслуживание"))

        # Не спамим мгновенными системными уведомлениями при каждом запуске,
        # если работа уже просрочена. Просрочку всегда видно в центре напоминаний.
        if status in ["due", "overdue"]:
            continue

        var warning_delay := _warning_delay_seconds(item)
        if warning_delay >= 2:
            var warning_id := base_id
            if _schedule(warning_id, "Скоро: %s" % title, _notification_message(item), warning_delay, item_key):
                scheduled_ids.append(warning_id)

        var due_delay := _due_delay_seconds(item)
        if due_delay >= 2:
            var due_id := base_id + 1
            if _schedule(due_id, "Пора: %s" % title, _notification_message(item), due_delay, item_key):
                scheduled_ids.append(due_id)

    Storage.data["scheduled_notification_ids"] = scheduled_ids
    var runtime: Dictionary = Storage.data.get("notification_runtime", {})
    runtime["last_sync_at"] = int(Time.get_unix_time_from_system())
    Storage.data["notification_runtime"] = runtime
    Storage.save()

func _on_initialized() -> void:
    _initialized = true
    _ensure_channel()
    status_changed.emit()
    sync_maintenance(false)

func _on_permission_changed(_permission_name: String = "") -> void:
    status_changed.emit()
    if has_permission():
        sync_maintenance(true)

func _on_notification_opened(notification_data) -> void:
    var item_id := _extract_item_id(notification_data)
    var runtime: Dictionary = Storage.data.get("notification_runtime", {})
    runtime["last_opened_item_id"] = item_id
    Storage.data["notification_runtime"] = runtime
    Storage.save()
    if item_id != "" and item_id != "test":
        maintenance_notification_opened.emit(item_id)

func _on_notification_dismissed(notification_data) -> void:
    var item_id := _extract_item_id(notification_data)
    var runtime: Dictionary = Storage.data.get("notification_runtime", {})
    runtime["last_dismissed_item_id"] = item_id
    Storage.data["notification_runtime"] = runtime
    Storage.save()

func consume_last_opened_item_id() -> String:
    var runtime: Dictionary = Storage.data.get("notification_runtime", {})
    var item_id := str(runtime.get("last_opened_item_id", ""))
    if item_id != "":
        runtime["last_opened_item_id"] = ""
        Storage.data["notification_runtime"] = runtime
        Storage.save()
    return item_id

func _extract_item_id(notification_data) -> String:
    if notification_data == null:
        return ""
    var deeplink = notification_data.get("deeplink") if notification_data is Object else null
    var value := str(deeplink) if deeplink != null else ""
    const PREFIX := "yetigarage://maintenance/"
    if value.begins_with(PREFIX):
        return value.trim_prefix(PREFIX)
    return ""

func _ensure_channel() -> void:
    if _channel_ready or not plugin_available() or not ClassDB.class_exists("NotificationChannel"):
        return
    var channel = ClassDB.instantiate("NotificationChannel")
    if channel == null:
        return
    if channel.has_method("set_id"):
        channel.call("set_id", CHANNEL_ID)
    if channel.has_method("set_name"):
        channel.call("set_name", CHANNEL_NAME)
    if channel.has_method("set_description"):
        channel.call("set_description", CHANNEL_DESCRIPTION)
    if channel.has_method("set_importance"):
        channel.call("set_importance", 3)
    if _scheduler.has_method("create_notification_channel"):
        var result = _scheduler.call("create_notification_channel", channel)
        _channel_ready = int(result) in [0, 32]

func _can_schedule() -> bool:
    return notifications_enabled() and is_initialized() and _channel_ready and has_permission()

func _schedule(id: int, title: String, content: String, delay_seconds: int, item_id: String = "") -> bool:
    if not _can_schedule() or not ClassDB.class_exists("NotificationData"):
        return false
    var notification_payload = ClassDB.instantiate("NotificationData")
    if notification_payload == null:
        return false
    if notification_payload.has_method("set_id"):
        notification_payload.call("set_id", id)
    if notification_payload.has_method("set_channel_id"):
        notification_payload.call("set_channel_id", CHANNEL_ID)
    if notification_payload.has_method("set_title"):
        notification_payload.call("set_title", title)
    if notification_payload.has_method("set_content"):
        notification_payload.call("set_content", content)
    if notification_payload.has_method("set_delay"):
        notification_payload.call("set_delay", delay_seconds)
    if item_id != "" and notification_payload.has_method("set_deeplink"):
        notification_payload.call("set_deeplink", "yetigarage://maintenance/%s" % item_id)
    if _scheduler.has_method("schedule"):
        return int(_scheduler.call("schedule", notification_payload)) == OK
    return false

func _cancel_previous_scheduled() -> void:
    if not plugin_available() or not _scheduler.has_method("cancel"):
        return
    for id_value in Storage.data.get("scheduled_notification_ids", []):
        _scheduler.call("cancel", int(id_value))
    Storage.data["scheduled_notification_ids"] = []

func _warning_delay_seconds(item: Dictionary) -> int:
    var seconds_per_day := 86400
    var candidates: Array[int] = []

    var remaining_days = item.get("remaining_days", null)
    if remaining_days != null:
        var warning_days := int(item.get("warning_days", 30))
        var days_until_warning := int(remaining_days) - warning_days
        if days_until_warning > 0:
            candidates.append(days_until_warning * seconds_per_day)

    var remaining_km = item.get("remaining_km", null)
    if remaining_km != null:
        var warning_km := int(item.get("warning_km", 1000))
        var distance_until_warning := int(remaining_km) - warning_km
        if distance_until_warning > 0:
            var projected_days := MileageService.projected_days_for_distance(distance_until_warning)
            if projected_days > 0:
                candidates.append(projected_days * seconds_per_day)

    if candidates.is_empty():
        return -1
    var best := candidates[0]
    for candidate in candidates:
        best = mini(best, candidate)
    return best

func _due_delay_seconds(item: Dictionary) -> int:
    var seconds_per_day := 86400
    var candidates: Array[int] = []

    var remaining_days = item.get("remaining_days", null)
    if remaining_days != null and int(remaining_days) > 0:
        candidates.append(int(remaining_days) * seconds_per_day)

    var remaining_km = item.get("remaining_km", null)
    if remaining_km != null and int(remaining_km) > 0:
        var projected_days := MileageService.projected_days_for_distance(int(remaining_km))
        if projected_days > 0:
            candidates.append(projected_days * seconds_per_day)

    if candidates.is_empty():
        return -1
    var best := candidates[0]
    for candidate in candidates:
        best = mini(best, candidate)
    return best

func _notification_message(item: Dictionary) -> String:
    var remaining_km = item.get("remaining_km", null)
    var remaining_days = item.get("remaining_days", null)
    var chunks: Array[String] = []
    if remaining_km != null:
        chunks.append("по пробегу осталось примерно %s км" % _format_int(maxi(0, int(remaining_km))))
    if remaining_days != null:
        chunks.append("по времени — %s дн." % str(maxi(0, int(remaining_days))))
    if chunks.is_empty():
        return "Открой Yeti Garage и проверь план обслуживания."
    return ", ".join(chunks) + "."

func _maintenance_signature() -> String:
    var parts: Array[String] = []
    for item_value in MaintenanceService.items():
        var item: Dictionary = item_value
        parts.append("%s:%s:%s:%s" % [
            str(item.get("id", "")),
            str(item.get("status", "")),
            str(item.get("remaining_km", "")),
            str(item.get("remaining_days", ""))
        ])
    return "|".join(parts)

func _format_int(value: int) -> String:
    var s := str(abs(value))
    var out := ""
    while s.length() > 3:
        out = " " + s.right(3) + out
        s = s.left(s.length() - 3)
    out = s + out
    return ("-" if value < 0 else "") + out
