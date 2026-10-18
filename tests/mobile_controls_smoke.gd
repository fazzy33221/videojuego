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
	# Define una ventana horizontal típica para que el modo headless use hitboxes móviles reales.
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	controls.position = Vector2.ZERO
	controls.size = Vector2(1280.0, 720.0)
	_check(failures, controls.size.x > 0.0 and controls.size.y > 0.0, "El HUD no tiene tamaño de pantalla.")
	_check(failures, game.get_node_or_null("HUD/Objective") != null, "Falta el panel de objetivo.")
	_check(failures, game.get_node_or_null("HUD/Status") != null, "Falta el panel de ubicación.")
	_check(failures, game.get_node_or_null("HUD/Health") != null, "Falta el panel de salud.")

	# Llama a la misma lógica de gestos que recibe _gui_input, con puntos
	# calculados desde los hitboxes del HUD para evitar depender del viewport.
	var joystick_start: Vector2 = controls._joystick_center()
	controls._begin_touch(1, joystick_start)
	var forward_position := joystick_start + Vector2(0.0, -controls._joystick_radius() * 0.75)
	controls._update_movement(forward_position)
	_check(failures, player.mobile_movement_input.y > 0.3, "El joystick no envió movimiento hacia delante.")
	controls._end_touch(1)
	_check(failures, player.mobile_movement_input == Vector2.ZERO, "El joystick no se detuvo al soltarlo.")

	# Correr debe mantenerse mientras se toca y desactivarse al soltar.
	controls._begin_touch(2, controls._sprint_center())
	_check(failures, player.mobile_sprint_pressed, "CORRER no activó el sprint.")
	controls._end_touch(2)
	_check(failures, not player.mobile_sprint_pressed, "CORRER no liberó el sprint.")

	controls._begin_touch(3, controls._attack_center())
	_check(failures, player.mobile_attack_requested, "FIST no llegó al jugador.")
	player.mobile_attack_requested = false
	controls._begin_touch(4, controls._jump_center())
	_check(failures, player.mobile_jump_requested, "SALTAR no llegó al jugador.")
	player.mobile_jump_requested = false

	var flashlight := player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D/Flashlight") as SpotLight3D
	_check(failures, flashlight != null, "No se encontró la linterna del jugador.")
	if flashlight != null:
		var was_visible := flashlight.visible
		controls._begin_touch(5, controls._flashlight_center())
		_check(failures, flashlight.visible != was_visible, "LUZ no alternó la linterna.")

	var camera_pivot := player.get_node_or_null("CameraPivot") as Node3D
	_check(failures, camera_pivot != null, "No se encontró CameraPivot.")
	if camera_pivot != null:
		var old_rotation := camera_pivot.rotation
		controls._begin_touch(6, Vector2(controls.size.x * 0.52, controls.size.y * 0.5))
		controls.look_changed.emit(Vector2(12.0, 9.0))
		_check(failures, camera_pivot.rotation != old_rotation, "El arrastre de cámara no cambió la vista.")
		controls._end_touch(6)

	controls.set_health(0.4)
	_check(failures, game.get_node("HUD/Health").text == "SALUD: 40%", "El indicador de salud no se actualizó.")
	controls.set_food(0.35)
	_check(failures, is_equal_approx(controls._food_ratio, 0.35), "El indicador de comida no se actualizó.")

	_finish(game, failures)


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
