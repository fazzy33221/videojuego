extends Control

signal movement_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal jump_requested
signal sprint_changed(pressed: bool)
signal flashlight_requested
signal attack_requested

const JOYSTICK_DEADZONE := 0.12
const DEFAULT_LOCATION := "Barrio del Mercado"
const DEFAULT_EXITS := "Centro Antiguo, ruta de evacuación"

@export var run_verification_on_start := false

var _joystick_touch := -1
var _look_touch := -1
var _sprint_touch := -1
var _movement := Vector2.ZERO
var _joystick_origin := Vector2.ZERO
var _sprint_pressed := false
var _health_ratio := 1.0
var _food_ratio := 1.0
var _location_name := DEFAULT_LOCATION
var _exits_list := DEFAULT_EXITS
var _verification_running := false
var _verification_logs: Array[String] = []

@onready var _objective_label: Label = get_parent().get_node_or_null("Objective") as Label
@onready var _location_label: Label = get_parent().get_node_or_null("Status") as Label
@onready var _health_label: Label = get_parent().get_node_or_null("Health") as Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh_hud()
	queue_redraw()
	if run_verification_on_start:
		call_deferred("verify_ui_and_controls")


func _process(_delta: float) -> void:
	if not visible:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var player_health = player.get("health")
		if player_health != null:
			set_health(float(player_health) / 100.0)
	_refresh_hud()


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
	elif _inside_circle(position, _attack_center(), _attack_radius()):
		_log_action("Attack!")
		attack_requested.emit()
	elif _inside_circle(position, _jump_center(), _button_radius()):
		_log_action("Jump!")
		jump_requested.emit()
	elif _sprint_touch == -1 and _inside_circle(position, _sprint_center(), _button_radius()):
		_sprint_touch = index
		_set_sprint(true)
	elif _inside_circle(position, _flashlight_center(), _button_radius()):
		_log_action("Light Toggled!")
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
		_set_sprint(false)


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
	return clampf(size.y * 0.062, 28.0, 46.0)


func _attack_radius() -> float:
	return clampf(size.y * 0.09, 40.0, 60.0)


func _attack_center() -> Vector2:
	return Vector2(size.x * 0.72, size.y * 0.66)


func _jump_center() -> Vector2:
	return Vector2(size.x * 0.88, size.y * 0.58)


func _sprint_center() -> Vector2:
	return Vector2(size.x * 0.73, size.y * 0.86)


func _flashlight_center() -> Vector2:
	return Vector2(size.x * 0.89, size.y * 0.85)


func set_health(value: float) -> void:
	var next_ratio := clampf(value, 0.0, 1.0)
	if is_equal_approx(_health_ratio, next_ratio):
		return
	_health_ratio = next_ratio
	if is_instance_valid(_health_label):
		var label_text := "SALUD: %d%%" % roundi(_health_ratio * 100.0)
		if _health_label.text != label_text:
			_health_label.text = label_text
	queue_redraw()


func set_food(value: float) -> void:
	var next_ratio := clampf(value, 0.0, 1.0)
	if is_equal_approx(_food_ratio, next_ratio):
		return
	_food_ratio = next_ratio
	queue_redraw()


func set_location_info(location_name: String, exits_list: String) -> void:
	_location_name = location_name
	_exits_list = exits_list
	_refresh_hud()


func _refresh_hud() -> void:
	if is_instance_valid(_objective_label):
		var objective_text := "ESTACIÓN DEL METRO | BÚSQUEDA DE SALIDA"
		if _objective_label.text != objective_text:
			_objective_label.text = objective_text
	if is_instance_valid(_location_label):
		var location_text := (
			"Find the exit. Current location: %s. Available exits: %s."
			% [_location_name, _exits_list]
		)
		if _location_label.text != location_text:
			_location_label.text = location_text


func _set_sprint(pressed: bool) -> void:
	if _sprint_pressed == pressed:
		return
	_sprint_pressed = pressed
	_log_action("Running: %s" % str(pressed).to_lower())
	sprint_changed.emit(pressed)


func _log_action(message: String) -> void:
	print(message)
	if _verification_running:
		_verification_logs.append(message)


func _draw() -> void:
	if not visible:
		return

	_draw_joystick()
	_draw_button(_attack_center(), "FIST", _attack_radius(), true)
	_draw_button(_jump_center(), "SALTAR", _button_radius())
	_draw_button(_sprint_center(), "CORRER", _button_radius())
	_draw_button(_flashlight_center(), "LUZ", _button_radius())
	_draw_status_bars()


func _draw_joystick() -> void:
	var radius := _joystick_radius()
	var center := _joystick_center()
	var knob_offset := (
		Vector2(_movement.x, -_movement.y) * radius * 0.65
		if _joystick_touch != -1 else Vector2.ZERO
	)
	draw_circle(center, radius, Color(0.06, 0.08, 0.10, 0.42))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.85, 0.88, 0.90, 0.72), 3.0)
	draw_circle(center + knob_offset, radius * 0.34, Color(0.85, 0.88, 0.90, 0.68))

	var font := get_theme_default_font()
	if font == null:
		return
	var arrow_color := Color(1.0, 1.0, 1.0, 0.78)
	var arrow_size := 22
	draw_string(font, center + Vector2(-7, -radius * 0.55), "↑", HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_size, arrow_color)
	draw_string(font, center + Vector2(-7, radius * 0.82), "↓", HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_size, arrow_color)
	draw_string(font, center + Vector2(-radius * 0.76, 7), "←", HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_size, arrow_color)
	draw_string(font, center + Vector2(radius * 0.54, 7), "→", HORIZONTAL_ALIGNMENT_LEFT, -1, arrow_size, arrow_color)


func _draw_button(center: Vector2, label: String, radius: float, is_main := false) -> void:
	var fill := Color(0.18, 0.10, 0.08, 0.78) if is_main else Color(0.06, 0.08, 0.10, 0.55)
	var outline := Color(0.95, 0.73, 0.58, 0.9) if is_main else Color(0.85, 0.88, 0.90, 0.72)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 48, outline, 3.0)

	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := 18 if is_main else 14
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


func _draw_status_bars() -> void:
	var row_width := minf(clampf(size.x * 0.36, 190.0, 400.0), size.x * 0.42)
	var label_width := minf(58.0, row_width * 0.30)
	var bar_width := row_width - label_width - 42.0
	if bar_width <= 20.0:
		return

	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := 13
	var left := (size.x - row_width) * 0.5 + label_width
	var rows := [
		{"label": "VIDA", "ratio": _health_ratio, "y": size.y - 76.0, "color": Color.RED.lerp(Color.GREEN, _health_ratio)},
		{"label": "COMIDA", "ratio": _food_ratio, "y": size.y - 38.0, "color": Color.GREEN.lerp(Color.RED, 1.0 - _food_ratio)}
	]

	for row in rows:
		var y: float = row["y"]
		var ratio: float = row["ratio"]
		draw_string(font, Vector2(left - label_width, y + 5.0), row["label"], HORIZONTAL_ALIGNMENT_LEFT, label_width - 4.0, font_size, Color.WHITE)
		var bar_rect := Rect2(left, y - 7.0, bar_width, 12.0)
		draw_rect(bar_rect, Color(0.04, 0.05, 0.06, 0.78), true)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_width * ratio, bar_rect.size.y)), row["color"], true)
		draw_rect(bar_rect, Color(0.9, 0.92, 0.94, 0.8), false, 1.5)
		draw_string(font, Vector2(left + bar_width + 6.0, y + 5.0), "%d%%" % roundi(ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 40.0, font_size, Color.WHITE)


func verify_ui_and_controls() -> void:
	var failures: Array[String] = []
	var hud := get_parent()
	var player := get_tree().get_first_node_in_group("player")

	if hud == null:
		failures.append("No se encontró el CanvasLayer del HUD.")
	else:
		for node_name in ["Objective", "Status", "Health"]:
			if hud.get_node_or_null(node_name) == null:
				failures.append("Falta el elemento HUD: %s." % node_name)
	if size.x <= 0.0 or size.y <= 0.0:
		failures.append("El panel de controles no tiene tamaño de pantalla.")
	if player == null:
		failures.append("No se encontró el jugador.")
	else:
		_check_signal_connection(movement_changed, player, "set_mobile_movement_input", failures)
		_check_signal_connection(sprint_changed, player, "set_mobile_sprint_pressed", failures)
		_check_signal_connection(jump_requested, player, "request_mobile_jump", failures)
		_check_signal_connection(attack_requested, player, "request_mobile_attack", failures)
		_check_signal_connection(flashlight_requested, player, "toggle_flashlight", failures)

	if not failures.is_empty():
		print("Verification: FAIL — %s" % "; ".join(failures))
		return

	var previous_movement: Vector2 = player.mobile_movement_input
	var previous_sprint: bool = player.mobile_sprint_pressed
	var previous_jump: bool = player.mobile_jump_requested
	var previous_attack: bool = player.mobile_attack_requested
	_sprint_pressed = false
	player.set_mobile_sprint_pressed(false)
	_verification_logs.clear()
	_verification_running = true

	_log_action("Move Forward")
	movement_changed.emit(Vector2.UP)
	var moved_forward: bool = player.mobile_movement_input == Vector2.UP

	_set_sprint(true)
	var running: bool = player.mobile_sprint_pressed

	_log_action("Attack!")
	attack_requested.emit()
	var attacked: bool = player.mobile_attack_requested

	_log_action("Jump!")
	jump_requested.emit()
	var jump_requested_ok: bool = player.mobile_jump_requested

	_set_sprint(false)
	var released_run: bool = not player.mobile_sprint_pressed
	movement_changed.emit(Vector2.ZERO)

	_verification_running = false
	var expected_logs: Array[String] = [
		"Move Forward",
		"Running: true",
		"Attack!",
		"Jump!",
		"Running: false"
	]
	if _verification_logs != expected_logs:
		failures.append("Los mensajes de consola no coinciden con la secuencia esperada.")
	if not moved_forward:
		failures.append("No se recibió el movimiento hacia delante.")
	if not running or not released_run:
		failures.append("El botón CORRER no activó y liberó el sprint.")
	if not attacked:
		failures.append("El botón FIST no llegó al jugador.")
	if not jump_requested_ok:
		failures.append("El botón SALTAR no llegó al jugador.")

	# La verificación deja el jugador como estaba antes de ejecutarse.
	player.set_mobile_movement_input(previous_movement)
	player.set_mobile_sprint_pressed(previous_sprint)
	_sprint_pressed = previous_sprint
	player.mobile_jump_requested = previous_jump
	player.mobile_attack_requested = previous_attack
	_movement = previous_movement

	if failures.is_empty():
		print("Verification: PASS")
	else:
		print("Verification: FAIL — %s" % "; ".join(failures))


func _check_signal_connection(
	source: Signal,
	target: Node,
	method_name: StringName,
	failures: Array[String]
) -> void:
	if not source.is_connected(Callable(target, method_name)):
		failures.append("La señal %s no está conectada." % method_name)
