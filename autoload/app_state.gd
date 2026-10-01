extends Node

signal data_changed
signal mileage_changed
signal history_changed
signal maintenance_changed
signal vehicle_changed

func notify_all() -> void:
    data_changed.emit()
    mileage_changed.emit()
    history_changed.emit()
    maintenance_changed.emit()
    vehicle_changed.emit()
