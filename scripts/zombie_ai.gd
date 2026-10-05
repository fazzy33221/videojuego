extends CharacterBody3D

@export var move_speed: float = 2.2
@export var detection_range: float = 28.0
@export var attack_range: float = 1.6
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.2
@export var repath_interval: float = 0.35

@onready var visual: Node3D = $Visual
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var target: CharacterBody3D
var attack_timer: float = 0.0
var repath_timer: float = 0.0
var safe_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	var animation_node := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_node != null:
		for animation_name in animation_node.get_animation_list():
			if animation_name.to_lower().contains("walk"):
				animation_node.play(animation_name)
				break


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	repath_timer = maxf(repath_timer - delta, 0.0)
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not is_instance_valid(target):
		_move_with_avoidance(Vector3.ZERO)
		return

	var offset := target.global_position - global_position
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	var distance := flat_offset.length()
	if distance > detection_range:
		_move_with_avoidance(Vector3.ZERO)
		return

	if distance > 0.05:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))

	if repath_timer <= 0.0:
		navigation_agent.target_position = target.global_position
		repath_timer = repath_interval
	var next_path_position := navigation_agent.get_next_path_position()

	if distance <= attack_range:
		_move_with_avoidance(Vector3.ZERO)
		if attack_timer <= 0.0:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
			attack_timer = attack_cooldown
	else:
		var path_offset := next_path_position - global_position
		path_offset.y = 0.0
		var desired_velocity := Vector3.ZERO
		if path_offset.length_squared() > 0.01:
			desired_velocity = path_offset.normalized() * move_speed
		_move_with_avoidance(desired_velocity)


func _move_with_avoidance(desired_velocity: Vector3) -> void:
	navigation_agent.velocity = desired_velocity
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func _on_velocity_computed(new_safe_velocity: Vector3) -> void:
	safe_velocity = new_safe_velocity