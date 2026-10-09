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
	if int(counts.VERIFIED_ARCHITECTURE) != 52 or int(counts.REFERENCE_ONLY) != 38:
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
	var dtc_rows: Array = FaultCatalog.dtcs()
	var dtc_count := dtc_rows.size()
	var generic_count := 0
	var vag_count := 0
	var mapped_count := 0
	for row_value in dtc_rows:
		var dtc_row: Dictionary = row_value
		if str(dtc_row.get("verification_status", "")) == "GENERIC_OBD": generic_count += 1
		if str(dtc_row.get("verification_status", "")) == "VAG_SPECIFIC": vag_count += 1
		if str(dtc_row.get("dashboard_warning_id", "")) != "": mapped_count += 1
	if warning_count != 18: errors.append("warning total changed: %d" % warning_count)
	if dtc_count != 41 or generic_count != 31 or vag_count != 10 or mapped_count != 36:
		errors.append("DTC counts changed: total=%d generic=%d VAG=%d warning_mapped=%d" % [dtc_count, generic_count, vag_count, mapped_count])
	for expected in [["006300", "P189C"], ["005634", "P1602"], ["18010", "P1602"], ["013131", "P334B"], ["P189C/006300", "P189C"]]:
		var result: Dictionary = FaultCatalog.dtc(str(expected[0]))
		if str(result.get("code", "")) != str(expected[1]): errors.append("VAG code lookup failed: " + str(expected[0]))
	if not FaultCatalog.dtc("012345").is_empty(): errors.append("unknown VAG numeric code fabricated")
	for query in ["P189C", "006300", "P189C/006300", " p189c / 006300 ", "P1602", "18010", "005634", "P334B", "013131"]:
		var lookup: Dictionary = FaultCatalog.dtc(query)
		var hits: Array = FaultCatalog.search(query)
		var found := false
		for hit in hits:
			if str(hit.get("kind", "")) == "dtc" and str(hit.get("id", "")) == str(lookup.get("code", "")): found = true
		if not found: errors.append("VAG global search failed: " + query)
	await _check_full_marker_sync(errors, view, vehicle)
	await _check_vag_diagnostics_ui(errors, view)

	print("Catalog validation: sections=%d nodes=%d images=%d markers=%d unique_marker_parts=%d" % [sections.size(), int(counts.nodes), int(counts.images), int(counts.markers), marker_parts.size()])
	print("Fault validation: warnings=%d warning_images=%d dtcs=%d generic_obd=%d vag_specific=%d warning_mapped=%d" % [warning_count, warning_count, dtc_count, generic_count, vag_count, mapped_count])
	if errors.is_empty():
		print("FAULT_AND_CATALOG_VALIDATION=PASS")
		quit(0)
		return
	for error in errors: push_error(error)
	print("FAULT_AND_CATALOG_VALIDATION=FAIL")
	quit(1)

func _walk(rows: Array, counts: Dictionary, marker_parts: Dictionary) -> void:
	for row_value in rows:
		var row: Dictionary = row_value
		var diagram: Dictionary = row.get("diagram", {})
		if not diagram.is_empty(): counts.nodes = int(counts.nodes) + 1
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

func _check_vag_diagnostics_ui(errors: Array[String], catalog_view: Control) -> void:
	for width in [360, 420]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, 780)
		root.add_child(viewport)
		var scroll := ScrollContainer.new()
		scroll.size = Vector2(width, 780)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		viewport.add_child(scroll)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(content)
		# Use the production diagnostics methods with a real mobile container.
		# The app stays detached so its dashboard does not alter user storage.
		var app_script: Script = load("res://scenes/app/app.gd")
		var app: Control = app_script.new()
		app.set("diagnostic_content", content)
		app.set("mobile_technical_catalog", true)
		app.set("vehicle_3d_view", catalog_view)
		var catalog_box := VBoxContainer.new()
		app.set("vehicle_3d_box", catalog_box)
		for code in ["P189C", "P189A", "P334B", "P130A", "P164B", "P1602", "P1570", "P1297", "P307A", "P1558", "P0301"]:
			app.call("_show_dtc_lookup")
			await process_frame
			var field: LineEdit = content.find_children("*", "LineEdit", true, false)[0]
			field.text = "006300" if code == "P189C" else code
			field.text_submitted.emit(field.text)
			for frame in range(4): await process_frame
			if field.has_focus(): errors.append("DTC submission did not dismiss keyboard focus")
			var texts := _ui_text(content)
			for heading in [code, "Что означает", "Возможные причины", "Что проверить сначала", "Возможные решения", "Для какого автомобиля", "Источник"]:
				if heading not in texts: errors.append("DTC UI missing %s at %dpx: %s" % [heading, width, code])
			if code != "P0301" and "VAG_SPECIFIC" not in texts: errors.append("VAG status not visible: " + code)
			var record: Dictionary = FaultCatalog.dtc(code)
			var images := content.find_children("*", "TextureRect", true, false)
			if str(record.get("dashboard_warning_id", "")) == "" and not images.is_empty(): errors.append("invented dashboard icon: " + code)
			if str(record.get("dashboard_warning_id", "")) != "" and images.is_empty(): errors.append("mapped dashboard icon missing: " + code)
			if code == "P164B" and "заглушите двигатель" not in texts: errors.append("oil pressure immediate action missing")
			if code == "P130A" and "безопасно остановитесь" not in texts: errors.append("misfire immediate action missing")
			if content.get_combined_minimum_size().x > width + 1: errors.append("DTC horizontal overflow %dpx: %s" % [width, code])
			var bar := scroll.get_v_scroll_bar()
			scroll.scroll_vertical = maxi(0, int(bar.max_value - bar.page))
			await process_frame
			if scroll.scroll_vertical <= 0: errors.append("DTC page bottom unreachable: " + code)
			for node in content.find_children("*", "Button", true, false):
				var button := node as Button
				if button.text == "Показать на схеме":
					button.pressed.emit()
					var diagram: Variant = catalog_view.get("_diagram")
					var selected: Dictionary = catalog_view.call("_current_node")
					if diagram == null or diagram.texture == null or str(selected.get("id", "")) != str(record.get("related_node_ids", [""])[0]): errors.append("DTC scheme route failed: " + code)
					if str(catalog_view.get("selected_part_id")) != "": errors.append("DTC selected an arbitrary marker: " + code)
		for unknown in ["P9999", "012345"]:
			app.call("_show_dtc_lookup")
			await process_frame
			var field: LineEdit = content.find_children("*", "LineEdit", true, false)[0]
			field.text = unknown
			field.text_submitted.emit(unknown)
			await process_frame
			if "Код отсутствует" not in _ui_text(content) or "Возможные решения" in _ui_text(content): errors.append("unknown DTC invented: " + unknown)
		app.free()
		catalog_box.free()
		viewport.queue_free()
		await process_frame
		print("VAG diagnostics mobile UI smoke executed: %dpx" % width)

func _ui_text(parent: Node) -> String:
	var texts := PackedStringArray()
	for label in parent.find_children("*", "Label", true, false): texts.append(str(label.text))
	return "\n".join(texts)

func _check_full_marker_sync(errors: Array[String], view: Control, vehicle: Dictionary) -> void:
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/technical_visual_audit.json"))
	var tested := 0
	for node_id in audit.nodes:
		var entry: Dictionary = audit.nodes[node_id]
		var profile := vehicle.duplicate(true)
		if entry.architecture_status == "NOT_APPLICABLE_FWD": profile.drivetrain = "AWD"
		view.call("set_vehicle_profile", profile)
		view.call("focus_node", node_id)
		await process_frame
		if str(view.call("_current_node").get("id", "")) != node_id:
			errors.append("full marker audit cannot open node: " + str(node_id))
			continue
		for marker in entry.markers:
			var part_id := str(marker.part_id)
			var canvas: Variant = view.get("_diagram")
			canvas.marker_selected.emit(part_id)
			await process_frame
			canvas = view.get("_diagram")
			if canvas == null or canvas.texture == null or canvas.selected_part_id != part_id or str(view.get("selected_part_id")) != part_id:
				errors.append("marker selection/image mismatch: %s #%s" % [node_id, marker.number])
			var wanted := "№%s · %s" % [TechnicalDiagramCanvas.marker_number_text(marker.number), marker.name_ru]
			if wanted not in _ui_text(view): errors.append("selected card title mismatch: " + wanted)
			var row: Button
			for candidate in view.find_children("*", "Button", true, false):
				if candidate.has_meta("part_id") and str(candidate.get_meta("part_id")) == part_id:
					row = candidate
					break
			if row == null:
				errors.append("missing part row: %s #%s" % [node_id, marker.number])
			else:
				canvas.set_selected_part("")
				row.pressed.emit()
				await process_frame
				canvas = view.get("_diagram")
				if canvas == null or canvas.selected_part_id != part_id or canvas.texture == null:
					errors.append("part row marker mismatch: %s #%s" % [node_id, marker.number])
			for point in canvas.markers:
				if float(point.x) < 0 or float(point.x) > 1 or float(point.y) < 0 or float(point.y) > 1: errors.append("marker coordinate outside 0..1")
			tested += 1
	if tested != 376: errors.append("full marker synchronization coverage: %d" % tested)
	print("All-context marker/card/row synchronization checked: %d markers / %d nodes" % [tested, audit.nodes.size()])
