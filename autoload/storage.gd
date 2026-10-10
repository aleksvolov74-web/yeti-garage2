extends Node

signal persistence_failed(message: String)

const REAL_DATA_PATH := "user://yeti_garage_data.json"
const REAL_BACKUP_PATH := "user://yeti_garage_data.backup.json"
const DEMO_DATA_PATH := "user://yeti_garage_demo.json"
const DEMO_BACKUP_PATH := "user://yeti_garage_demo.backup.json"
const REAL_MANUAL_BACKUP_PATH := "user://yeti_garage_data.manual_backup.json"
const DEMO_MANUAL_BACKUP_PATH := "user://yeti_garage_demo.manual_backup.json"
const SCHEMA_VERSION := 8
const TRANSFER_FORMAT := "yeti_garage_transfer_v1"

var data: Dictionary = {}
var demo_mode := false
var storage_writable := true

func _ready() -> void:
    load_or_create()

func default_data() -> Dictionary:
    return {
        "schema_version": SCHEMA_VERSION,
        "vehicle": {
            "id": "vehicle_yeti_001",
            "vin": "XW8JF25LXBK701304",
            "make": "Skoda",
            "model": "Yeti",
            "generation": "5L",
            "year": 2011,
            "factory_engine_code": "CBZB",
            "factory_engine_name": "1.2 TSI",
            "engine_replacement_known": true,
            "current_engine_confirmed": true,
            "current_engine_code": "CBZB",
            "current_engine_name": "1.2 TSI",
            "power_hp": 105,
            "drivetrain": "FWD",
            "transmission": "DSG 7",
            "transmission_family": "0AM / DQ200",
            "transmission_code": "",
            "nickname": "Моя Yeti"
        },
        "mileage_records": [],
        "service_events": [],
        "reminder_snoozes": {},
        "scheduled_notification_ids": [],
        "notification_settings": {"enabled": true},
        "notification_runtime": {"last_sync_at": 0, "last_opened_item_id": "", "last_dismissed_item_id": ""},
        "install_info": {"first_run_at": int(Time.get_unix_time_from_system()), "last_transfer_import_at": 0},
        "active_repair_session": {},
        "saved_faults": [],
        "maintenance_rules": [
            {"id":"engine_oil","title":"Масло двигателя","interval_km":10000,"interval_days":365,"warning_km":1000,"warning_days":30,"event_type":"engine_oil"},
            {"id":"oil_filter","title":"Масляный фильтр","interval_km":10000,"interval_days":365,"warning_km":1000,"warning_days":30,"event_type":"oil_filter"},
            {"id":"air_filter","title":"Воздушный фильтр","interval_km":15000,"interval_days":365,"warning_km":1500,"warning_days":30,"event_type":"air_filter"},
            {"id":"coolant","title":"Охлаждающая жидкость","interval_km":60000,"interval_days":1460,"warning_km":3000,"warning_days":60,"event_type":"coolant"},
            {"id":"brake_fluid","title":"Тормозная жидкость","interval_km":0,"interval_days":730,"warning_km":0,"warning_days":30,"event_type":"brake_fluid"}
        ]
    }

func demo_data() -> Dictionary:
    var demo := default_data()
    demo["vehicle"] = {
        "id": "vehicle_yeti_demo",
        "vin": "DEMO-YETI-001",
        "make": "Skoda",
        "model": "Yeti",
        "generation": "5L",
        "year": 2011,
        "factory_engine_code": "CBZB",
        "factory_engine_name": "1.2 TSI",
        "engine_replacement_known": true,
        "current_engine_confirmed": true,
        "current_engine_code": "CBZB",
        "current_engine_name": "1.2 TSI",
        "power_hp": 105,
        "drivetrain": "FWD",
        "transmission": "DSG 7, демо",
        "transmission_family": "0AM / DQ200",
        "nickname": "ДЕМО — Yeti"
    }
    demo["mileage_records"] = [
        {"id":"demo_mileage_1","date":"2026-09-28","mileage":120000,"source":"demo","estimated":false,"created_at":1790610000}
    ]
    demo["service_events"] = [
        {"id":"demo_engine","vehicle_id":"vehicle_yeti_demo","type":"engine_replacement","date":"2026-01-15","date_unknown":false,"mileage":110000,"mileage_unknown":false,"title":"Замена двигателя","cost":65000.0,"labor_cost":18000.0,"notes":"Демонстрационная запись","engine_code":"CBZB","engine_initial_mileage":70000,"engine_initial_mileage_unknown":false,"created_at":1768470000,"updated_at":1768470000},
        {"id":"demo_oil","vehicle_id":"vehicle_yeti_demo","type":"engine_oil","date":"2026-06-12","date_unknown":false,"mileage":115000,"mileage_unknown":false,"title":"Замена масла двигателя","cost":4200.0,"labor_cost":0.0,"notes":"Демонстрационная запись","created_at":1781230000,"updated_at":1781230000},
        {"id":"demo_air","vehicle_id":"vehicle_yeti_demo","type":"air_filter","date":"2026-05-02","date_unknown":false,"mileage":113500,"mileage_unknown":false,"title":"Замена воздушного фильтра","cost":900.0,"labor_cost":0.0,"notes":"Демонстрационная запись","created_at":1777690000,"updated_at":1777690000},
        {"id":"demo_coolant","vehicle_id":"vehicle_yeti_demo","type":"coolant","date":"2024-08-10","date_unknown":false,"mileage":90000,"mileage_unknown":false,"title":"Замена антифриза","cost":3000.0,"labor_cost":1500.0,"notes":"Демонстрационная запись","created_at":1723250000,"updated_at":1723250000},
        {"id":"demo_brake_fluid","vehicle_id":"vehicle_yeti_demo","type":"brake_fluid","date":"2024-09-01","date_unknown":false,"mileage":92000,"mileage_unknown":false,"title":"Замена тормозной жидкости","cost":1200.0,"labor_cost":1200.0,"notes":"Демонстрационная запись","created_at":1725140000,"updated_at":1725140000},
        {"id":"demo_pads","vehicle_id":"vehicle_yeti_demo","type":"part_replacement","date":"2026-03-20","date_unknown":false,"mileage":112000,"mileage_unknown":false,"title":"Замена передних тормозных колодок","part_id":"brake_pads","cost":3800.0,"labor_cost":1500.0,"notes":"Демонстрационная запись","created_at":1773960000,"updated_at":1773960000}
    ]
    return demo

func is_demo_mode() -> bool:
    return demo_mode

func set_demo_mode(enabled: bool) -> void:
    if demo_mode == enabled:
        return
    if not save():
        return
    demo_mode = enabled
    load_or_create()
    AppState.notify_all()

func _read_vehicle_file(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parser := JSON.new()
    var result := parser.parse(file.get_as_text())
    file.close()
    if result != OK:
        push_warning("Invalid vehicle JSON in %s: %s" % [path, parser.get_error_message()])
        return {}
    var parsed = parser.data
    if parsed is Dictionary and _looks_like_vehicle_data(parsed):
        return parsed
    return {}

func load_or_create() -> void:
    storage_writable = true
    var path := _data_path()
    var parsed := _read_vehicle_file(path)
    if parsed.is_empty():
        parsed = _read_vehicle_file(_backup_path())
        if not parsed.is_empty():
            push_warning("Recovered vehicle data from backup; original file retained until next save.")
        elif FileAccess.file_exists(path) or FileAccess.file_exists(_backup_path()):
            # Keep unreadable files intact. Defaults are only an in-memory fallback.
            storage_writable = false
            data = demo_data() if demo_mode else default_data()
            push_warning("Vehicle data and backup cannot be read. Saving is blocked to preserve existing files.")
            return
        else:
            data = demo_data() if demo_mode else default_data()
            save()
            return
    data = parsed
    var previous_schema := int(data.get("schema_version", 1))
    _ensure_schema()
    if previous_schema < SCHEMA_VERSION:
        save()

func _ensure_schema() -> void:
    var defaults := default_data()
    if not data.has("schema_version"):
        data["schema_version"] = 1
    if not data.has("vehicle"):
        data["vehicle"] = defaults["vehicle"]
    _migrate_vehicle_engine_fields()
    if not data.has("mileage_records"):
        data["mileage_records"] = []
    if not data.has("service_events"):
        data["service_events"] = []
    if not data.has("maintenance_rules"):
        data["maintenance_rules"] = defaults["maintenance_rules"]
    if not data.has("reminder_snoozes"):
        data["reminder_snoozes"] = {}
    if not data.has("scheduled_notification_ids"):
        data["scheduled_notification_ids"] = []
    if not data.has("notification_settings"):
        data["notification_settings"] = {"enabled": true}
    if not data.has("notification_runtime"):
        data["notification_runtime"] = {"last_sync_at": 0, "last_opened_item_id": "", "last_dismissed_item_id": ""}
    if not data.has("install_info"):
        data["install_info"] = {"first_run_at": int(Time.get_unix_time_from_system()), "last_transfer_import_at": 0}
    if not data.has("active_repair_session"):
        data["active_repair_session"] = {}
    if not data.has("saved_faults"):
        data["saved_faults"] = []
    data["schema_version"] = SCHEMA_VERSION


func _migrate_vehicle_engine_fields() -> void:
    var vehicle: Dictionary = data.get("vehicle", {})
    var defaults: Dictionary = default_data().get("vehicle", {})

    # До схемы v8 поля engine_name/engine_code одновременно использовались как
    # заводская конфигурация и как будто бы текущий двигатель. Это неверно для
    # машин, где двигатель уже менялся. Сохраняем старые значения как заводские.
    if not vehicle.has("factory_engine_code"):
        vehicle["factory_engine_code"] = str(vehicle.get("engine_code", defaults.get("factory_engine_code", "")))
    if not vehicle.has("factory_engine_name"):
        vehicle["factory_engine_name"] = str(vehicle.get("engine_name", defaults.get("factory_engine_name", "")))

    # VIN-профиль Yeti задан владельцем: MY2011, CBZB, FWD, DSG7 / 0AM.
    # Точный код КПП и PR-коды остаются неизвестными.
    if not vehicle.has("engine_replacement_known"):
        vehicle["engine_replacement_known"] = str(vehicle.get("vin", "")) == "XW8JF25LXBK701304"
    if not vehicle.has("current_engine_confirmed"):
        vehicle["current_engine_confirmed"] = false
    if not vehicle.has("current_engine_code"):
        vehicle["current_engine_code"] = ""
    if not vehicle.has("current_engine_name"):
        vehicle["current_engine_name"] = ""
    if str(vehicle.get("vin", "")) == "XW8JF25LXBK701304":
        vehicle["year"] = 2011
        vehicle["generation"] = "5L"
        vehicle["factory_engine_code"] = "CBZB"
        vehicle["factory_engine_name"] = "1.2 TSI"
        vehicle["current_engine_confirmed"] = true
        vehicle["current_engine_code"] = "CBZB"
        vehicle["current_engine_name"] = "1.2 TSI"
        vehicle["drivetrain"] = "FWD"
        vehicle["transmission"] = "DSG 7"
        vehicle["transmission_family"] = "0AM / DQ200"
        vehicle["transmission_code"] = ""

    # Старые неоднозначные поля оставляем в файле ради обратной совместимости,
    # но новый интерфейс больше не использует их как сведения о текущем моторе.
    data["vehicle"] = vehicle

func _write_atomic(path: String, contents: String) -> bool:
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(contents)
    file.flush()
    var result := file.get_error()
    file.close()
    if result != OK:
        return false
    return DirAccess.rename_absolute(temporary, path) == OK

func _preserve_unreadable_file(path: String) -> bool:
    var damaged := FileAccess.open(path, FileAccess.READ)
    if damaged == null:
        return false
    var preserved := path + ".corrupt-" + str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec())
    var copy := FileAccess.open(preserved, FileAccess.WRITE)
    if copy == null:
        return false
    copy.store_buffer(damaged.get_buffer(damaged.get_length()))
    copy.flush()
    var copied := copy.get_error() == OK
    copy.close()
    damaged.close()
    return copied

func _save_failed() -> bool:
    persistence_failed.emit("Не удалось сохранить изменения. Проверьте свободное место и резервную копию. При повреждении файлов запись заблокирована, чтобы сохранить исходные данные.")
    return false

func save() -> bool:
    if not storage_writable or not _looks_like_vehicle_data(data):
        return _save_failed()
    var path := _data_path()
    # Never rotate corrupt data over a valid recovery copy.
    var previous := _read_vehicle_file(path)
    if not previous.is_empty():
        if FileAccess.file_exists(_backup_path()) and _read_vehicle_file(_backup_path()).is_empty():
            if not _preserve_unreadable_file(_backup_path()):
                return _save_failed()
        if not _write_atomic(_backup_path(), JSON.stringify(previous, "  ")):
            return _save_failed()
    elif FileAccess.file_exists(path) and not _preserve_unreadable_file(path):
        return _save_failed()
    if not _write_atomic(path, JSON.stringify(data, "  ")):
        return _save_failed()
    return true

func reset_all() -> void:
    storage_writable = true
    data = demo_data() if demo_mode else default_data()
    save()
    AppState.notify_all()

func _data_path() -> String:
    return DEMO_DATA_PATH if demo_mode else REAL_DATA_PATH

func _backup_path() -> String:
    return DEMO_BACKUP_PATH if demo_mode else REAL_BACKUP_PATH

func create_manual_backup() -> bool:
    if not storage_writable:
        return false
    return _write_atomic(_manual_backup_path(), JSON.stringify(data, "  "))

func has_manual_backup() -> bool:
    return FileAccess.file_exists(_manual_backup_path())

func restore_manual_backup() -> bool:
    var restored := _read_vehicle_file(_manual_backup_path())
    if restored.is_empty():
        return false
    var previous := data.duplicate(true)
    var was_writable := storage_writable
    data = restored
    _ensure_schema()
    storage_writable = true
    if not save():
        data = previous
        storage_writable = was_writable
        return false
    AppState.notify_all()
    return true


func export_json() -> String:
    return JSON.stringify(data, "  ")

func export_transfer_text() -> String:
    # Переносимая копия специально обёрнута метаданными, чтобы standalone APK
    # мог отличить её от случайного JSON в буфере обмена и показать, что
    # именно будет импортировано до замены локальных данных.
    var payload := {
        "format": TRANSFER_FORMAT,
        "exported_at": int(Time.get_unix_time_from_system()),
        "schema_version": int(data.get("schema_version", SCHEMA_VERSION)),
        "vehicle_name": str(data.get("vehicle", {}).get("nickname", "Моя машина")),
        "vehicle_vin": str(data.get("vehicle", {}).get("vin", "")),
        "data": data
    }
    return JSON.stringify(payload)

func inspect_transfer_text(raw: String) -> Dictionary:
    var parsed = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var wrapper: Dictionary = parsed
    var imported: Dictionary = {}
    var format_name := str(wrapper.get("format", ""))
    var wrapped_data = wrapper.get("data", null)
    if format_name == TRANSFER_FORMAT and typeof(wrapped_data) == TYPE_DICTIONARY:
        imported = wrapped_data
    else:
        # Совместимость с резервными копиями из 0.6/0.7, где в буфер
        # копировался сам словарь данных без внешней обёртки.
        imported = wrapper
    if not _looks_like_vehicle_data(imported):
        return {}
    var vehicle: Dictionary = imported.get("vehicle", {})
    var mileage := 0
    var records: Array = imported.get("mileage_records", [])
    for value in records:
        if typeof(value) == TYPE_DICTIONARY:
            var record: Dictionary = value
            mileage = maxi(mileage, int(record.get("mileage", 0)))
    return {
        "valid": true,
        "format": format_name if format_name != "" else "legacy",
        "vehicle_name": str(vehicle.get("nickname", vehicle.get("model", "Автомобиль"))),
        "vin": str(vehicle.get("vin", "")),
        "mileage": mileage,
        "events": imported.get("service_events", []).size(),
        "schema_version": int(imported.get("schema_version", 1))
    }

func import_transfer_text(raw: String) -> bool:
    var parsed = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    var wrapper: Dictionary = parsed
    var imported: Dictionary = {}
    var wrapped_data = wrapper.get("data", null)
    if str(wrapper.get("format", "")) == TRANSFER_FORMAT and typeof(wrapped_data) == TYPE_DICTIONARY:
        var wrapped_dict: Dictionary = wrapped_data
        imported = wrapped_dict.duplicate(true)
    else:
        imported = wrapper.duplicate(true)
    return _import_vehicle_data(imported, true)

func import_json(raw: String) -> bool:
    # Оставляем старое API для совместимости внутренних вызовов.
    return import_transfer_text(raw)

func _import_vehicle_data(imported: Dictionary, make_backup: bool) -> bool:
    if not _looks_like_vehicle_data(imported):
        return false
    if make_backup and storage_writable and not create_manual_backup():
        return false
    var previous := data.duplicate(true)
    var was_writable := storage_writable
    storage_writable = true
    data = imported.duplicate(true)
    _ensure_schema()
    var info: Dictionary = data.get("install_info", {})
    info["last_transfer_import_at"] = int(Time.get_unix_time_from_system())
    data["install_info"] = info
    var ok := save()
    if ok:
        AppState.notify_all()
    else:
        data = previous
        storage_writable = was_writable
    return ok

func _looks_like_vehicle_data(value: Dictionary) -> bool:
    if not value.get("vehicle") is Dictionary:
        return false
    for key in ["mileage_records", "service_events", "maintenance_rules", "scheduled_notification_ids", "saved_faults"]:
        if value.has(key):
            if not value[key] is Array:
                return false
        elif key in ["mileage_records", "service_events"]:
            return false
    for key in ["reminder_snoozes", "notification_settings", "notification_runtime", "install_info", "active_repair_session"]:
        if value.has(key) and not value[key] is Dictionary:
            return false
    for key in ["mileage_records", "service_events", "maintenance_rules", "saved_faults"]:
        for record in value.get(key, []):
            if not record is Dictionary:
                return false
    return true

func _manual_backup_path() -> String:
    return DEMO_MANUAL_BACKUP_PATH if demo_mode else REAL_MANUAL_BACKUP_PATH
