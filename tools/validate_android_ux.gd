extends SceneTree

var errors: Array[String] = []
var app: Control
var width := 360
var evidence: Array = []

func _initialize() -> void:
	await process_frame
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
			await _frames(5)
			await _check_page("tab_%d" % index, pages.get_child(index) as ScrollContainer)
		pages.current_tab = 4
		for method in ["_show_warning_lights", "_show_dtc_lookup", "_show_diagnostic_scenarios"]:
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
		var catalog: Control = app.get("vehicle_3d_view")
		catalog.call("focus_node", "engine_complete")
		await _frames(6)
		await _check_page("engine_complete", pages.get_child(5) as ScrollContainer)
		catalog.call("_select_part", "cylinder_head")
		await _frames(6)
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
		if not control.is_visible_in_tree() or not (control is Button or control is Label or control is LineEdit or control is OptionButton): continue
		var child_rect := control.get_global_rect()
		if child_rect.end.x > rect.end.x + 1 or child_rect.position.x < rect.position.x - 1:
			errors.append("%dpx %s horizontal overflow: %s %s" % [width, id, control.get_class(), str(child_rect)])
	await _capture(id + "_top")
	var bar := scroll.get_v_scroll_bar()
	var maximum := maxi(0, int(bar.max_value - bar.page))
	if maximum > 0:
		var start := rect.get_center()
		await _swipe(start, start + Vector2(0, -120))
		if scroll.scroll_vertical <= 0: errors.append("%dpx %s upward swipe did not scroll" % [width,id])
		await _swipe(start, start + Vector2(0, 120))
		if scroll.scroll_vertical > 2: errors.append("%dpx %s downward swipe did not restore top" % [width,id])
		scroll.scroll_vertical = maximum
		await _frames(3)
		if abs(scroll.scroll_vertical - maximum) > 2: errors.append("%dpx %s bottom unreachable" % [width,id])
		await _capture(id + "_bottom")
	scroll.scroll_vertical = 0

func _swipe(start: Vector2, finish: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0; press.pressed = true; press.position = start
	root.push_input(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 0; drag.position = finish; drag.relative = finish-start
	root.push_input(drag)
	await process_frame
	press.pressed = false; press.position = finish
	root.push_input(press)
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
