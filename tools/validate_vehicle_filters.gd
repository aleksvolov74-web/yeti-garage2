extends SceneTree

var errors: Array[String] = []
const AWD_IDS := ["haldex_coupling", "propshaft", "propshaft_center_bearing", "rear_drive_shaft_left", "rear_drive_shaft_right"]

func _initialize() -> void:
    await process_frame
    ProjectSettings.set_setting("application/testing/mobile_ui", true)
    var storage := root.get_node("Storage")
    var sample: Dictionary = storage.call("demo_data")
    sample.vehicle.drivetrain = "FWD"
    storage.set("data", sample)
    var app: Control = load("res://scenes/app/app.tscn").instantiate()
    root.add_child(app)
    await process_frame
    var results := VBoxContainer.new()
    var dialog := Window.new()
    root.add_child(results)
    root.add_child(dialog)
    for drivetrain in ["FWD", "AWD"]:
        sample.vehicle.drivetrain = drivetrain
        storage.set("data", sample)
        for query in ["haldex", "кардан", "задний привод"]:
            app.call("_render_global_search_results", results, query, dialog)
            await process_frame
            var seen := false
            for button in results.find_children("*", "Button", true, false):
                if button.text.contains("Haldex") or button.text.contains("Карданный") or button.text.contains("привод 4×4"):
                    seen = true
            if drivetrain == "FWD" and seen: errors.append("AWD global search leak: " + query)
            if drivetrain == "AWD" and not seen: errors.append("AWD search unexpectedly removed: " + query)
    var view: Control = load("res://scenes/technical_catalog/technical_catalog_view.gd").new()
    var technical = load("res://services/technical_catalog_service.gd")
    view.call("set_vehicle_profile", {"drivetrain":"FWD", "current_engine_code":"CBZB", "transmission_family":"0AM / DQ200", "year":2011})
    root.add_child(view)
    await process_frame
    var section: Dictionary = {}
    for candidate in technical.catalog().sections:
        if candidate.get("part_system", "") == "transmission" and candidate.get("requires_drivetrain", "") != "AWD":
            section = candidate
            break
    view.set("current_section_id", section.id)
    view.call("_open_section_root")
    await process_frame
    for button in view.find_children("*", "Button", true, false):
        if button.get_meta("part_id", "") in AWD_IDS: errors.append("AWD fallback list leak: " + str(button.get_meta("part_id")))
    for part_id in AWD_IDS:
        view.call("focus_part", part_id)
        await process_frame
        if view.get("selected_part_id") == part_id: errors.append("AWD direct focus leak: " + part_id)
    view.call("focus_part", "clutch_k1")
    await process_frame
    if view.get("selected_part_id") != "clutch_k1": errors.append("valid FWD part blocked")
    var app_view: Control = app.get("vehicle_3d_view")
    sample.vehicle.drivetrain = "AWD"
    storage.set("data", sample)
    app.call("_refresh_all")
    app_view.call("focus_part", "haldex_coupling")
    await process_frame
    if app_view.get("selected_part_id") != "haldex_coupling": errors.append("live AWD profile not applied")
    sample.vehicle.drivetrain = "FWD"
    storage.set("data", sample)
    app.call("_refresh_all")
    await process_frame
    if app_view.get("selected_part_id") == "haldex_coupling": errors.append("stale AWD selection after vehicle change")
    if app_view.get("_vehicle").get("drivetrain") != "FWD": errors.append("catalog profile cache not refreshed")
    var desktop: Control = load("res://scenes/vehicle_3d/vehicle_3d_view.gd").new()
    root.add_child(desktop)
    await process_frame
    desktop.call("set_vehicle_profile", {"drivetrain":"FWD"})
    desktop.call("focus_part", "haldex_coupling")
    if desktop.get("selected_part") == "haldex_coupling": errors.append("desktop AWD focus leak")
    desktop.call("set_vehicle_profile", {"drivetrain":"AWD"})
    desktop.call("focus_part", "haldex_coupling")
    if desktop.get("selected_part") != "haldex_coupling": errors.append("desktop reference removed for AWD")
    var reference_label := false
    for label in desktop.find_children("*", "Label", true, false):
        if label.text.contains("REFERENCE_ONLY"): reference_label = true
    if not reference_label: errors.append("desktop AWD reference label missing")
    desktop.call("set_vehicle_profile", {"drivetrain":"FWD"})
    if desktop.get("selected_part") == "haldex_coupling": errors.append("desktop stale AWD selection")
    for error in errors: print("VEHICLE_FILTER_FAILURE: ", error)
    print("VEHICLE_FILTER_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
    quit(0 if errors.is_empty() else 1)
