extends SceneTree

var errors: Array[String] = []
var app: Control
var width := 360
var evidence: Array = []

func _initialize() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://build")
	var ignore := FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	ignore.close()
	ProjectSettings.set_setting("application/testing/mobile_ui", true)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.gui_embed_subwindows = true
	# Isolated CI storage: stress long histories and saved-fault lists without
	# changing a developer's or phone user's production data.
	var storage := root.get_node("Storage")
	var sample: Dictionary = storage.call("demo_data")
	sample.vehicle.transmission = "DSG 7"
	for index in range(32):
		var event: Dictionary = sample.service_events[1].duplicate(true)
		event.id = "ux_history_%d" % index
		event.title = "Длинное название обслуживания системы управления двигателем и электрооборудования"
		event.notes = "Проверка переноса текста и доступа к нижним действиям записи."
		event.part_id = "oil_filter"
		sample.service_events.append(event)
	for index in range(16):
		sample.saved_faults.append({"id":"ux_fault_%d" % index,"date":"2026-10-08","warning_id":"abs","dtc_code":"","title":"ABS — сохранённая неисправность","note":"Записано вручную; проверка состояния системы","status":"NEW"})
	storage.set("data", sample)
	var scene: PackedScene = load("res://scenes/app/app.tscn")
	app = scene.instantiate()
	root.add_child(app)
	await _frames(8)
	for current_width in [360, 420]:
		width = current_width
		DisplayServer.window_set_size(Vector2i(width, 780))
		root.size = Vector2i(width, 780)
		await _frames(8)
		var title: Label = app.get("header_title")
		var accent: Label = app.get("header_accent")
		if title.size.y > 55 or accent.size.y > 55: errors.append("header wraps vertically at %dpx" % width)
		var pages: TabContainer = app.get("pages")
		for index in range(pages.get_tab_count()):
			pages.current_tab = index
			app.call("_update_nav_styles")
			await _frames(5)
			await _check_page("tab_%d" % index, pages.get_child(index) as ScrollContainer)
		pages.current_tab = 4
		app.call("_update_nav_styles")
		for method in ["_show_warning_lights", "_show_dtc_lookup", "_show_diagnostic_scenarios", "_show_symptom_scenarios", "_show_saved_faults"]:
			app.call(method)
			await _frames(5)
			await _check_page(method, pages.get_child(4) as ScrollContainer)
		for warning_id in ["abs", "oil_pressure", "epc", "check_engine"]:
			app.call("_show_warning_detail", warning_id)
			await _frames(5)
			await _check_page("warning_" + warning_id, pages.get_child(4) as ScrollContainer)
		app.call("_show_dtc_lookup")
		await _frames(3)
		var content: VBoxContainer = app.get("diagnostic_content")
		var field: LineEdit = content.find_children("*", "LineEdit", true, false)[0]
		field.text = "P0301"
		field.text_submitted.emit(field.text)
		await _frames(6)
		await _check_page("dtc_P0301", pages.get_child(4) as ScrollContainer)
		pages.current_tab = 5
		app.call("_update_nav_styles")
		var catalog: Control = app.get("vehicle_3d_view")
		catalog.call("focus_node", "engine_complete")
		await _frames(6)
		await _check_page("engine_complete", pages.get_child(5) as ScrollContainer)
		catalog.call("_select_part", "cylinder_head")
		await _frames(6)
		var selected_card: Control = catalog.get("_selected_part_card")
		var technical_scroll := pages.get_child(5) as ScrollContainer
		var selected_canvas: Control = catalog.get("_diagram")
		if selected_card.get_global_rect().position.y >= technical_scroll.get_global_rect().end.y: errors.append("selected part card not revealed")
		if selected_canvas.get_global_rect().intersection(technical_scroll.get_global_rect()).size.y < 90.0: errors.append("selection scrolled the diagram away")
		var image_rect: Rect2 = selected_canvas.call("_image_rect")
		var point := selected_canvas.global_position + image_rect.position + Vector2(0.54,0.20) * image_rect.size
		if not technical_scroll.get_global_rect().grow(-18).has_point(point): errors.append("selected cylinder-head marker clipped after revealing card")
		await _capture("selected_cylinder_head_revealed")
		await _check_page("selected_cylinder_head", pages.get_child(5) as ScrollContainer)
		var selectors := catalog.find_children("*", "OptionButton", true, false)
		if not selectors.is_empty():
			var selector := selectors[0] as OptionButton
			(pages.get_child(5) as ScrollContainer).scroll_vertical = 0
			await _frames(3)
			selector.show_popup()
			await _frames(5)
			var popup := selector.get_popup()
			if popup.position.x < 0 or popup.position.x + popup.size.x > width: errors.append("scheme popup overflow at %d" % width)
			await _capture("scheme_popup")
			popup.hide()
		pages.current_tab = 4
		app.call("_update_nav_styles")
		app.call("_show_dtc_lookup")
		await _frames(3)
		root.size = Vector2i(width, 480)
		DisplayServer.window_set_size(Vector2i(width, 480))
		await _frames(6)
		await _check_page("reduced_height_keyboard_geometry", pages.get_child(4) as ScrollContainer)
		root.size = Vector2i(width, 780)
		DisplayServer.window_set_size(Vector2i(width, 780))
		await _frames(6)
		app.call("_open_manual_hub")
		await _frames(6)
		await _capture("manual_hub")
		for window in root.get_embedded_subwindows():
			if window.visible:
				if window.size.x > width: errors.append("manual dialog width exceeds %d" % width)
				window.hide()
		await _frames(3)
		for method in ["_open_more_menu", "_open_vehicle_dialog", "_open_global_search"]:
			app.call(method)
			await _frames(6)
			await _check_dialog(method)
		app.call("_open_official_manual", 22)
		await _frames(10)
		await _check_dialog("official_manual_page_22")
		app.call("_show_part_history", "oil_filter", "Масляный фильтр")
		await _frames(6)
		await _check_dialog("part_history_long")
		app.call("_open_maintenance_rule_dialog", sample.maintenance_rules[0])
		await _frames(6)
		await _check_dialog("maintenance_settings")
		pages.current_tab = 5
		app.call("_update_nav_styles")
		catalog.call("focus_node", "engine_complete")
		await _frames(5)
		var original_canvas: Variant = catalog.get("_diagram")
		catalog.call("_show_fullscreen_diagram")
		await _frames(6)
		if original_canvas != catalog.get("_diagram"): errors.append("fullscreen duplicated diagram model")
		original_canvas.marker_selected.emit("cylinder_head")
		await _frames(5)
		await _capture("fullscreen_selected_cylinder_head")
		for window in root.get_embedded_subwindows():
			if window.visible: window.hide()
		await _frames(5)
		if catalog.get("_diagram") != original_canvas or str(catalog.get("selected_part_id")) != "cylinder_head": errors.append("fullscreen state not restored")
		await _check_cbzb_batch(catalog, pages.get_child(5) as ScrollContainer)
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/technical_visual_audit.json"))
	var total := 0
	for entry in audit.nodes.values():
		var seen := {}
		for marker in entry.markers:
			var text := TechnicalDiagramCanvas.marker_number_text(marker.number)
			if text.contains(".") or not text.is_valid_int(): errors.append("fractional marker number: " + text)
			if seen.has(text): errors.append("duplicate marker number")
			seen[text] = true
			total += 1
	if total != 376: errors.append("marker numbering coverage changed")
	DirAccess.make_dir_recursive_absolute("res://build/ux")
	var result := {"viewports": ["360x780", "420x780"], "marker_numbers_checked":total, "captures":evidence, "errors":errors, "physical_android_test":"NOT_RUN_NO_ADB_DEVICE", "real_keyboard_test":"NOT_RUN", "reduced_height_geometry":"CHECKED_480PX"}
	var file := FileAccess.open("res://build/ux/result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	for error in errors: push_error(error)
	print("ANDROID_UX_DESKTOP_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
	quit(0 if errors.is_empty() else 1)

func _check_page(id: String, scroll: ScrollContainer) -> void:
	if scroll == null: errors.append("missing scroll: " + id); return
	scroll.scroll_vertical = 0
	await _frames(3)
	var rect := scroll.get_global_rect()
	for child in scroll.find_children("*", "Control", true, false):
		var control := child as Control
		if not control.is_visible_in_tree(): continue
		var child_rect := control.get_global_rect()
		if child_rect.end.x > rect.end.x + 1 or child_rect.position.x < rect.position.x - 1:
			errors.append("%dpx %s horizontal overflow: %s %s" % [width, id, control.get_class(), str(child_rect)])
	await _capture(id + "_top")
	var bar := scroll.get_v_scroll_bar()
	var maximum := maxi(0, int(bar.max_value - bar.page))
	if maximum > 0:
		var start := rect.get_center()
		await _swipe(start, start + Vector2(0, -120), scroll.get_viewport())
		if scroll.scroll_vertical <= 0: errors.append("%dpx %s upward swipe did not scroll" % [width,id])
		await _swipe(start, start + Vector2(0, 120), scroll.get_viewport())
		if scroll.scroll_vertical > 2: errors.append("%dpx %s downward swipe did not restore top" % [width,id])
		scroll.scroll_vertical = maximum
		await _frames(3)
		if abs(scroll.scroll_vertical - maximum) > 2: errors.append("%dpx %s bottom unreachable" % [width,id])
		await _capture(id + "_bottom")
	scroll.scroll_vertical = 0

func _swipe(start: Vector2, finish: Vector2, receiver: Viewport = null) -> void:
	var viewport := root if receiver == null else receiver
	var press := InputEventScreenTouch.new()
	press.index = 0; press.pressed = true; press.position = start
	viewport.push_input(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 0; drag.position = finish; drag.relative = finish-start
	viewport.push_input(drag)
	await process_frame
	press.pressed = false; press.position = finish
	viewport.push_input(press)
	await _frames(3)

func _capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := "res://build/ux/%d" % width
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder + "/" + id + ".png"
	var image := root.get_texture().get_image()
	if image == null or image.is_empty(): errors.append("empty render: " + path); return
	image.save_png(path)
	evidence.append(path)

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check_dialog(id: String) -> void:
	for window in root.get_embedded_subwindows():
		if not window.visible: continue
		if window.position.x < 0 or window.position.x + window.size.x > width or window.size.y > 780: errors.append("dialog outside viewport: " + id)
		await _capture(id)
		for candidate in window.find_children("*", "ScrollContainer", true, false):
			var scroll := candidate as ScrollContainer
			if scroll.is_visible_in_tree(): await _check_page(id + "_scroll", scroll)
		window.hide()
	await _frames(4)

func _check_cbzb_batch(catalog: Control, scroll: ScrollContainer) -> void:
	for node_id in ["engine_bottom_end", "boost_group"]:
		catalog.call("focus_node", node_id)
		await _frames(6)
		var canvas: Control = catalog.get("_diagram")
		if canvas == null or canvas.get("texture") == null:
			errors.append("batch image missing: " + node_id)
			continue
		var texture: Texture2D = canvas.get("texture")
		if texture.get_size() != Vector2(1254,1254): errors.append("batch image dimensions: " + node_id)
		await _check_page("cbzb_" + node_id, scroll)
		var points: Array = canvas.get("markers").duplicate(true)
		for marker in points:
			catalog.call("focus_node", node_id)
			await _frames(5)
			scroll.scroll_vertical = 0
			await _frames(3)
			canvas = catalog.get("_diagram")
			var rect: Rect2 = canvas.call("_image_rect")
			var location := canvas.global_position + rect.position + rect.size * Vector2(marker.x,marker.y)
			var touch := InputEventScreenTouch.new()
			touch.index = 0; touch.pressed = true; touch.position = location
			root.push_input(touch)
			await process_frame
			touch.pressed = false; root.push_input(touch)
			await _frames(5)
			canvas = catalog.get("_diagram")
			if str(catalog.get("selected_part_id")) != str(marker.part_id) or canvas.get("texture") == null:
				errors.append("batch marker touch failed: %s/%s" % [node_id,marker.part_id])
			await _capture("cbzb_%s_marker_%d" % [node_id,int(marker.number)])
			var found := false
			for button in catalog.find_children("*", "Button", true, false):
				if str(button.get_meta("part_id", "")) == str(marker.part_id):
					button.pressed.emit(); found = true; break
			await _frames(4)
			canvas = catalog.get("_diagram")
			if not found or str(canvas.get("selected_part_id")) != str(marker.part_id): errors.append("batch part row failed: " + str(marker.part_id))
			catalog.call("focus_part", str(marker.part_id))
			await _frames(4)
			canvas = catalog.get("_diagram")
			if canvas == null or canvas.get("texture") == null or str(canvas.get("selected_part_id")) != str(marker.part_id): errors.append("batch focus/search route failed: " + str(marker.part_id))
		catalog.call("focus_node", node_id)
		await _frames(5)
		scroll.scroll_vertical = 0
		await _frames(3)
		canvas = catalog.get("_diagram")
		catalog.call("_toggle_markers")
		if bool(canvas.get("markers_visible")): errors.append("batch numbers hide failed")
		catalog.call("_toggle_markers")
		if not bool(canvas.get("markers_visible")): errors.append("batch numbers restore failed")
		canvas.call("reset_view")
		var center := canvas.get_global_rect().get_center()
		await _send_mobile_pinch(root, center, 35.0)
		if float(canvas.get("_zoom")) <= 1.0: errors.append("batch pinch failed: " + node_id)
		canvas.set("_zoom", 2.0)
		var prior: Vector2 = canvas.get("_pan")
		await _swipe(center,center+Vector2(-55,0),root)
		if Vector2(canvas.get("_pan")).is_equal_approx(prior): errors.append("batch pan failed: " + node_id)
		canvas.call("reset_view")
		if float(canvas.get("_zoom")) != 1.0 or not Vector2(canvas.get("_pan")).is_zero_approx(): errors.append("batch fit failed: " + node_id)
		catalog.call("_reset_catalog")
		await _frames(3)

func _send_mobile_pinch(viewport: Viewport, center: Vector2, radius: float) -> void:
	var first := InputEventScreenTouch.new()
	first.device = 0
	first.index = 0
	first.pressed = true
	first.position = center + Vector2(-radius, 0)
	viewport.push_input(first)
	await process_frame
	var second := InputEventScreenTouch.new()
	second.device = 0
	second.index = 1
	second.pressed = true
	second.position = center + Vector2(radius, 0)
	viewport.push_input(second)
	await process_frame
	var pinch := InputEventScreenDrag.new()
	pinch.device = 0
	pinch.index = 1
	pinch.position = center + Vector2(radius * 2.0, 0)
	pinch.relative = Vector2(radius, 0)
	viewport.push_input(pinch)
	await process_frame
	second.pressed = false
	viewport.push_input(second)
	await process_frame
	first.pressed = false
	viewport.push_input(first)
	await _frames(2)
