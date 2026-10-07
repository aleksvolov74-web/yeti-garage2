extends RefCounted

static func style_result_button(button: Button) -> void:
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func content_width(preferred: float, viewport_width: float) -> float:
	return maxf(1.0, minf(preferred, viewport_width - 48.0))

static func popup_size(preferred: Vector2i, viewport_size: Vector2i) -> Vector2i:
	return Vector2i(
		mini(preferred.x, maxi(1, viewport_size.x - 24)),
		mini(preferred.y, maxi(1, viewport_size.y - 48))
	)
