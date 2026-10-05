extends Node3D

const MAP_SIZE := 300.0
const MAP_HALF_SIZE := MAP_SIZE * 0.5
const AVENUE_WIDTH := 24.0
const AVENUE_SIDEWALK_WIDTH := 4.0
const AVENUE_CURB_WIDTH := 0.3
const AVENUE_LANE_WIDTH := 6.7
const AVENUE_MEDIAN_WIDTH := 2.0
const GRID_STREET_WIDTH := 12.0
const GRID_STREET_SIDEWALK_WIDTH := 2.0
const GRID_STREET_CURB_WIDTH := 0.25
const GRID_STREET_ROAD_WIDTH := 7.5
const SIDEWALK_TILE_REPEAT := Vector3(15.0, 15.0, 1.0)
const ROAD_TILE_REPEAT := Vector3(20.0, 20.0, 1.0)
const MEDIAN_TILE_REPEAT := Vector3(20.0, 20.0, 1.0)
const WALL_TILE_REPEAT := Vector3(10.0, 15.0, 1.0)
const GRID_ROAD_POSITIONS := [-90.0, -30.0, 30.0, 90.0]
const X_BLOCK_INTERVALS := [
	Vector2(-150.0, -96.0),
	Vector2(-84.0, -36.0),
	Vector2(-24.0, 24.0),
	Vector2(36.0, 84.0),
	Vector2(96.0, 150.0),
]
const Z_BLOCK_INTERVALS := [
	Vector2(-150.0, -96.0),
	Vector2(-84.0, -36.0),
	Vector2(-24.0, 24.0),
	Vector2(36.0, 84.0),
	Vector2(96.0, 150.0),
]
const BUILDING_HEIGHTS := [15.0, 18.0, 20.0]

var asphalt_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var curb_material: StandardMaterial3D
var median_material: StandardMaterial3D
var crosswalk_material: StandardMaterial3D
var building_material: StandardMaterial3D


func _ready() -> void:
	asphalt_material = _create_tiled_material(Color(0.16, 0.17, 0.18), 1847, ROAD_TILE_REPEAT)
	sidewalk_material = _create_tiled_material(Color(0.43, 0.42, 0.39), 3109, SIDEWALK_TILE_REPEAT)
	curb_material = _create_tiled_material(Color(0.59, 0.57, 0.52), 3163)
	median_material = _create_tiled_material(Color(0.26, 0.34, 0.23), 4327, MEDIAN_TILE_REPEAT)
	crosswalk_material = _create_tiled_material(Color(0.84, 0.82, 0.73), 5227)
	building_material = _create_tiled_material(Color(0.48, 0.45, 0.41), 7919, WALL_TILE_REPEAT)

	_create_surface(
		"Terrain",
		Vector2(MAP_SIZE, MAP_SIZE),
		Vector3(0.0, -0.1, 0.0),
		_create_ground_material()
	)
	_create_main_avenue()
	_create_grid_streets()
	_create_crosswalks()
	_create_urban_blocks()


func _create_main_avenue() -> void:
	var half_width := AVENUE_WIDTH * 0.5
	var sidewalk_center := half_width - AVENUE_SIDEWALK_WIDTH * 0.5
	var curb_center := half_width - AVENUE_SIDEWALK_WIDTH - AVENUE_CURB_WIDTH * 0.5
	var lane_center := AVENUE_MEDIAN_WIDTH * 0.5 + AVENUE_LANE_WIDTH * 0.5
	var road_length := Vector2(AVENUE_LANE_WIDTH, MAP_SIZE)

	_create_surface(
		"AvenueWestLane",
		road_length,
		Vector3(-lane_center, 0.0, 0.0),
		asphalt_material
	)
	_create_surface(
		"AvenueEastLane",
		road_length,
		Vector3(lane_center, 0.0, 0.0),
		asphalt_material
	)

	for side in [-1.0, 1.0]:
		_create_surface(
			"AvenueSidewalk",
			Vector2(AVENUE_SIDEWALK_WIDTH, MAP_SIZE),
			Vector3(side * sidewalk_center, 0.02, 0.0),
			sidewalk_material
		)
		_create_barrier(
			"AvenueCurb",
			Vector3(side * curb_center, 0.12, 0.0),
			Vector3(AVENUE_CURB_WIDTH, 0.24, MAP_SIZE),
			curb_material
		)

	_create_median_segments()


func _create_median_segments() -> void:
	var median_center := AVENUE_MEDIAN_WIDTH * 0.5 - AVENUE_CURB_WIDTH * 0.5
	var median_size := Vector3(AVENUE_CURB_WIDTH, 0.3, 1.0)
	var segment_start := -MAP_HALF_SIZE
	for crossing_z in GRID_ROAD_POSITIONS:
		var segment_end: float = crossing_z - GRID_STREET_WIDTH * 0.5
		_create_median_segment(segment_start, segment_end, median_center, median_size)
		segment_start = crossing_z + GRID_STREET_WIDTH * 0.5
	_create_median_segment(segment_start, MAP_HALF_SIZE, median_center, median_size)


func _create_median_segment(
	segment_start: float,
	segment_end: float,
	median_center: float,
	median_size: Vector3
) -> void:
	if segment_end <= segment_start:
		return

	var segment_length := segment_end - segment_start
	var segment_center := (segment_start + segment_end) * 0.5
	_create_surface(
		"CentralMedian",
		Vector2(AVENUE_MEDIAN_WIDTH, segment_length),
		Vector3(0.0, 0.18, segment_center),
		median_material
	)
	_create_barrier(
		"MedianCurb",
		Vector3(-median_center, 0.2, segment_center),
		median_size * Vector3(1.0, 1.0, segment_length),
		curb_material
	)
	_create_barrier(
		"MedianCurb",
		Vector3(median_center, 0.2, segment_center),
		median_size * Vector3(1.0, 1.0, segment_length),
		curb_material
	)


func _create_grid_streets() -> void:
	var side_offset := GRID_STREET_WIDTH * 0.5 - GRID_STREET_SIDEWALK_WIDTH * 0.5
	var curb_offset := GRID_STREET_WIDTH * 0.5 - GRID_STREET_SIDEWALK_WIDTH - GRID_STREET_CURB_WIDTH * 0.5

	for position in GRID_ROAD_POSITIONS:
		_create_surface(
			"CrossStreetRoad",
			Vector2(MAP_SIZE, GRID_STREET_ROAD_WIDTH),
			Vector3(0.0, 0.005, position),
			asphalt_material
		)
		for side in [-1.0, 1.0]:
			_create_surface(
				"CrossStreetSidewalk",
				Vector2(MAP_SIZE, GRID_STREET_SIDEWALK_WIDTH),
				Vector3(0.0, 0.02, position + side * side_offset),
				sidewalk_material
			)
			_create_barrier(
				"CrossStreetCurb",
				Vector3(0.0, 0.12, position + side * curb_offset),
				Vector3(MAP_SIZE, 0.24, GRID_STREET_CURB_WIDTH),
				curb_material
			)

	for position in GRID_ROAD_POSITIONS:
		_create_surface(
			"GridStreetRoad",
			Vector2(GRID_STREET_ROAD_WIDTH, MAP_SIZE),
			Vector3(position, 0.005, 0.0),
			asphalt_material
		)
		for side in [-1.0, 1.0]:
			_create_surface(
				"GridStreetSidewalk",
				Vector2(GRID_STREET_SIDEWALK_WIDTH, MAP_SIZE),
				Vector3(position + side * side_offset, 0.02, 0.0),
				sidewalk_material
			)
			_create_barrier(
				"GridStreetCurb",
				Vector3(position + side * curb_offset, 0.12, 0.0),
				Vector3(GRID_STREET_CURB_WIDTH, 0.24, MAP_SIZE),
				curb_material
			)


func _create_crosswalks() -> void:
	var stripe_count := 8
	var stripe_spacing := 0.9
	var stripe_depth := 0.45
	var lane_width := AVENUE_LANE_WIDTH

	for crossing_z in GRID_ROAD_POSITIONS:
		for stripe_index in range(stripe_count):
			var stripe_z: float = crossing_z + (stripe_index - (stripe_count - 1) * 0.5) * stripe_spacing
			for side in [-1.0, 1.0]:
				var lane_center: float = side * (AVENUE_MEDIAN_WIDTH * 0.5 + lane_width * 0.5)
				_create_surface(
					"CrosswalkStripe",
					Vector2(lane_width, stripe_depth),
					Vector3(lane_center, 0.025, stripe_z),
					crosswalk_material
				)
func _create_urban_blocks() -> void:
	var block_index := 0
	for x_interval in X_BLOCK_INTERVALS:
		for z_interval in Z_BLOCK_INTERVALS:
			_create_block(x_interval, z_interval, block_index)
			block_index += 1


func _create_block(x_interval: Vector2, z_interval: Vector2, block_index: int) -> void:
	var block_width := x_interval.y - x_interval.x
	var block_depth := z_interval.y - z_interval.x
	var block_root := Node3D.new()
	block_root.name = "Block%02d" % block_index
	block_root.position = Vector3(
		(x_interval.x + x_interval.y) * 0.5,
		0.0,
		(z_interval.x + z_interval.y) * 0.5
	)
	add_child(block_root)

	var parcel_width := block_width * 0.28
	var parcel_depth := block_depth * 0.3
	var offset_x := block_width * 0.25
	var offset_z := block_depth * 0.24
	var parcel_offsets := [
		Vector2(-offset_x, -offset_z),
		Vector2(offset_x, -offset_z),
		Vector2(-offset_x, offset_z),
		Vector2(offset_x, offset_z),
	]

	for parcel_index in range(parcel_offsets.size()):
		var height: float = BUILDING_HEIGHTS[(block_index * 3 + parcel_index * 2) % BUILDING_HEIGHTS.size()]
		var building_width := parcel_width
		var parcel_offset: Vector2 = parcel_offsets[parcel_index]
		if is_equal_approx((x_interval.x + x_interval.y) * 0.5, 0.0):
			building_width = minf(building_width, 10.0)
			var building_side := -1.0 if parcel_index % 2 == 0 else 1.0
			parcel_offset.x = building_side * (AVENUE_WIDTH * 0.5 + building_width * 0.5)
		var building_size := Vector3(building_width, height, parcel_depth)
		_add_building(
			block_root,
			"Block%02dBuilding%d" % [block_index, parcel_index + 1],
			Vector3(parcel_offset.x, height * 0.5, parcel_offset.y),
			building_size
		)


func _create_surface(
	surface_name: String,
	dimensions: Vector2,
	world_position: Vector3,
	material: StandardMaterial3D
) -> void:
	var body := StaticBody3D.new()
	body.name = surface_name
	body.position = world_position
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Surface"
	var plane := PlaneMesh.new()
	plane.size = dimensions
	mesh_instance.mesh = plane
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(dimensions.x, 0.2, dimensions.y)
	collision.shape = collision_box
	collision.position.y = -0.1
	body.add_child(collision)


func _create_barrier(
	barrier_name: String,
	world_position: Vector3,
	dimensions: Vector3,
	material: StandardMaterial3D
) -> void:
	var body := StaticBody3D.new()
	body.name = barrier_name
	body.position = world_position
	add_child(body)

	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = dimensions
	collision.shape = collision_box
	body.add_child(collision)


func _add_building(
	block_root: Node3D,
	building_name: String,
	world_position: Vector3,
	dimensions: Vector3
) -> void:
	var body := StaticBody3D.new()
	body.name = building_name
	body.position = world_position
	block_root.add_child(body)

	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BuildingMesh"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = building_material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = dimensions
	collision.shape = collision_box
	body.add_child(collision)


func _create_ground_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.23, 0.22)
	material.roughness = 1.0
	return material


func _create_tiled_material(
	base_color: Color,
	seed: int,
	uv_repeat: Vector3 = SIDEWALK_TILE_REPEAT
) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.08
	noise.fractal_octaves = 3

	var texture := NoiseTexture2D.new()
	texture.width = 64
	texture.height = 64
	texture.seamless = true
	texture.noise = noise

	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.albedo_texture = texture
	material.uv1_scale = uv_repeat
	material.roughness = 0.92
	return material
