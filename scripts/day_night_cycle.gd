extends Node
## Smooth, deterministic day/night lighting for the city level.

@export var cycle_duration_seconds: float = 720.0
@export_range(0.0, 1.0, 0.001) var initial_time_of_day: float = 0.36
@export_node_path("DirectionalLight3D") var sun_path: NodePath = NodePath("../Daylight")
@export_node_path("WorldEnvironment") var world_environment_path: NodePath = NodePath("../WorldEnvironment")

var time_of_day: float = 0.0
var sun: DirectionalLight3D
var world_environment: WorldEnvironment


func _ready() -> void:
	time_of_day = initial_time_of_day
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	if sun == null or world_environment == null:
		push_error("Day/night cycle needs a sun and a WorldEnvironment.")
		set_process(false)
		return
	_update_lighting()


func _process(delta: float) -> void:
	if cycle_duration_seconds <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta / cycle_duration_seconds, 1.0)
	_update_lighting()


func _update_lighting() -> void:
	var sun_height := sin(time_of_day * TAU - PI * 0.5)
	var daylight := smoothstep(-0.16, 0.22, sun_height)
	sun.rotation_degrees = Vector3(-65.0 * sun_height, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.68, 0.43).lerp(Color(1.0, 0.96, 0.84), daylight)
	sun.light_energy = lerpf(0.025, 1.35, daylight)
	sun.shadow_enabled = daylight > 0.12

	var environment := world_environment.environment
	if environment != null:
		environment.background_color = Color(0.012, 0.02, 0.055).lerp(
			Color(0.38, 0.58, 0.78), daylight
		)
		environment.ambient_light_color = Color(0.22, 0.29, 0.48).lerp(
			Color(0.96, 0.94, 0.88), daylight
		)
		environment.ambient_light_energy = lerpf(0.28, 0.85, daylight)

	for light in get_tree().get_nodes_in_group("street_lights"):
		if light is OmniLight3D:
			light.light_energy = lerpf(1.4, 0.04, daylight)
