extends Node3D

const ACT_TWO: PackedScene = preload("res://scenes/levels/act_two.tscn")

@onready var player: CharacterBody3D = $Player
@onready var level_container: Node3D = $LevelContainer
@onready var objective_label: Label = $HUD/Objective
@onready var status_label: Label = $HUD/Status
@onready var health_label: Label = $HUD/Health
@onready var mobile_controls: Control = $HUD/MobileControls

var active_level: Node3D
var changing_level: bool = false


func _ready() -> void:
	add_to_group("game_manager")
	mobile_controls.visible = OS.has_feature("mobile")
	if mobile_controls.visible:
		mobile_controls.connect("movement_changed", Callable(player, "set_mobile_movement_input"))
		mobile_controls.connect("look_changed", Callable(player, "apply_mobile_look"))
		mobile_controls.connect("jump_requested", Callable(player, "request_mobile_jump"))
		mobile_controls.connect("sprint_changed", Callable(player, "set_mobile_sprint_pressed"))
		mobile_controls.connect("flashlight_requested", Callable(player, "toggle_flashlight"))
	_start_level(ACT_TWO)


func advance_to(next_level: PackedScene) -> void:
	if changing_level:
		return
	changing_level = true
	if next_level == null:
		objective_label.text = "EVACUACION COMPLETADA"
		status_label.text = "Llegaste al punto de evacuacion en Paseo de la Reforma."
		player.set_physics_process(false)
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