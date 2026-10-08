extends SceneTree

const TechnicalCatalog = preload("res://services/technical_catalog_service.gd")
const FaultCatalog = preload("res://services/fault_catalog_service.gd")
const PartCatalog = preload("res://services/part_catalog_service.gd")
const CatalogViewScript = preload("res://scenes/technical_catalog/technical_catalog_view.gd")

func _initialize() -> void:
	var errors: Array[String] = FaultCatalog.validate()
	var catalog: Dictionary = TechnicalCatalog.catalog()
	var sections: Array = catalog.get("sections", [])
	var counts := {"nodes":0, "images":0, "markers":0, "exploded_view":0, "assembled_view":0, "technical_illustration":0, "reference_card":0, "VERIFIED_ARCHITECTURE":0, "REFERENCE_ONLY":0}
	var marker_parts: Dictionary = {}
	_walk(sections, counts, marker_parts)
	if sections.size() != 24: errors.append("catalog sections changed: %d" % sections.size())
	if int(counts.nodes) != 90: errors.append("catalog nodes changed: %d" % int(counts.nodes))
	if int(counts.images) != 90: errors.append("catalog images changed: %d" % int(counts.images))
	if int(counts.markers) != 376: errors.append("catalog markers changed: %d" % int(counts.markers))
	if int(counts.exploded_view) != 50 or int(counts.assembled_view) != 24 or int(counts.technical_illustration) != 12 or int(counts.reference_card) != 4:
		errors.append("catalog image type totals changed")
	if int(counts.VERIFIED_ARCHITECTURE) != 57 or int(counts.REFERENCE_ONLY) != 33:
		errors.append("catalog verification totals changed")
	var vehicle := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission_family":"0AM / DQ200"}
	for part_id_value in marker_parts.keys():
		var part_id := str(part_id_value)
		if PartCatalog.get_part(part_id).is_empty():
			errors.append("marker references unknown part: " + part_id)
			continue
		var route_vehicle: Dictionary = vehicle
		var location := TechnicalCatalog.find_marker_location(part_id, route_vehicle)
		if location.is_empty():
			route_vehicle = {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"AWD", "transmission_family":"0AM / DQ200"}
			location = TechnicalCatalog.find_marker_location(part_id, route_vehicle)
		if location.is_empty():
			errors.append("marker part has no route: " + part_id)
			continue
		var node: Dictionary = location.get("node", {})
		var diagram: Dictionary = node.get("diagram", {})
		var image := str(diagram.get("image", ""))
		if image == "" or not ResourceLoader.exists(image):
			errors.append("marker route has no image: " + part_id)
		var found_marker := false
		for marker_value in diagram.get("markers", []):
			var marker: Dictionary = marker_value
			if str(marker.get("part_id", "")) == part_id: found_marker = true
		if not found_marker: errors.append("marker route selects wrong marker: " + part_id)
	var view: Variant = CatalogViewScript.new()
	view.set_vehicle_profile(vehicle)
	root.add_child(view)
	await process_frame
	var route_index := 0
	for part_id_value in marker_parts.keys():
		var part_id := str(part_id_value)
		var route_vehicle: Dictionary = vehicle
		var location := TechnicalCatalog.find_marker_location(part_id, route_vehicle)
		if location.is_empty():
			route_vehicle = {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"AWD", "transmission_family":"0AM / DQ200"}
			location = TechnicalCatalog.find_marker_location(part_id, route_vehicle)
		view.set_vehicle_profile(route_vehicle)
		view.focus_part(part_id)
		if str(view.selected_part_id) != part_id:
			errors.append("focus_part did not select marker part: " + part_id)
		var selected_canvas: Variant = view.get("_diagram")
		if selected_canvas == null or selected_canvas.texture == null:
			errors.append("focus_part did not show diagram texture: " + part_id)
		elif str(selected_canvas.selected_part_id) != part_id:
			errors.append("focus_part canvas marker selection mismatch: " + part_id)
		var expected_path: Array = location.get("path", [])
		if view.current_path.size() != expected_path.size():
			errors.append("focus_part selected wrong node path: " + part_id)
		elif not expected_path.is_empty() and str(view.current_path.back()) != str(expected_path.back().get("id", "")):
			errors.append("focus_part selected wrong node: " + part_id)
		route_index += 1
		if route_index % 8 == 0: await process_frame
	if not FaultCatalog.dtc("P9999").is_empty(): errors.append("unknown DTC unexpectedly has a description")
	var warning_count := FaultCatalog.warnings().size()
	var dtc_count := FaultCatalog.dtcs().size()
	print("Catalog validation: sections=%d nodes=%d images=%d markers=%d unique_marker_parts=%d" % [sections.size(), int(counts.nodes), int(counts.images), int(counts.markers), marker_parts.size()])
	print("Fault validation: warnings=%d warning_images=%d dtcs=%d generic_obd=%d" % [warning_count, warning_count, dtc_count, dtc_count])
	if errors.is_empty():
		print("FAULT_AND_CATALOG_VALIDATION=PASS")
		quit(0)
	for error in errors: push_error(error)
	print("FAULT_AND_CATALOG_VALIDATION=FAIL")
	quit(1)

func _walk(rows: Array, counts: Dictionary, marker_parts: Dictionary) -> void:
	for row_value in rows:
		var row: Dictionary = row_value
		counts.nodes = int(counts.nodes) + 1
		var diagram: Dictionary = row.get("diagram", {})
		if str(diagram.get("image", "")) != "":
			counts.images = int(counts.images) + 1
			var image_type := str(diagram.get("image_type", ""))
			if counts.has(image_type): counts[image_type] = int(counts[image_type]) + 1
			var verification := str(diagram.get("verification_level", ""))
			if counts.has(verification): counts[verification] = int(counts[verification]) + 1
		for marker_value in diagram.get("markers", []):
			var marker: Dictionary = marker_value
			counts.markers = int(counts.markers) + 1
			marker_parts[str(marker.get("part_id", ""))] = true
		var child_rows: Array = row.get("nodes", row.get("children", []))
		_walk(child_rows, counts, marker_parts)
