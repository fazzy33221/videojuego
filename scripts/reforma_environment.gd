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
const DISTRICT_CENTRO := "CENTRO ANTIGUO"
const DISTRICT_RESIDENTIAL := "COLONIA DEL LAGO"
const DISTRICT_COMMERCIAL := "BARRIO DEL MERCADO"
const DISTRICT_INDUSTRIAL := "ZONA INDUSTRIAL"
const DISTRICT_PARK := "PARQUE DEL MIRADOR"

var district_palettes: Dictionary = {}
var asphalt_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var curb_material: StandardMaterial3D
var median_material: StandardMaterial3D
var crosswalk_material: StandardMaterial3D
var building_material: StandardMaterial3D
var decorations: StaticBody3D


func _ready() -> void:
	asphalt_material = _create_tiled_material(Color(0.16, 0.17, 0.18), 1847, ROAD_TILE_REPEAT)
	sidewalk_material = _create_tiled_material(Color(0.43, 0.42, 0.39), 3109, SIDEWALK_TILE_REPEAT)
	curb_material = _create_tiled_material(Color(0.59, 0.57, 0.52), 3163)
	median_material = _create_tiled_material(Color(0.26, 0.34, 0.23), 4327, MEDIAN_TILE_REPEAT)
	crosswalk_material = _create_tiled_material(Color(0.84, 0.82, 0.73), 5227)
	building_material = _create_tiled_material(Color(0.48, 0.45, 0.41), 7919, WALL_TILE_REPEAT)
	decorations = StaticBody3D.new()
	decorations.name = "NonCollidingStreetDecor"
	decorations.collision_layer = 0
	decorations.collision_mask = 0
	add_child(decorations)
	district_palettes = {
		DISTRICT_CENTRO: [Color(0.47, 0.52, 0.57), Color(0.35, 0.43, 0.49), Color(0.61, 0.59, 0.52)],
		DISTRICT_RESIDENTIAL: [Color(0.62, 0.48, 0.37), Color(0.55, 0.59, 0.48), Color(0.69, 0.63, 0.51)],
		DISTRICT_COMMERCIAL: [Color(0.65, 0.39, 0.24), Color(0.55, 0.49, 0.38), Color(0.49, 0.56, 0.58)],
		DISTRICT_INDUSTRIAL: [Color(0.36, 0.40, 0.39), Color(0.47, 0.43, 0.34), Color(0.33, 0.38, 0.44)],
		DISTRICT_PARK: [Color(0.49, 0.57, 0.47), Color(0.62, 0.57, 0.43), Color(0.46, 0.55, 0.57)],
	}

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
	_create_district_signs()
	_create_street_lights()


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
	var center_x := (x_interval.x + x_interval.y) * 0.5
	var center_z := (z_interval.x + z_interval.y) * 0.5
	var district := _district_for(center_x, center_z)
	var block_root := Node3D.new()
	block_root.name = "%s_Block%02d" % [district.replace(" ", ""), block_index]
	block_root.position = Vector3(center_x, 0.0, center_z)
	add_child(block_root)

	if _build_landmark_block(block_root, district, center_x, center_z, block_width, block_depth):
		return

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
	var palette: Array = district_palettes[district]
	for parcel_index in range(parcel_offsets.size()):
		var height := _building_height_for(district, block_index, parcel_index)
		var building_width := parcel_width
		var parcel_offset: Vector2 = parcel_offsets[parcel_index]
		if is_equal_approx(center_x, 0.0):
			building_width = minf(building_width, 10.0)
			var building_side := -1.0 if parcel_index % 2 == 0 else 1.0
			parcel_offset.x = building_side * (AVENUE_WIDTH * 0.5 + building_width * 0.5)
		var building_depth := parcel_depth
		if district == DISTRICT_RESIDENTIAL:
			building_width *= [0.72, 0.84, 0.96][parcel_index % 3]
			building_depth *= [0.76, 0.88, 1.0][parcel_index % 3]
		var landmark_tower := (
			district == DISTRICT_CENTRO
			and absf(center_x) < 1.0
			and absf(center_z) < 1.0
			and parcel_index == 3
		)
		if landmark_tower:
			height = 52.0
			building_width = 11.0
			building_depth = 14.0
			parcel_offset = Vector2(AVENUE_WIDTH * 0.5 + building_width * 0.5, 0.0)
		var facade := _create_facade_material(palette[parcel_index % palette.size()])
		_add_building(
			block_root,
			"Building%02d_%d" % [block_index, parcel_index + 1],
			Vector3(parcel_offset.x, height * 0.5, parcel_offset.y),
			Vector3(building_width, height, building_depth),
			facade,
			landmark_tower
		)


func _district_for(x: float, z: float) -> String:
	if absf(x) < 70.0 and absf(z) < 70.0:
		return DISTRICT_CENTRO
	if x < -60.0 and z > 60.0:
		return DISTRICT_INDUSTRIAL
	if x > 60.0 and z < -60.0:
		return DISTRICT_PARK
	if z > 60.0:
		return DISTRICT_COMMERCIAL
	return DISTRICT_RESIDENTIAL


func _building_height_for(district: String, block_index: int, parcel_index: int) -> float:
	var variation := (block_index * 3 + parcel_index * 2) % 3
	match district:
		DISTRICT_CENTRO:
			return [24.0, 31.0, 39.0][variation]
		DISTRICT_COMMERCIAL:
			return [12.0, 16.0, 21.0][variation]
		DISTRICT_INDUSTRIAL:
			return [9.0, 12.0, 15.0][variation]
		DISTRICT_PARK:
			return [5.0, 7.0, 10.0][variation]
		_:
			return [8.0, 10.0, 13.0][variation]


func _create_facade_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material


func _build_landmark_block(
	block_root: Node3D,
	district: String,
	center_x: float,
	center_z: float,
	block_width: float,
	block_depth: float
) -> bool:
	if district == DISTRICT_INDUSTRIAL and center_x < -100.0 and center_z > 100.0:
		_add_building(
			block_root, "AbandonedWarehouse", Vector3(0, 6, 0),
			Vector3(31, 12, 25), _create_facade_material(Color(0.35, 0.39, 0.38))
		)
		_add_landmark_box(block_root, "WaterTank", Vector3(-16, 5, -14), Vector3(6, 10, 6), Color(0.42, 0.45, 0.41))
		_add_landmark_box(block_root, "ShippingContainerA", Vector3(15, 1.4, 14), Vector3(12, 2.8, 4), Color(0.48, 0.26, 0.18))
		_add_landmark_box(block_root, "ShippingContainerB", Vector3(15, 1.4, 9), Vector3(12, 2.8, 4), Color(0.22, 0.36, 0.40))
		_add_landmark_label(block_root, "BODEGAS DEL NORTE", Vector3(0, 12.5, -15), Color(0.95, 0.62, 0.34))
		return true

	if district == DISTRICT_COMMERCIAL and center_x > 100.0 and center_z > 100.0:
		_add_building(
			block_root, "MarketStore", Vector3(-11, 4, 9),
			Vector3(17, 8, 16), _create_facade_material(Color(0.65, 0.4, 0.24))
		)
		_add_landmark_box(block_root, "GasStationCanopy", Vector3(12, 5, -7), Vector3(24, 0.8, 18), Color(0.74, 0.68, 0.5))
		for pump_x in [-5.0, 3.0, 11.0]:
			_add_landmark_box(block_root, "FuelPump", Vector3(pump_x, 1.25, -7), Vector3(1.2, 2.5, 1.2), Color(0.75, 0.24, 0.16))
		_add_landmark_label(block_root, "MERCADO 24 H", Vector3(-11, 8.5, 0), Color(1.0, 0.75, 0.42))
		return true

	if district == DISTRICT_PARK and center_x > 100.0 and center_z < -100.0:
		_add_landmark_box(
			block_root, "ParkGreen", Vector3(0, 0.05, 0),
			Vector3(block_width - 8.0, 0.1, block_depth - 8.0), Color(0.24, 0.39, 0.25)
		)
		_add_landmark_box(
			block_root, "ParkCourt", Vector3(0, 0.16, 0),
			Vector3(24, 0.08, 15), Color(0.18, 0.34, 0.38)
		)
		_add_landmark_box(block_root, "ParkFountain", Vector3(0, 0.45, 0), Vector3(4, 0.9, 4), Color(0.64, 0.72, 0.73))
		for tree_index in range(8):
			var tree := MeshInstance3D.new()
			var trunk := MeshInstance3D.new()
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.22
			trunk_mesh.bottom_radius = 0.32
			trunk_mesh.height = 2.4
			trunk.mesh = trunk_mesh
			trunk.material_override = _create_facade_material(Color(0.30, 0.20, 0.13))
			trunk.position = Vector3(-18 + (tree_index % 4) * 12, 1.2, -18 + int(tree_index / 4) * 36)
			var canopy := SphereMesh.new()
			canopy.radius = 2.0
			canopy.height = 3.8
			canopy.radial_segments = 7
			tree.mesh = canopy
			tree.material_override = _create_facade_material(Color(0.20, 0.42, 0.27))
			tree.position = Vector3(-18 + (tree_index % 4) * 12, 3.0, -18 + int(tree_index / 4) * 36)
			var tree_container := block_root.get_node_or_null("ParkTrees") as StaticBody3D
			if tree_container == null:
				tree_container = StaticBody3D.new()
				tree_container.name = "ParkTrees"
				tree_container.collision_layer = 0
				tree_container.collision_mask = 0
				block_root.add_child(tree_container)
			tree_container.add_child(trunk)
			tree_container.add_child(tree)
		_add_landmark_label(block_root, "PARQUE DEL MIRADOR", Vector3(0, 8, -20), Color(0.8, 1.0, 0.75))
		return true

	if district == DISTRICT_RESIDENTIAL and center_x < -100.0 and center_z < -100.0:
		_add_building(
			block_root, "PublicSchool", Vector3(0, 4.5, 0),
			Vector3(27, 9, 22), _create_facade_material(Color(0.65, 0.57, 0.4))
		)
		_add_landmark_box(block_root, "SchoolYard", Vector3(0, 0.05, 19), Vector3(22, 0.1, 14), Color(0.33, 0.39, 0.30))
		_add_landmark_label(block_root, "ESCUELA PRIMARIA", Vector3(0, 10, -12), Color(0.9, 0.84, 0.62))
		return true

	return false


func _add_landmark_box(
	parent: Node3D,
	box_name: String,
	position: Vector3,
	size: Vector3,
	color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	parent.add_child(body)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _create_facade_material(color)
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_landmark_label(parent: Node3D, text: String, position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.025
	label.modulate = color
	label.outline_size = 8
	label.position = position
	parent.add_child(label)


func _create_district_signs() -> void:
	_add_landmark_label(self, "CENTRO ANTIGUO", Vector3(-17, 54, 0), Color(0.96, 0.83, 0.53))
	_add_landmark_label(self, "COLONIA DEL LAGO", Vector3(72, 18, -117), Color(0.85, 0.91, 0.79))
	_add_landmark_label(self, "BARRIO DEL MERCADO", Vector3(38, 18, 119), Color(1.0, 0.77, 0.45))
	_add_landmark_label(self, "ZONA INDUSTRIAL", Vector3(-123, 16, 107), Color(0.85, 0.88, 0.88))
	_add_landmark_label(self, "PARQUE DEL MIRADOR", Vector3(120, 16, -123), Color(0.8, 1.0, 0.75))


func _create_street_lights() -> void:
	for z in range(-120, 121, 40):
		for side in [-1.0, 1.0]:
			var pole := MeshInstance3D.new()
			var pole_mesh := CylinderMesh.new()
			pole_mesh.top_radius = 0.13
			pole_mesh.bottom_radius = 0.18
			pole_mesh.height = 6.0
			pole.mesh = pole_mesh
			pole.material_override = _create_facade_material(Color(0.23, 0.25, 0.26))
			pole.position = Vector3(side * 14.4, 3.0, float(z))
			decorations.add_child(pole)
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(1.0, 0.78, 0.52)
			lamp.light_energy = 0.35
			lamp.omni_range = 7.0
			lamp.shadow_enabled = false
			lamp.position = Vector3(side * 14.4, 6.0, float(z))
			decorations.add_child(lamp)


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
	dimensions: Vector3,
	material: StandardMaterial3D,
	add_roof_feature: bool = false
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
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var window := MeshInstance3D.new()
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(dimensions.x * 0.62, minf(1.8, dimensions.y * 0.32), 0.12)
	window.mesh = window_mesh
	window.material_override = _create_facade_material(Color(0.11, 0.20, 0.25))
	window.position = Vector3(0, minf(dimensions.y * 0.22, 3.0), dimensions.z * 0.5 + 0.08)
	body.add_child(window)
	if add_roof_feature:
		_add_landmark_box(body, "RoofBeacon", Vector3(0, dimensions.y * 0.5 + 2.5, 0), Vector3(1.2, 5.0, 1.2), Color(1.0, 0.55, 0.22))

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
