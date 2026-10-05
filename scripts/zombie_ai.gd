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
var navigation_ready: bool = false


func _ready() -> void:
	set_physics_process(false)
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	var animation_node := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_node != null:
		for animation_name in animation_node.get_animation_list():
			if animation_name.to_lower().contains("walk"):
				animation_node.play(animation_name)
				break
	_wait_for_navigation()


func _wait_for_navigation() -> void:
	var level := get_parent()
	var navigation_region := level.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if navigation_region == null:
		push_error("Zombie has no NavigationRegion3D in its level; enabling direct pursuit.")
		_align_to_map_surface()
		set_physics_process(true)
		return

	for _frame_index in range(180):
		await get_tree().physics_frame
		var navigation_mesh := navigation_region.navigation_mesh
		var navigation_map := navigation_region.get_navigation_map()
		if (
			navigation_mesh != null
			and navigation_mesh.get_polygon_count() > 0
			and navigation_map.is_valid()
			and NavigationServer3D.map_get_iteration_id(navigation_map) > 0
		):
			navigation_ready = true
			_align_to_map_surface()
			set_physics_process(true)
			return

	push_warning("Navigation did not synchronize in time; enabling direct zombie pursuit.")
	_align_to_map_surface()
	set_physics_process(true)


func _align_to_map_surface() -> void:
	var original_position := global_position
	var space_state := get_world_3d().direct_space_state
	for radius in range(5):
		for offset_x in range(-radius, radius + 1):
			for offset_z in range(-radius, radius + 1):
				if maxi(absi(offset_x), absi(offset_z)) != radius:
					continue
				var sample_position := original_position + Vector3(offset_x, 0.0, offset_z)
				var ray := PhysicsRayQueryParameters3D.create(
					sample_position + Vector3.UP * 200.0,
					sample_position + Vector3.DOWN * 200.0,
					1
				)
				var surface_hit := space_state.intersect_ray(ray)
				if surface_hit.is_empty():
					continue
				var surface_normal: Vector3 = surface_hit["normal"]
				if surface_normal.y < 0.75:
					continue
				var surface_position: Vector3 = surface_hit["position"]
				global_position = Vector3(
					sample_position.x,
					surface_position.y + 0.05,
					sample_position.z
				)
				return

	push_warning("No walkable static map surface was found below zombie: %s" % get_path())


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

	if distance <= attack_range:
		_move_with_avoidance(Vector3.ZERO)
		if attack_timer <= 0.0:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
			attack_timer = attack_cooldown
	else:
		var desired_velocity: Vector3
		if navigation_ready:
			if repath_timer <= 0.0:
				navigation_agent.target_position = target.global_position
				repath_timer = repath_interval
			var next_path_position := navigation_agent.get_next_path_position()
			var current_path := navigation_agent.get_current_navigation_path()
			if current_path.size() > 1 and navigation_agent.is_target_reachable():
				var path_offset := next_path_position - global_position
				path_offset.y = 0.0
				if path_offset.length_squared() > 0.01:
					desired_velocity = path_offset.normalized() * move_speed
				else:
					desired_velocity = flat_offset.normalized() * move_speed
			else:
				desired_velocity = flat_offset.normalized() * move_speed
		else:
			desired_velocity = flat_offset.normalized() * move_speed
		_move_with_avoidance(desired_velocity)


func _move_with_avoidance(desired_velocity: Vector3) -> void:
	if not navigation_ready:
		velocity.x = desired_velocity.x
		velocity.z = desired_velocity.z
		move_and_slide()
		return

	navigation_agent.velocity = desired_velocity
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func _on_velocity_computed(new_safe_velocity: Vector3) -> void:
	safe_velocity = new_safe_velocity