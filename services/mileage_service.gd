class_name MileageService
extends RefCounted

static func current_mileage() -> int:
    var records: Array = Storage.data.get("mileage_records", [])
    if records.is_empty():
        return 0
    var latest: Dictionary = records[0]
    for record in records:
        if str(record.get("date", "")) > str(latest.get("date", "")):
            latest = record
        elif str(record.get("date", "")) == str(latest.get("date", "")) and int(record.get("created_at", 0)) > int(latest.get("created_at", 0)):
            latest = record
    return int(latest.get("mileage", 0))

static func add_record(mileage: int, date: String, source: String = "manual") -> bool:
    if mileage <= 0:
        return false
    var record := {
        "id": "mileage_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi() % 100000)],
        "date": date,
        "mileage": mileage,
        "source": source,
        "estimated": false,
        "created_at": int(Time.get_unix_time_from_system()),
        "updated_at": int(Time.get_unix_time_from_system())
    }
    Storage.data["mileage_records"].append(record)
    Storage.save()
    AppState.mileage_changed.emit()
    AppState.maintenance_changed.emit()
    return true

static func update_record(id: String, mileage: int, date: String) -> bool:
    if mileage <= 0:
        return false
    var records: Array = Storage.data.get("mileage_records", [])
    for i in range(records.size()):
        if str(records[i].get("id", "")) == id:
            var updated: Dictionary = records[i].duplicate(true)
            updated["mileage"] = mileage
            updated["date"] = date
            updated["updated_at"] = int(Time.get_unix_time_from_system())
            records[i] = updated
            Storage.data["mileage_records"] = records
            Storage.save()
            AppState.mileage_changed.emit()
            AppState.maintenance_changed.emit()
            return true
    return false

static func delete_record(id: String) -> bool:
    var records: Array = Storage.data.get("mileage_records", [])
    for i in range(records.size()):
        if str(records[i].get("id", "")) == id:
            records.remove_at(i)
            Storage.data["mileage_records"] = records
            Storage.save()
            AppState.mileage_changed.emit()
            AppState.maintenance_changed.emit()
            return true
    return false

static func history() -> Array:
    var copy: Array = Storage.data.get("mileage_records", []).duplicate(true)
    copy.sort_custom(func(a, b):
        if str(a.get("date", "")) == str(b.get("date", "")):
            return int(a.get("created_at", 0)) > int(b.get("created_at", 0))
        return str(a.get("date", "")) > str(b.get("date", ""))
    )
    return copy

static func average_km_per_day(max_days: int = 90) -> float:
    var records: Array = history()
    if records.size() < 2:
        return 0.0

    var newest: Dictionary = {}
    var oldest: Dictionary = {}
    var newest_unix := 0
    var oldest_unix := 0
    var cutoff := int(Time.get_unix_time_from_system()) - max_days * 86400

    for record_value in records:
        var record: Dictionary = record_value
        if bool(record.get("estimated", false)):
            continue
        var date_string := str(record.get("date", ""))
        var unix := _date_to_unix(date_string)
        if unix <= 0:
            continue
        if newest.is_empty():
            newest = record
            newest_unix = unix
        if unix >= cutoff:
            oldest = record
            oldest_unix = unix

    if newest.is_empty() or oldest.is_empty() or newest_unix <= oldest_unix:
        return 0.0

    var distance := int(newest.get("mileage", 0)) - int(oldest.get("mileage", 0))
    if distance <= 0:
        return 0.0
    var days := float(newest_unix - oldest_unix) / 86400.0
    if days < 1.0:
        return 0.0
    return float(distance) / days

static func projected_days_for_distance(distance_km: int, max_days: int = 90) -> int:
    if distance_km <= 0:
        return 0
    var rate := average_km_per_day(max_days)
    if rate <= 0.0:
        return -1
    return int(ceil(float(distance_km) / rate))

static func _date_to_unix(date_string: String) -> int:
    var parts := date_string.split("-")
    if parts.size() != 3:
        return 0
    return int(Time.get_unix_time_from_datetime_dict({
        "year": int(parts[0]),
        "month": int(parts[1]),
        "day": int(parts[2]),
        "hour": 0,
        "minute": 0,
        "second": 0
    }))
