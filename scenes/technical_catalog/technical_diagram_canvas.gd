class_name TechnicalDiagramCanvas
extends Control

signal marker_selected(part_id: String)

const CYAN := Color("2de7eb")
const TEXT := Color("edf8fa")

var texture: Texture2D
var markers: Array = []
var selected_part_id := ""
var markers_visible := true
var _zoom := 1.0
var _initial_zoom := 1.0
var _pan := Vector2.ZERO
var _touches: Dictionary = {}
var _pinch_distance := 0.0
var _start_position := Vector2.ZERO
var _start_pan := Vector2.ZERO
var _dragging := false
var _touch_gesture_moved := false
var _mouse_gesture_moved := false
const TOUCH_DRAG_THRESHOLD := 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	resized.connect(_frame_initial_view)
	_frame_initial_view()

func configure(image: Texture2D, points: Array, active_part_id: String = "", show_points: bool = true) -> void:
	texture = image
	markers = points.duplicate(true)
	selected_part_id = active_part_id
	markers_visible = show_points
	_zoom = 1.0
	_pan = Vector2.ZERO
	var min_x := 1.0
	var min_y := 1.0
	var max_x := 0.0
	var max_y := 0.0
	for marker_value in markers:
		var marker: Dictionary = marker_value
		var point := Vector2(float(marker.get("x", 0.5)), float(marker.get("y", 0.5)))
		min_x = minf(min_x, point.x)
		min_y = minf(min_y, point.y)
		max_x = maxf(max_x, point.x)
		max_y = maxf(max_y, point.y)
	if not markers.is_empty():
		var edge_margin := minf(minf(min_x, min_y), minf(1.0 - max_x, 1.0 - max_y))
		_zoom = 1.20 if edge_margin >= 0.10 else (1.10 if edge_margin >= 0.05 else 1.0)
	_initial_zoom = _zoom
	_update_input_routing()
	queue_redraw()

func is_pan_enabled() -> bool:
	return _zoom > _initial_zoom + 0.01

static func marker_number_text(value: Variant) -> String:
	return str(int(value))

func _frame_initial_view() -> void:
	if texture == null or size.x <= 36.0 or size.y <= 36.0 or is_pan_enabled(): return
	while _zoom > 1.001:
		var rect := _image_rect()
		var safe := true
		for marker in markers:
			var point := rect.position + Vector2(float(marker.get("x", 0.5)), float(marker.get("y", 0.5))) * rect.size
			if point.x < 18.0 or point.y < 18.0 or point.x > size.x - 18.0 or point.y > size.y - 18.0: safe = false
		if safe: break
		_zoom = maxf(1.0, _zoom - 0.01)
	_initial_zoom = _zoom
	_update_input_routing()
	queue_redraw()

func set_selected_part(part_id: String) -> void:
	selected_part_id = part_id
	queue_redraw()

func set_markers_visible(is_visible: bool) -> void:
	markers_visible = is_visible
	queue_redraw()

func reset_view() -> void:
	_zoom = 1.0
	_pan = Vector2.ZERO
	_update_input_routing()
	queue_redraw()

func get_view_state() -> Dictionary:
	return {"zoom":_zoom, "initial_zoom":_initial_zoom, "pan":_pan}

func set_view_state(state: Dictionary) -> void:
	_zoom = clampf(float(state.get("zoom", 1.0)), 1.0, 4.0)
	_initial_zoom = float(state.get("initial_zoom", _initial_zoom))
	var pan_value: Variant = state.get("pan", Vector2.ZERO)
	if pan_value is Vector2:
		_pan = pan_value
	if size.x > 0.0 and size.y > 0.0:
		_clamp_pan()
	_update_input_routing()
	queue_redraw()

func cancel_touch_sequence() -> void:
	_touches.clear()
	_pinch_distance = 0.0
	_touch_gesture_moved = false
	_dragging = false
	_update_input_routing()

func _image_rect() -> Rect2:
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
		return Rect2()
	var image_size := Vector2(texture.get_width(), texture.get_height())
	var fit := minf(maxf(1.0, size.x - 36.0) / image_size.x, maxf(1.0, size.y - 36.0) / image_size.y)
	var drawn := image_size * fit * _zoom
	var origin := (size - drawn) * 0.5 + _pan
	return Rect2(origin, drawn)

func _draw() -> void:
	if texture == null:
		return
	var rect := _image_rect()
	draw_texture_rect(texture, rect, false)
	if not markers_visible:
		return
	for marker_value in markers:
		var marker: Dictionary = marker_value
		var local := rect.position + Vector2(float(marker.get("x", 0.5)), float(marker.get("y", 0.5))) * rect.size
		if not Rect2(Vector2.ZERO, size).grow(22).has_point(local):
			continue
		var active := str(marker.get("part_id", "")) == selected_part_id
		var fill := CYAN if active else Color("0a2630")
		draw_circle(local, 16.0, fill)
		draw_arc(local, 16.0, 0.0, TAU, 32, CYAN, 2.0, true)
		var font := get_theme_default_font()
		if font != null:
			var label := marker_number_text(marker.get("number", 0))
			var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			draw_string(font, local - Vector2(label_size.x * 0.5, -4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("052027") if active else TEXT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() == 1:
				_start_position = touch.position
				_start_pan = _pan
				_touch_gesture_moved = false
				_dragging = false
				if is_pan_enabled():
					accept_event()
			elif _touches.size() >= 2:
				_touch_gesture_moved = true
				_pinch_distance = _distance_between_touches()
				_update_input_routing()
				accept_event()
		elif _touches.has(touch.index):
			var was_multi_touch := _touches.size() >= 2
			var was_zoomed := is_pan_enabled()
			if not _touch_gesture_moved and not was_multi_touch:
				_pick_marker(touch.position)
			_touches.erase(touch.index)
			if _touches.size() < 2:
				_pinch_distance = 0.0
			if _touches.size() == 1:
				var remaining_id = _touches.keys()[0]
				_start_position = Vector2(_touches[remaining_id])
				_start_pan = _pan
			if was_multi_touch or was_zoomed or _touch_gesture_moved:
				accept_event()
			if _touches.is_empty():
				_touch_gesture_moved = false
				_dragging = false
			_update_input_routing()
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.size() >= 2:
			_touch_gesture_moved = true
			_touches[drag.index] = drag.position
			var distance := _distance_between_touches()
			if _pinch_distance > 0.0:
				_zoom = clampf(_zoom * distance / _pinch_distance, 1.0, 4.0)
				_clamp_pan()
			_pinch_distance = distance
			_update_input_routing()
			queue_redraw()
			accept_event()
			return
		if not _touches.has(drag.index):
			return
		_touches[drag.index] = drag.position
		if drag.position.distance_to(_start_position) >= TOUCH_DRAG_THRESHOLD:
			_touch_gesture_moved = true
		if is_pan_enabled() and _touch_gesture_moved:
			_dragging = true
			_pan = _start_pan + drag.position - _start_position
			_clamp_pan()
			queue_redraw()
			accept_event()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_zoom = minf(_zoom * 1.15, 4.0)
			_update_input_routing()
			queue_redraw()
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_zoom = maxf(_zoom / 1.15, 1.0)
			_clamp_pan()
			_update_input_routing()
			queue_redraw()
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_start_position = mouse.position
				_start_pan = _pan
				_dragging = false
				_mouse_gesture_moved = false
				_update_input_routing()
				if is_pan_enabled():
					accept_event()
			else:
				if not _mouse_gesture_moved:
					_pick_marker(mouse.position)
				if _dragging or is_pan_enabled():
					accept_event()
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_start_position) >= TOUCH_DRAG_THRESHOLD:
			_mouse_gesture_moved = true
		if is_pan_enabled() and _mouse_gesture_moved:
			_dragging = true
			_pan = _start_pan + motion.position - _start_position
			_clamp_pan()
			queue_redraw()
			accept_event()

func _update_input_routing() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if is_pan_enabled() or _touches.size() >= 2 else Control.MOUSE_FILTER_PASS

func _distance_between_touches() -> float:
	var ids := _touches.keys()
	if ids.size() < 2:
		return 0.0
	return Vector2(_touches[ids[0]]).distance_to(Vector2(_touches[ids[1]]))

func _pick_marker(position: Vector2) -> void:
	if not markers_visible:
		return
	var rect := _image_rect()
	for marker_value in markers:
		var marker: Dictionary = marker_value
		var point := rect.position + Vector2(float(marker.get("x", 0.5)), float(marker.get("y", 0.5))) * rect.size
		if point.distance_to(position) <= 23.0:
			var part_id := str(marker.get("part_id", ""))
			if part_id != "":
				marker_selected.emit(part_id)
			accept_event()
			return

func _clamp_pan() -> void:
	var rect := _image_rect()
	var limit := Vector2(maxf(0.0, (rect.size.x - size.x) * 0.5), maxf(0.0, (rect.size.y - size.y) * 0.5))
	_pan.x = clampf(_pan.x, -limit.x, limit.x)
	_pan.y = clampf(_pan.y, -limit.y, limit.y)
