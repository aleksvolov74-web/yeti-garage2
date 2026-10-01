class_name VehicleService
extends RefCounted

static func vehicle() -> Dictionary:
    return Storage.data.get("vehicle", {})

static func update_vehicle(changes: Dictionary) -> void:
    var current: Dictionary = Storage.data.get("vehicle", {}).duplicate(true)
    for key in changes.keys():
        current[key] = changes[key]
    Storage.data["vehicle"] = current
    Storage.save()
    AppState.vehicle_changed.emit()
