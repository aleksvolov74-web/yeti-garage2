class_name ReminderService
extends RefCounted

static func active_reminders() -> Array:
    var reminders: Array = []
    for item in MaintenanceService.items():
        var status := str(item.get("status", "unknown"))
        if status not in ["soon", "due", "overdue"]:
            continue
        var reminder_id := "maintenance_%s" % str(item.get("id", "item"))
        if _is_snoozed(reminder_id):
            continue
        reminders.append({
            "id": reminder_id,
            "kind": "maintenance",
            "status": status,
            "title": str(item.get("title", "Обслуживание")),
            "message": _message_for(item),
            "maintenance_item": item
        })
    reminders.sort_custom(func(a, b): return _priority(str(a.get("status", "unknown"))) < _priority(str(b.get("status", "unknown"))))
    return reminders

static func missing_baselines() -> Array:
    var items: Array = []
    for item in MaintenanceService.items():
        if str(item.get("status", "unknown")) == "unknown":
            items.append(item)
    return items

static func summary() -> Dictionary:
    var reminders := active_reminders()
    var overdue := 0
    var due := 0
    var soon := 0
    for reminder in reminders:
        match str(reminder.get("status", "")):
            "overdue": overdue += 1
            "due": due += 1
            "soon": soon += 1
    return {
        "total": reminders.size(),
        "overdue": overdue,
        "due": due,
        "soon": soon,
        "missing_baselines": missing_baselines().size()
    }

static func _message_for(item: Dictionary) -> String:
    var chunks: Array[String] = []
    var km = item.get("remaining_km", null)
    var days = item.get("remaining_days", null)
    if km != null:
        var km_value := int(km)
        if km_value < 0:
            chunks.append("просрочено на %s км" % _format_int(abs(km_value)))
        elif km_value == 0:
            chunks.append("срок по пробегу наступил")
        else:
            chunks.append("осталось %s км" % _format_int(km_value))
    if days != null:
        var day_value := int(days)
        if day_value < 0:
            chunks.append("просрочено на %s дн." % str(abs(day_value)))
        elif day_value == 0:
            chunks.append("срок по дате наступил")
        else:
            chunks.append("осталось %s дн." % str(day_value))
    var projected_date := str(item.get("projected_date_by_mileage", ""))
    if projected_date != "" and km != null and int(km) > 0:
        chunks.append("по темпу езды ≈ %s" % _display_date(projected_date))
    if chunks.is_empty():
        return "Пора проверить запись обслуживания."
    return " • ".join(chunks)

static func _display_date(value: String) -> String:
    var parts := value.split("-")
    if parts.size() != 3:
        return value
    return "%s.%s.%s" % [parts[2], parts[1], parts[0]]

static func _priority(status: String) -> int:
    match status:
        "overdue": return 0
        "due": return 1
        "soon": return 2
        _: return 3

static func _format_int(value: int) -> String:
    var s := str(abs(value))
    var out := ""
    while s.length() > 3:
        out = " " + s.substr(s.length() - 3, 3) + out
        s = s.substr(0, s.length() - 3)
    out = s + out
    return ("-" if value < 0 else "") + out

static func snooze(reminder_id: String, days: int = 7) -> void:
    if reminder_id == "":
        return
    var snoozes: Dictionary = Storage.data.get("reminder_snoozes", {}).duplicate(true)
    var until_unix := int(Time.get_unix_time_from_system()) + maxi(days, 1) * 86400
    snoozes[reminder_id] = until_unix
    Storage.data["reminder_snoozes"] = snoozes
    Storage.save()
    AppState.maintenance_changed.emit()

static func clear_snooze(reminder_id: String) -> void:
    var snoozes: Dictionary = Storage.data.get("reminder_snoozes", {}).duplicate(true)
    if snoozes.has(reminder_id):
        snoozes.erase(reminder_id)
        Storage.data["reminder_snoozes"] = snoozes
        Storage.save()
        AppState.maintenance_changed.emit()

static func snoozed_until(reminder_id: String) -> int:
    var snoozes: Dictionary = Storage.data.get("reminder_snoozes", {})
    return int(snoozes.get(reminder_id, 0))

static func _is_snoozed(reminder_id: String) -> bool:
    var until_unix := snoozed_until(reminder_id)
    if until_unix <= 0:
        return false
    if until_unix <= int(Time.get_unix_time_from_system()):
        var snoozes: Dictionary = Storage.data.get("reminder_snoozes", {}).duplicate(true)
        snoozes.erase(reminder_id)
        Storage.data["reminder_snoozes"] = snoozes
        Storage.save()
        return false
    return true
