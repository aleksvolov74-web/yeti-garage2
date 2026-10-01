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
var _pan := Vector2.ZERO
var _touches: Dictionary = {}
var _pinch_distance := 0.0
var _start_position := Vector2.ZERO
var _start_pan := Vector2.ZERO
var _dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 230)

func configure(image: Texture2D, points: Array, active_part_id: String = "", show_points: bool = true) -> void:
	texture = image
	markers = points.duplicate(true)
	selected_part_id = active_part_id
	markers_visible = show_points
	_zoom = 1.0
	_pan = Vector2.ZERO
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
	queue_redraw()

func _image_rect() -> Rect2:
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
		return Rect2()
	var image_size := Vector2(texture.get_width(), texture.get_height())
	var fit := minf(size.x / image_size.x, size.y / image_size.y)
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
			var label := str(marker.get("number", ""))
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
				_dragging = false
			elif _touches.size() >= 2:
				_pinch_distance = _distance_between_touches()
				accept_event()
		else:
			if _touches.has(touch.index):
				var moved := _dragging
				if not moved:
					_pick_marker(touch.position)
				_touches.erase(touch.index)
				if _touches.size() < 2:
					_pinch_distance = 0.0
				if moved or _zoom > 1.01:
					accept_event()
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touches.size() >= 2:
			_touches[drag.index] = drag.position
			var distance := _distance_between_touches()
			if _pinch_distance > 0.0:
				_zoom = clampf(_zoom * distance / _pinch_distance, 1.0, 4.0)
				_clamp_pan()
			_pinch_distance = distance
			queue_redraw()
			accept_event()
			return
		if _zoom > 1.01:
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
			queue_redraw()
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_zoom = maxf(_zoom / 1.15, 1.0)
			_clamp_pan()
			queue_redraw()
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_start_position = mouse.position
				_start_pan = _pan
				_dragging = false
			else:
				if not _dragging:
					_pick_marker(mouse.position)
				if _dragging or _zoom > 1.01:
					accept_event()
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _zoom > 1.01:
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_start_position) > 6.0:
			_dragging = true
			_pan = _start_pan + motion.position - _start_position
			_clamp_pan()
			queue_redraw()
			accept_event()

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
	var limit := maxf(0.0, (rect.size - size) * 0.5)
	_pan.x = clampf(_pan.x, -limit.x, limit.x)
	_pan.y = clampf(_pan.y, -limit.y, limit.y)
