extends SceneTree

var errors: Array[String] = []

func check(condition: bool, label: String) -> void:
    if not condition:
        errors.append(label)

func write(path: String, contents: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(contents)
    file.close()

func _initialize() -> void:
    await process_frame
    var fixture = load("res://tools/storage_test_fixture.gd")
    var store = fixture.new()
    store.directory = "user://storage-validation-" + str(Time.get_ticks_usec())
    DirAccess.make_dir_recursive_absolute(store.directory)
    store.load_or_create()
    check(store.storage_writable, "fresh store writable")
    store.data.service_events.append({"id": "retained-event", "cost": 123.45})
    check(store.save(), "save event")
    store.data.vehicle.nickname = "Second save"
    check(store.save(), "rotate backup")
    var reopened = fixture.new()
    reopened.directory = store.directory
    reopened.load_or_create()
    check(reopened.data.service_events.size() == 1, "persisted event survives fresh instance")
    write(store._data_path(), "{broken-json")
    reopened.load_or_create()
    check(reopened.data.service_events.size() == 1, "recover event from backup")
    check(FileAccess.get_file_as_string(store._data_path()) == "{broken-json", "load preserves corrupt file")
    check(reopened.save(), "save recovered data")
    var corrupt_files := 0
    for name in DirAccess.get_files_at(store.directory):
        if name.begins_with("data.json.corrupt-"):
            check(FileAccess.get_file_as_string(store.directory + "/" + name) == "{broken-json", "preserve corrupt bytes")
            corrupt_files += 1
    check(corrupt_files == 1, "one preserved corrupt original")
    check(reopened.create_manual_backup(), "manual backup")
    var before: String = reopened.export_json()
    check(not reopened.import_json('{"vehicle": [], "mileage_records": [], "service_events": []}'), "reject invalid vehicle type")
    check(not reopened.import_json('{"vehicle": {}, "mileage_records": [7], "service_events": []}'), "reject invalid record type")
    check(not reopened.import_json('{"schema_version": [], "vehicle": {}, "mileage_records": [], "service_events": []}'), "reject invalid schema type")
    check(not reopened.import_json('{"schema_version": 1.5, "vehicle": {}, "mileage_records": [], "service_events": []}'), "reject fractional schema")
    check(reopened.export_json() == before, "invalid import leaves data unchanged")
    # Force a real write failure without touching production user data.
    var good_directory: String = reopened.directory
    reopened.directory += "/missing/child"
    check(not reopened.import_json(store.export_json()), "failed import reports failure")
    check(reopened.export_json() == before, "failed import keeps memory unchanged")
    reopened.directory = good_directory
    # Backup succeeds, then a real blocked destination forces save() to fail.
    var held: String = store._data_path() + ".held"
    DirAccess.rename_absolute(store._data_path(), held)
    DirAccess.make_dir_absolute(store._data_path())
    var changed: Dictionary = store.data.duplicate(true)
    changed.vehicle.nickname = "Must roll back"
    check(not reopened.import_json(JSON.stringify(changed)), "destination failure rejects import")
    check(reopened.export_json() == before, "destination failure rolls back memory")
    DirAccess.remove_absolute(store._data_path())
    DirAccess.rename_absolute(held, store._data_path())
    write(store._data_path(), "broken-main")
    write(store._backup_path(), "broken-backup")
    reopened.load_or_create()
    check(not reopened.storage_writable, "unrecoverable data blocks writes")
    check(not reopened.save(), "blocked save fails")
    check(FileAccess.get_file_as_string(store._data_path()) == "broken-main", "blocked save preserves main")
    check(FileAccess.get_file_as_string(store._backup_path()) == "broken-backup", "blocked save preserves backup")
    check(reopened.restore_manual_backup(), "manual recovery unlocks storage")
    check(reopened.storage_writable and reopened.data.service_events.size() == 1, "manual recovery retains event")
    write(store._data_path(), "broken-main")
    write(store._backup_path(), "broken-backup")
    reopened.load_or_create()
    check(reopened.import_json(store.export_json()), "valid transfer recovers blocked storage")
    check(reopened.storage_writable and reopened.data.service_events.size() == 1, "transfer recovery retains event")
    check(reopened.save(), "post-recovery save preserves damaged backup before rotation")
    var preserved_backup := false
    for name in DirAccess.get_files_at(store.directory):
        if name.begins_with("backup.json.corrupt-"):
            preserved_backup = FileAccess.get_file_as_string(store.directory + "/" + name) == "broken-backup"
    check(preserved_backup, "damaged backup bytes preserved")
    # These are disposable test fixtures only.
    for name in DirAccess.get_files_at(store.directory):
        DirAccess.remove_absolute(store.directory + "/" + name)
    DirAccess.remove_absolute(store.directory)
    store.free()
    reopened.free()
    for error in errors:
        print("STORAGE_VALIDATION_FAILURE: " + error)
    print("STORAGE_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
    quit(0 if errors.is_empty() else 1)
