class_name ServiceHistoryService
extends RefCounted

static func add_event(event: Dictionary) -> String:
    var id := "event_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi() % 100000)]
    var new_event := event.duplicate(true)
    new_event["id"] = id
    new_event["created_at"] = int(Time.get_unix_time_from_system())
    new_event["updated_at"] = int(Time.get_unix_time_from_system())
    Storage.data["service_events"].append(new_event)
    Storage.save()
    AppState.history_changed.emit()
    AppState.maintenance_changed.emit()
    return id

static func update_event(id: String, values: Dictionary) -> bool:
    var event_list: Array = Storage.data.get("service_events", [])
    for i in range(event_list.size()):
        if str(event_list[i].get("id", "")) == id:
            var updated: Dictionary = event_list[i].duplicate(true)
            for key in values.keys():
                updated[key] = values[key]
            updated["updated_at"] = int(Time.get_unix_time_from_system())
            event_list[i] = updated
            Storage.save()
            AppState.history_changed.emit()
            AppState.maintenance_changed.emit()
            return true
    return false

static func delete_event(id: String) -> bool:
    var event_list: Array = Storage.data.get("service_events", [])
    for i in range(event_list.size()):
        if str(event_list[i].get("id", "")) == id:
            event_list.remove_at(i)
            Storage.save()
            AppState.history_changed.emit()
            AppState.maintenance_changed.emit()
            return true
    return false

static func events() -> Array:
    var copy: Array = Storage.data.get("service_events", []).duplicate(true)
    copy.sort_custom(func(a, b):
        if str(a.get("date", "")) == str(b.get("date", "")):
            return int(a.get("updated_at", 0)) > int(b.get("updated_at", 0))
        return str(a.get("date", "")) > str(b.get("date", ""))
    )
    return copy

static func events_for_part(part_id: String) -> Array:
    var matching: Array = []
    for event in events():
        if str(event.get("part_id", "")) == part_id:
            matching.append(event)
    return matching

static func latest_event_for_part(part_id: String) -> Dictionary:
    var matching := events_for_part(part_id)
    if matching.is_empty():
        return {}
    return matching[0]

static func latest_event_of_type(event_type: String) -> Dictionary:
    var matching: Array = []
    for event in events():
        if str(event.get("type", "")) == event_type:
            matching.append(event)
    if matching.is_empty():
        return {}
    return matching[0]

static func latest_engine_replacement() -> Dictionary:
    return latest_event_of_type("engine_replacement")

static func total_cost() -> float:
    var total := 0.0
    for event in Storage.data.get("service_events", []):
        total += float(event.get("cost", 0.0))
        total += float(event.get("labor_cost", 0.0))
    return total
