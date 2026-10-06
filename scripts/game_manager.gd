extends Node3D

const ACT_TWO: PackedScene = preload("res://scenes/levels/act_two.tscn")
const SAVE_PATH := "user://continue.cfg"
const AUTOSAVE_INTERVAL := 5.0

@onready var player: CharacterBody3D = $Player
@onready var level_container: Node3D = $LevelContainer
@onready var objective_label: Label = $HUD/Objective
@onready var status_label: Label = $HUD/Status
@onready var health_label: Label = $HUD/Health
@onready var mobile_controls: Control = $HUD/MobileControls
@onready var start_menu: Control = $HUD/StartMenu

var active_level: Node3D
var changing_level: bool = false
var autosave_timer: float = AUTOSAVE_INTERVAL


func _ready() -> void:
	add_to_group("game_manager")
	mobile_controls.visible = false
	mobile_controls.connect("movement_changed", Callable(player, "set_mobile_movement_input"))
	mobile_controls.connect("look_changed", Callable(player, "apply_mobile_look"))
	mobile_controls.connect("jump_requested", Callable(player, "request_mobile_jump"))
	mobile_controls.connect("sprint_changed", Callable(player, "set_mobile_sprint_pressed"))
	mobile_controls.connect("flashlight_requested", Callable(player, "toggle_flashlight"))
	mobile_controls.connect("attack_requested", Callable(player, "request_mobile_attack"))
	start_menu.connect("new_game_requested", Callable(self, "_start_new_game"))
	start_menu.connect("continue_requested", Callable(self, "_continue_game"))
	start_menu.connect("options_changed", Callable(self, "_apply_settings"))
	start_menu.connect("weapon_selected", Callable(player, "select_weapon"))
	player.select_weapon(start_menu.selected_weapon_id)
	player.mouse_sensitivity = start_menu.camera_sensitivity
	player.visible = false
	player.set_physics_process(false)
	level_container.visible = false
	objective_label.visible = false
	status_label.visible = false
	health_label.visible = false
	start_menu.set_continue_available(FileAccess.file_exists(SAVE_PATH))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if active_level == null or not player.visible:
		return
	autosave_timer -= delta
	if autosave_timer <= 0.0:
		_save_progress()
		autosave_timer = AUTOSAVE_INTERVAL


func _start_new_game() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	start_menu.set_continue_available(false)
	_begin_game(null)


func _continue_game() -> void:
	var save_data := ConfigFile.new()
	if save_data.load(SAVE_PATH) != OK:
		start_menu.set_continue_available(false)
		return
	_begin_game(save_data)


func _begin_game(save_data: ConfigFile) -> void:
	start_menu.visible = false
	player.visible = true
	player.set_physics_process(true)
	level_container.visible = true
	objective_label.visible = true
	status_label.visible = true
	health_label.visible = true
	mobile_controls.visible = OS.has_feature("mobile")
	if not mobile_controls.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_start_level(ACT_TWO)

	if save_data != null:
		var saved_position: Vector3 = save_data.get_value("player", "position", player.global_position)
		player.global_position = saved_position
		player.health = float(save_data.get_value("player", "health", 100.0))
		player.rotation.y = float(save_data.get_value("player", "rotation_y", 0.0))
		var camera_pivot := player.get_node_or_null("CameraPivot") as Node3D
		if camera_pivot != null:
			camera_pivot.rotation.x = float(save_data.get_value("camera", "pitch", 0.0))
			camera_pivot.rotation.y = float(save_data.get_value("camera", "yaw", 0.0))
		update_health(player.health)
	_save_progress()


func _apply_settings(volume_percent: float, sensitivity: float) -> void:
	player.mouse_sensitivity = sensitivity


func _save_progress() -> void:
	if active_level == null or not player.visible:
		return
	var save_data := ConfigFile.new()
	save_data.set_value("player", "position", player.global_position)
	save_data.set_value("player", "health", player.health)
	save_data.set_value("player", "rotation_y", player.rotation.y)
	var camera_pivot := player.get_node_or_null("CameraPivot") as Node3D
	if camera_pivot != null:
		save_data.set_value("camera", "pitch", camera_pivot.rotation.x)
		save_data.set_value("camera", "yaw", camera_pivot.rotation.y)
	save_data.save(SAVE_PATH)
	start_menu.set_continue_available(true)


func advance_to(next_level: PackedScene) -> void:
	if changing_level:
		return
	changing_level = true
	if next_level == null:
		objective_label.text = "EVACUACION COMPLETADA"
		status_label.text = "Llegaste al punto de evacuacion en la estacion del Metro."
		player.set_physics_process(false)
		_save_progress()
		return
	_start_level(next_level)


func _start_level(level_scene: PackedScene) -> void:
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()

	active_level = level_scene.instantiate() as Node3D
	level_container.add_child(active_level)
	var spawn_marker := active_level.get_node_or_null("PlayerSpawn") as Node3D
	if spawn_marker != null:
		player.global_position = spawn_marker.global_position + Vector3.UP * 0.05
		player.rotation.y = spawn_marker.global_rotation.y
	else:
		player.global_position = Vector3(0.0, 0.05, 0.0)
	player.velocity = Vector3.ZERO
	player.health = 100.0
	update_health(player.health)
	objective_label.text = str(active_level.get("act_title"))
	status_label.text = "%s | WASD mover, Shift correr, Espacio saltar, F linterna" % str(active_level.get("act_hint"))
	changing_level = false


func update_health(value: float) -> void:
	health_label.text = "SALUD: %d%%" % roundi(value)
