extends Control

var joystick_active: bool = false
var joystick_touch_id: int = -1
var joystick_center: Vector2
var joystick_radius: float = 75.0
var movement_vector: Vector2 = Vector2.ZERO

@onready var joystick_area: Control = $JoystickArea
@onready var joystick_base: ColorRect = $JoystickArea/JoystickBase
@onready var joystick_handle: ColorRect = $JoystickArea/JoystickBase/JoystickHandle
@onready var jump_btn: Button = $ActionButtons/JumpButton
@onready var sprint_btn: Button = $ActionButtons/SprintButton
@onready var flashlight_btn: Button = $ActionButtons/FlashlightButton

func _ready() -> void:
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		# In a real scenario we might hide it if not on mobile,
		# but for testing let's keep it or show it only on Android/iOS
		# visible = false
		pass

	joystick_area.gui_input.connect(_on_joystick_input)
	joystick_center = joystick_base.position + joystick_base.size / 2.0

	jump_btn.button_down.connect(_on_jump_down)
	jump_btn.button_up.connect(_on_jump_up)
	sprint_btn.toggled.connect(_on_sprint_toggled)
	flashlight_btn.pressed.connect(_on_flashlight_pressed)

	# Add custom actions if they don't exist
	for action in ["jump_mobile", "sprint_mobile", "flashlight_mobile"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not joystick_active:
			joystick_active = true
			joystick_touch_id = event.index
			joystick_base.position = event.position - joystick_base.size / 2.0
			_update_joystick(event.position)
		elif not event.pressed and event.index == joystick_touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and joystick_active and event.index == joystick_touch_id:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var center = joystick_base.position + joystick_base.size / 2.0
	var offset = touch_pos - center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius

	joystick_handle.position = (joystick_base.size / 2.0) - (joystick_handle.size / 2.0) + offset
	movement_vector = offset / joystick_radius

func _reset_joystick() -> void:
	joystick_active = false
	joystick_touch_id = -1
	joystick_base.position = joystick_center - joystick_base.size / 2.0
	joystick_handle.position = (joystick_base.size / 2.0) - (joystick_handle.size / 2.0)
	movement_vector = Vector2.ZERO

func _on_jump_down():
	var ev = InputEventAction.new()
	ev.action = "jump_mobile"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_jump_up():
	var ev = InputEventAction.new()
	ev.action = "jump_mobile"
	ev.pressed = false
	Input.parse_input_event(ev)

func _on_sprint_toggled(toggled_on: bool):
	var ev = InputEventAction.new()
	ev.action = "sprint_mobile"
	ev.pressed = toggled_on
	Input.parse_input_event(ev)

func _on_flashlight_pressed():
	var ev = InputEventAction.new()
	ev.action = "flashlight_mobile"
	ev.pressed = true
	Input.parse_input_event(ev)

	# Release it immediately
	var ev_rel = InputEventAction.new()
	ev_rel.action = "flashlight_mobile"
	ev_rel.pressed = false
	Input.parse_input_event(ev_rel)
