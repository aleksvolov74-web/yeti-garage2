class_name MobileScrollGesture
extends Node

# Own vertical swipes before a child button/editor can swallow them. The first
# touch still reaches the control; only a deliberate vertical drag cancels a tap.
var scroll: ScrollContainer
var _index := -1
var _start := Vector2.ZERO
var _offset := 0
var _claimed := false
var _fingers: Dictionary = {}
var _button: BaseButton
var _canvas: TechnicalDiagramCanvas
const DEADZONE := 10.0

static func attach(container: ScrollContainer) -> void:
	if container.has_node("MobileScrollGesture"):
		return
	var gesture := MobileScrollGesture.new()
	gesture.name = "MobileScrollGesture"
	gesture.scroll = container
	container.add_child(gesture)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(scroll) or not scroll.is_visible_in_tree():
		_reset()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if not _owns_position(touch.position): return
			_fingers[touch.index] = true
			if _fingers.size() > 1:
				_index = -1
				return
			_index = touch.index
			_start = touch.position
			_offset = scroll.scroll_vertical
			_claimed = false
			_button = null
			_canvas = null
			for candidate in scroll.find_children("*", "Control", true, false):
				var control := candidate as Control
				if not control.is_visible_in_tree() or not control.get_global_rect().has_point(touch.position): continue
				if control is BaseButton: _button = control as BaseButton
				if control is TechnicalDiagramCanvas: _canvas = control as TechnicalDiagramCanvas
		else:
			_fingers.erase(touch.index)
			if touch.index == _index:
				if _claimed: get_viewport().set_input_as_handled()
				_reset()
		return
	if not event is InputEventScreenDrag: return
	var drag := event as InputEventScreenDrag
	if drag.index != _index or _fingers.size() != 1: return
	if is_instance_valid(_canvas) and _canvas.is_pan_enabled(): return
	var delta := drag.position - _start
	if not _claimed and absf(delta.y) >= DEADZONE and absf(delta.y) > absf(delta.x):
		_claimed = true
		if is_instance_valid(_button): _button.set_pressed_no_signal(false)
		if is_instance_valid(_canvas): _canvas.cancel_touch_sequence()
	if _claimed:
		var bar := scroll.get_v_scroll_bar()
		scroll.scroll_vertical = clampi(_offset - int(delta.y), 0, maxi(0, int(bar.max_value - bar.page)))
		get_viewport().set_input_as_handled()

func _owns_position(position: Vector2) -> bool:
	if not scroll.get_global_rect().has_point(position): return false
	# An embedded dialog has its own viewport; don't scroll the page behind it.
	for window in get_viewport().get_embedded_subwindows():
		if window.visible: return false
	for candidate in scroll.find_children("*", "ScrollContainer", true, false):
		var nested := candidate as ScrollContainer
		if nested.is_visible_in_tree() and nested.get_global_rect().has_point(position): return false
	return scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED

func _reset() -> void:
	_index = -1
	_claimed = false
	_button = null
	_canvas = null
