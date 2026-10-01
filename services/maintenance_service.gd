class_name MaintenanceService
extends RefCounted

const DAY_SECONDS := 86400

static func items() -> Array:
    var output: Array = []
    var current := MileageService.current_mileage()
    for rule in Storage.data.get("maintenance_rules", []):
        var item: Dictionary = rule.duplicate(true)
        var last := ServiceHistoryService.latest_event_of_type(str(rule.get("event_type", "")))
        item["last_event"] = last
        item["status"] = "unknown"
        item["remaining_km"] = null
        item["remaining_days"] = null
        item["next_mileage"] = null
        item["next_date"] = ""
        item["projected_days_by_mileage"] = null
        item["projected_date_by_mileage"] = ""

        if not last.is_empty():
            var interval_km := int(rule.get("interval_km", 0))
            var interval_days := int(rule.get("interval_days", 0))
            if interval_km > 0 and not bool(last.get("mileage_unknown", false)) and int(last.get("mileage", 0)) > 0:
                var next_km := int(last.get("mileage", 0)) + interval_km
                item["next_mileage"] = next_km
                item["remaining_km"] = next_km - current if current > 0 else null
            if interval_days > 0 and not bool(last.get("date_unknown", false)):
                var date_string := str(last.get("date", ""))
                var unix := _date_to_unix(date_string)
                if unix > 0:
                    var next_unix := unix + interval_days * DAY_SECONDS
                    item["next_date"] = Time.get_date_string_from_unix_time(next_unix)
                    var today_unix := _date_to_unix(Time.get_date_string_from_system())
                    item["remaining_days"] = int(floor(float(next_unix - today_unix) / DAY_SECONDS))
            if item["remaining_km"] != null and int(item["remaining_km"]) > 0:
                var projected_days := MileageService.projected_days_for_distance(int(item["remaining_km"]))
                if projected_days >= 0:
                    item["projected_days_by_mileage"] = projected_days
                    var today_unix := _date_to_unix(Time.get_date_string_from_system())
                    item["projected_date_by_mileage"] = Time.get_date_string_from_unix_time(today_unix + projected_days * DAY_SECONDS)
            if item["remaining_km"] != null or item["remaining_days"] != null:
                item["status"] = _status_for(item)
        output.append(item)

    output.sort_custom(func(a, b): return _priority(str(a.get("status", "unknown"))) < _priority(str(b.get("status", "unknown"))))
    return output

static func _status_for(item: Dictionary) -> String:
    var km = item.get("remaining_km", null)
    var days = item.get("remaining_days", null)
    var warning_km := int(item.get("warning_km", 1000))
    var warning_days := int(item.get("warning_days", 30))

    if km != null and int(km) < 0:
        return "overdue"
    if days != null and int(days) < 0:
        return "overdue"
    if km != null and int(km) == 0:
        return "due"
    if days != null and int(days) == 0:
        return "due"
    if km != null and int(km) <= warning_km:
        return "soon"
    if days != null and int(days) <= warning_days:
        return "soon"
    return "normal"

static func _priority(status: String) -> int:
    match status:
        "overdue": return 0
        "due": return 1
        "soon": return 2
        "normal": return 3
        _: return 4

static func _date_to_unix(date_string: String) -> int:
    var parts := date_string.split("-")
    if parts.size() != 3:
        return 0
    var dt := {
        "year": int(parts[0]),
        "month": int(parts[1]),
        "day": int(parts[2]),
        "hour": 0,
        "minute": 0,
        "second": 0
    }
    return int(Time.get_unix_time_from_datetime_dict(dt))
