extends CharacterBody3D

const ANIMATION_CLIPS: Dictionary = {
	"idle": "res://assets/models/zombies/player/walking.fbx",
	"walk": "res://assets/models/zombies/player/walking.fbx",
	"run": "res://assets/models/zombies/player/walking.fbx",
	"jump": "res://assets/models/zombies/player/hit reaction.fbx",
	"armed_idle": "res://assets/models/zombies/player/rifle aiming idle.fbx",
	"armed_walk": "res://assets/models/zombies/player/rifle run.fbx",
	"armed_run": "res://assets/models/zombies/player/rifle run.fbx",
	"armed_jump": "res://assets/models/zombies/player/rifle jump.fbx",
}

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025
@export var camera_follow_speed: float = 12.0
@export var health: float = 100.0
@export_node_path("Node3D") var weapon_node_path: NodePath

@onready var camera_pivot: Node3D = $CameraPivot
@onready var flashlight: SpotLight3D = $CameraPivot/SpringArm3D/Camera3D/Flashlight
@onready var model_pivot: Node3D = $ModelPivot
@onready var character_model: Node3D = $ModelPivot/CharacterModel

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var character_animator: AnimationPlayer
var current_animation: StringName = &""
var has_weapon: bool = false
var weapon_node: Node3D
var weapon_visual_defaults: Dictionary = {}
var weapon_collision_defaults: Dictionary = {}


func _ready() -> void:
	if not weapon_node_path.is_empty():
		weapon_node = get_node_or_null(weapon_node_path) as Node3D
		if weapon_node == null:
			push_warning("weapon_node_path does not point to a Node3D: %s" % weapon_node_path)
		else:
			_cache_weapon_node_defaults()
	set_weapon_equipped(false)
	add_to_group("player")
	_configure_movement_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_character_rig()
	camera_pivot.global_position = global_position + Vector3.UP * 1.5
	_play_character_animation(&"idle")


func equip_weapon(weapon: Node3D) -> void:
	if not is_instance_valid(weapon):
		push_error("Cannot equip an invalid weapon node.")
		return
	if not is_ancestor_of(weapon):
		push_error("The weapon node must be attached under the player before equipping it.")
		return
	weapon_node = weapon
	_cache_weapon_node_defaults()
	set_weapon_equipped(true)


func unequip_weapon() -> void:
	set_weapon_equipped(false)


func set_weapon_equipped(equipped: bool) -> void:
	if equipped and not is_instance_valid(weapon_node):
		push_warning("Cannot equip a weapon because no weapon node is assigned.")
		has_weapon = false
	else:
		has_weapon = equipped

	for visual_node in weapon_visual_defaults:
		if is_instance_valid(visual_node):
			var was_visible: bool = weapon_visual_defaults[visual_node]
			visual_node.visible = has_weapon and was_visible
	for collision_node in weapon_collision_defaults:
		if is_instance_valid(collision_node):
			var was_disabled: bool = weapon_collision_defaults[collision_node]
			collision_node.set_deferred(
				"disabled",
				not has_weapon or was_disabled
			)
	current_animation = &""


func _cache_weapon_node_defaults() -> void:
	weapon_visual_defaults.clear()
	weapon_collision_defaults.clear()
	if not is_instance_valid(weapon_node):
		return

	if weapon_node is VisualInstance3D:
		weapon_visual_defaults[weapon_node] = weapon_node.visible
	if weapon_node is CollisionShape3D:
		weapon_collision_defaults[weapon_node] = weapon_node.disabled
	for node in weapon_node.find_children("*", "VisualInstance3D", true, false):
		var visual_node := node as VisualInstance3D
		weapon_visual_defaults[visual_node] = visual_node.visible
	for node in weapon_node.find_children("*", "CollisionShape3D", true, false):
		var collision_node := node as CollisionShape3D
		weapon_collision_defaults[collision_node] = collision_node.disabled


func _configure_movement_actions() -> void:
	_register_action(&"move_left", [KEY_A, KEY_LEFT])
	_register_action(&"move_right", [KEY_D, KEY_RIGHT])
	_register_action(&"move_forward", [KEY_W, KEY_UP])
	_register_action(&"move_backward", [KEY_S, KEY_DOWN])


func _register_action(action_name: StringName, physical_keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for physical_key in physical_keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = physical_key
		InputMap.action_add_event(action_name, key_event)


func _process(delta: float) -> void:
	var target_position := global_position + Vector3.UP * 1.5
	var follow_weight := 1.0 - exp(-camera_follow_speed * delta)
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, follow_weight)


func _setup_character_rig() -> void:
	character_animator = character_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if character_animator == null:
		character_animator = AnimationPlayer.new()
		character_animator.name = "AnimationPlayer"
		model_pivot.add_child(character_animator)
	character_animator.root_node = character_animator.get_path_to(character_model)
	_load_animation_clips()


func _load_animation_clips() -> void:
	var animation_library := character_animator.get_animation_library(&"")
	if animation_library == null:
		animation_library = AnimationLibrary.new()
		character_animator.add_animation_library(&"", animation_library)

	for animation_state in ANIMATION_CLIPS:
		if animation_library.has_animation(animation_state):
			continue
		var clip_scene := load(ANIMATION_CLIPS[animation_state]) as PackedScene
		if clip_scene == null:
			push_warning("Could not load animation clip: %s" % ANIMATION_CLIPS[animation_state])
			continue
		var clip_root := clip_scene.instantiate()
		var clip_player := clip_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if clip_player != null:
			var clip_names := clip_player.get_animation_list()
			if not clip_names.is_empty():
				var source_animation := clip_player.get_animation(clip_names[0])
				var copied_animation := source_animation.duplicate(true) as Animation
				if copied_animation != null:
					animation_library.add_animation(animation_state, copied_animation)
			else:
				push_warning("Animation clip contains no animations: %s" % ANIMATION_CLIPS[animation_state])
		else:
			push_warning("AnimationPlayer was not found in clip: %s" % ANIMATION_CLIPS[animation_state])
		clip_root.free()


func _play_character_animation(animation_state: StringName) -> void:
	if character_animator == null:
		return
	var selected_animation := animation_state
	if has_weapon:
		match animation_state:
			&"idle":
				selected_animation = &"armed_idle"
			&"walk":
				selected_animation = &"armed_walk"
			&"run":
				selected_animation = &"armed_run"
			&"jump":
				selected_animation = &"armed_jump"

	if current_animation == selected_animation:
		return
	if selected_animation != &"idle" and not character_animator.has_animation(selected_animation):
		selected_animation = animation_state
	if selected_animation == &"idle":
		if not character_animator.has_animation(selected_animation):
			character_animator.stop()
			current_animation = &""
			return
		current_animation = selected_animation
		character_animator.speed_scale = 1.0
		character_animator.play(selected_animation, 0.12)
		character_animator.seek(0.0, true)
		character_animator.pause()
		return
	if not character_animator.has_animation(selected_animation):
		character_animator.stop()
		current_animation = &""
		return

	current_animation = selected_animation
	character_animator.speed_scale = 1.35 if animation_state == &"run" else 1.0
	character_animator.play(selected_animation, 0.12)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x - event.relative.y * mouse_sensitivity,
			-0.75,
			0.65
		)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_F:
			flashlight.visible = not flashlight.visible
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var movement_input := Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_backward", &"move_forward")
	).limit_length()
	var camera_basis := camera_pivot.global_transform.basis
	var camera_right := camera_basis.x
	var camera_forward := -camera_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0
	var direction := camera_right.normalized() * movement_input.x
	direction += camera_forward.normalized() * movement_input.y
	direction = direction.normalized()
	var movement_speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	if not direction.is_zero_approx():
		var facing_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, facing_angle, 10.0 * delta)

	var animation_state: StringName = &"jump" if not is_on_floor() else &"idle"
	if is_on_floor() and not movement_input.is_zero_approx():
		animation_state = &"run" if Input.is_key_pressed(KEY_SHIFT) else &"walk"
	_play_character_animation(animation_state)

	move_and_slide()


func take_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	get_tree().call_group("game_manager", "update_health", health)
	if health <= 0.0:
		get_tree().reload_current_scene()