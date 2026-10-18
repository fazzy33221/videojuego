extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	var player := game.get_node_or_null("Player")
	var controls := game.get_node_or_null("HUD/MobileControls")
	_check(failures, player != null, "No se encontró Player en la escena principal.")
	_check(failures, controls != null, "No se encontró HUD/MobileControls.")
	if player == null or controls == null:
		_finish(game, failures)
		return

	controls.visible = true
	_check(failures, controls.size.x > 0.0 and controls.size.y > 0.0, "El HUD no tiene tamaño de pantalla.")
	_check(failures, game.get_node_or_null("HUD/Objective") != null, "Falta el panel de objetivo.")
	_check(failures, game.get_node_or_null("HUD/Status") != null, "Falta el panel de ubicación.")
	_check(failures, game.get_node_or_null("HUD/Health") != null, "Falta el panel de salud.")

	# Simula un toque y arrastre hacia delante en el joystick.
	var joystick_start: Vector2 = controls._joystick_center()
	_send_touch(controls, 1, joystick_start, true)
	var forward_position := joystick_start + Vector2(0.0, -controls._joystick_radius() * 0.75)
	var movement_drag := InputEventScreenDrag.new()
	movement_drag.index = 1
	movement_drag.position = forward_position
	movement_drag.relative = forward_position - joystick_start
	controls._gui_input(movement_drag)
	_check(failures, player.mobile_movement_input.y > 0.3, "El joystick no envió movimiento hacia delante.")
	_send_touch(controls, 1, forward_position, false)
	_check(failures, player.mobile_movement_input == Vector2.ZERO, "El joystick no se detuvo al soltarlo.")

	# Correr debe mantenerse mientras se toca y desactivarse al soltar.
	_send_touch(controls, 2, controls._sprint_center(), true)
	_check(failures, player.mobile_sprint_pressed, "CORRER no activó el sprint.")
	_send_touch(controls, 2, controls._sprint_center(), false)
	_check(failures, not player.mobile_sprint_pressed, "CORRER no liberó el sprint.")

	_send_touch(controls, 3, controls._attack_center(), true)
	_check(failures, player.mobile_attack_requested, "FIST no llegó al jugador.")
	player.mobile_attack_requested = false
	_send_touch(controls, 4, controls._jump_center(), true)
	_check(failures, player.mobile_jump_requested, "SALTAR no llegó al jugador.")
	player.mobile_jump_requested = false

	var flashlight := player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D/Flashlight") as SpotLight3D
	_check(failures, flashlight != null, "No se encontró la linterna del jugador.")
	if flashlight != null:
		var was_visible := flashlight.visible
		_send_touch(controls, 5, controls._flashlight_center(), true)
		_check(failures, flashlight.visible != was_visible, "LUZ no alternó la linterna.")

	var camera_pivot := player.get_node_or_null("CameraPivot") as Node3D
	_check(failures, camera_pivot != null, "No se encontró CameraPivot.")
	if camera_pivot != null:
		var old_rotation := camera_pivot.rotation
		_send_touch(controls, 6, Vector2(controls.size.x * 0.52, controls.size.y * 0.5), true)
		var look_drag := InputEventScreenDrag.new()
		look_drag.index = 6
		look_drag.position = Vector2(controls.size.x * 0.56, controls.size.y * 0.53)
		look_drag.relative = Vector2(12.0, 9.0)
		controls._gui_input(look_drag)
		_check(failures, camera_pivot.rotation != old_rotation, "El arrastre de cámara no cambió la vista.")
		_send_touch(controls, 6, look_drag.position, false)

	controls.set_health(0.4)
	_check(failures, game.get_node("HUD/Health").text == "SALUD: 40%", "El indicador de salud no se actualizó.")
	controls.set_food(0.35)
	_check(failures, is_equal_approx(controls._food_ratio, 0.35), "El indicador de comida no se actualizó.")

	_finish(game, failures)


func _send_touch(controls: Control, touch_index: int, position: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = touch_index
	touch.position = position
	touch.pressed = pressed
	controls._gui_input(touch)


func _check(failures: Array[String], condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game: Node, failures: Array[String]) -> void:
	game.queue_free()
	if failures.is_empty():
		print("Mobile controls smoke test: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		push_error("Mobile controls smoke test: FAIL")
		quit(1)

