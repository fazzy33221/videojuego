extends Control

signal movement_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal jump_requested
signal sprint_changed(pressed: bool)
signal flashlight_requested
signal attack_requested

var _joystick_touch := -1
var _look_touch := -1
var _sprint_touch := -1
var _movement := Vector2.ZERO
var _joystick_origin := Vector2.ZERO

const JOYSTICK_DEADZONE := 0.12


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_touch(touch.index, touch.position)
		else:
			_end_touch(touch.index)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch:
			_update_movement(drag.position)
		elif drag.index == _look_touch:
			look_changed.emit(drag.relative)
		accept_event()


func _begin_touch(index: int, position: Vector2) -> void:
	if _joystick_touch == -1 and position.x <= size.x * 0.42:
		_joystick_touch = index
		_joystick_origin = position
		_update_movement(position)
	elif _inside_circle(position, _attack_center(), _button_radius()):
		attack_requested.emit()
	elif _inside_circle(position, _jump_center(), _button_radius()):
		jump_requested.emit()
	elif _sprint_touch == -1 and _inside_circle(position, _sprint_center(), _button_radius()):
		_sprint_touch = index
		sprint_changed.emit(true)
	elif _inside_circle(position, _flashlight_center(), _button_radius()):
		flashlight_requested.emit()
	elif _look_touch == -1 and position.x > size.x * 0.42:
		_look_touch = index


func _end_touch(index: int) -> void:
	if index == _joystick_touch:
		_joystick_touch = -1
		_movement = Vector2.ZERO
		movement_changed.emit(_movement)
		queue_redraw()
	if index == _look_touch:
		_look_touch = -1
	if index == _sprint_touch:
		_sprint_touch = -1
		sprint_changed.emit(false)


func _update_movement(position: Vector2) -> void:
	var offset := position - _joystick_center()
	var raw_movement := Vector2(offset.x, -offset.y) / _joystick_radius()
	var strength := raw_movement.length()
	if strength <= JOYSTICK_DEADZONE:
		_movement = Vector2.ZERO
	else:
		var adjusted_strength := clampf(
			(strength - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE),
			0.0,
			1.0
		)
		_movement = raw_movement.normalized() * adjusted_strength
	movement_changed.emit(_movement)
	queue_redraw()


func _inside_circle(point: Vector2, center: Vector2, radius: float) -> bool:
	return point.distance_squared_to(center) <= radius * radius


func _joystick_center() -> Vector2:
	if _joystick_touch != -1:
		return _joystick_origin
	return Vector2(size.x * 0.15, size.y * 0.78)


func _joystick_radius() -> float:
	return clampf(size.y * 0.13, 48.0, 92.0)


func _button_radius() -> float:
	return clampf(size.y * 0.075, 34.0, 56.0)


func _attack_center() -> Vector2:
	return Vector2(size.x * 0.73, size.y * 0.65)


func _jump_center() -> Vector2:
	return Vector2(size.x * 0.87, size.y * 0.65)


func _sprint_center() -> Vector2:
	return Vector2(size.x * 0.73, size.y * 0.86)


func _flashlight_center() -> Vector2:
	return Vector2(size.x * 0.90, size.y * 0.88)


func _draw() -> void:
	if not visible:
		return

	var radius := _joystick_radius()
	var knob_offset := Vector2(_movement.x, -_movement.y) * radius * 0.65 if _joystick_touch != -1 else Vector2.ZERO
	draw_circle(_joystick_center(), radius, Color(0.06, 0.08, 0.10, 0.42))
	draw_arc(_joystick_center(), radius, 0.0, TAU, 48, Color(0.85, 0.88, 0.90, 0.72), 3.0)
	draw_circle(_joystick_center() + knob_offset, radius * 0.34, Color(0.85, 0.88, 0.90, 0.68))

	_draw_button(_attack_center(), "GOLPE")
	_draw_button(_jump_center(), "SALTAR")
	_draw_button(_sprint_center(), "CORRER")
	_draw_button(_flashlight_center(), "LUZ")


func _draw_button(center: Vector2, label: String) -> void:
	var radius := _button_radius()
	draw_circle(center, radius, Color(0.06, 0.08, 0.10, 0.48))
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.85, 0.88, 0.90, 0.72), 3.0)
	var font := get_theme_default_font()
	var font_size := 16
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.35),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color.WHITE
	)
