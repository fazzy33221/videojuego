extends Node3D

const CITY_EXTENT := 64.0

var asphalt: StandardMaterial3D
var concrete: StandardMaterial3D
var road_line: StandardMaterial3D
var glass: StandardMaterial3D
var metal: StandardMaterial3D
var foliage: StandardMaterial3D
var bark: StandardMaterial3D
var lamp_glow: StandardMaterial3D
var building_colors: Array[Color] = [
	Color(0.37, 0.39, 0.42),
	Color(0.48, 0.40, 0.34),
	Color(0.31, 0.39, 0.40),
	Color(0.49, 0.47, 0.41),
	Color(0.39, 0.35, 0.34),
]


func _ready() -> void:
	_create_materials()
	_build_ground_and_roads()
	_build_buildings()
	_build_street_lights()
	_build_trees()
	_build_cars_and_barriers()


func _create_materials() -> void:
	asphalt = _make_material(Color(0.105, 0.12, 0.14), 0.95)
	concrete = _make_material(Color(0.39, 0.41, 0.42), 0.9)
	road_line = _make_material(Color(0.87, 0.77, 0.48), 0.72, Color(0.18, 0.11, 0.025))
	glass = _make_material(Color(0.11, 0.23, 0.29), 0.26)
	metal = _make_material(Color(0.16, 0.18, 0.19), 0.48)
	foliage = _make_material(Color(0.13, 0.28, 0.19), 0.92)
	bark = _make_material(Color(0.23, 0.16, 0.11), 0.95)
	lamp_glow = _make_material(Color(1.0, 0.76, 0.38), 0.3, Color(1.0, 0.46, 0.1))
	var store_material := _make_material(Color(0.42, 0.25, 0.16), 0.82)
	building_colors.append(store_material.albedo_color)


func _make_material(color: Color, roughness: float, glow: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow != Color.BLACK:
		material.emission_enabled = true
		material.emission = glow
	return material


func _build_ground_and_roads() -> void:
	_add_solid_box(self, "CityGround", Vector3(0, -0.18, 0), Vector3(128, 0.36, 128), concrete)
	_add_solid_box(self, "MainAvenue", Vector3(0, 0.015, 0), Vector3(19, 0.05, 124), asphalt)
	for x in [-46.0, 46.0]:
		_add_solid_box(self, "SideStreet", Vector3(x, 0.015, 0), Vector3(9, 0.05, 124), asphalt)
	for z in [-43.0, 0.0, 43.0]:
		_add_solid_box(self, "CrossStreet", Vector3(0, 0.02, z), Vector3(124, 0.06, 12), asphalt)

	for x in [-12.0, 12.0]:
		_add_solid_box(self, "AvenueSidewalk", Vector3(x, 0.07, 0), Vector3(3.0, 0.16, 124), concrete)
	for x in [-51.0, -40.5, 40.5, 51.0]:
		_add_solid_box(self, "Sidewalk", Vector3(x, 0.06, 0), Vector3(1.2, 0.12, 124), concrete)
	for z in [-50.5, -35.5, -6.0, 6.0, 35.5, 50.5]:
		_add_solid_box(self, "CrosswalkSidewalk", Vector3(0, 0.06, z), Vector3(124, 0.12, 1.2), concrete)

	for dash in range(-11, 12):
		_add_visual_box(self, Vector3(-2.7, 0.052, dash * 4.7), Vector3(0.13, 0.018, 2.2), road_line)
		_add_visual_box(self, Vector3(2.7, 0.052, dash * 4.7), Vector3(0.13, 0.018, 2.2), road_line)
	for street_z in [-43.0, 0.0, 43.0]:
		for stripe in range(-3, 4):
			_add_visual_box(self, Vector3(stripe * 1.5, 0.058, street_z - 4.0), Vector3(0.8, 0.025, 3.2), road_line)
			_add_visual_box(self, Vector3(stripe * 1.5, 0.058, street_z + 4.0), Vector3(0.8, 0.025, 3.2), road_line)


func _build_buildings() -> void:
	var building_index := 0
	for side in [-1.0, 1.0]:
		for street_z in [-21.0, 21.0]:
			var x: float = side * 23.5
			var height: float = [12.0, 18.0, 15.0, 22.0][building_index % 4]
			var size := Vector3(15.0, height, 20.0)
			var material := _make_material(building_colors[building_index % building_colors.size()], 0.86)
			var building := _create_building("Building_%02d" % building_index, Vector3(x, 0, street_z), size, material, side)
			if building_index == 1:
				_add_store_sign(building, size, side)
			building_index += 1

		for street_z in [-21.0, 21.0]:
			var x: float = side * 52.0
			var height := 10.0 + float((building_index % 3) * 3)
			var size := Vector3(15.0, height, 20.0)
			var material := _make_material(building_colors[building_index % building_colors.size()], 0.86)
			_create_building("OuterBuilding_%02d" % building_index, Vector3(x, 0, street_z), size, material, side)
			building_index += 1

	for side in [-1.0, 1.0]:
		for street_z in [-57.0, 57.0]:
			var x := side * 23.5
			var size := Vector3(15.0, 11.0, 10.0)
			var material := _make_material(building_colors[building_index % building_colors.size()], 0.88)
			_create_building("CornerBuilding_%02d" % building_index, Vector3(x, 0, street_z), size, material, side)
			building_index += 1


func _create_building(building_name: String, ground_position: Vector3, size: Vector3, facade: StandardMaterial3D, road_side: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = building_name
	body.position = ground_position + Vector3.UP * (size.y * 0.5)
	body.collision_layer = 1
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_add_visual_box(body, Vector3.ZERO, size, facade)

	var window_x := -road_side * (size.x * 0.5 + 0.07)
	var floors := maxi(1, int(size.y / 4.5) - 1)
	for floor_index in range(floors):
		for window_column in range(3):
			var window_y := -size.y * 0.5 + 3.0 + floor_index * 4.1
			var window_z := -size.z * 0.5 + 3.5 + window_column * 5.8
			_add_visual_box(body, Vector3(window_x, window_y, window_z), Vector3(0.08, 1.65, 2.5), glass)
	return body


func _add_store_sign(building: StaticBody3D, size: Vector3, road_side: float) -> void:
	var sign := Label3D.new()
	sign.name = "StoreSign"
	sign.text = "TIENDA"
	sign.font_size = 48
	sign.pixel_size = 0.012
	sign.modulate = Color(1.0, 0.79, 0.35)
	sign.position = Vector3(-road_side * (size.x * 0.5 + 0.11), -size.y * 0.5 + 2.4, 0)
	sign.rotation.y = PI * 0.5 if road_side > 0.0 else -PI * 0.5
	building.add_child(sign)


func _build_street_lights() -> void:
	for z in range(-48, 57, 16):
		for side in [-1.0, 1.0]:
			_add_lamp(Vector3(side * 14.2, 0, float(z)))
	for x in [-39.0, 39.0]:
		for z in [-29, 0, 29]:
			_add_lamp(Vector3(x, 0, float(z)))


func _add_lamp(position: Vector3) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "StreetLightPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = 6.0
	pole.mesh = pole_mesh
	pole.material_override = metal
	pole.position = position + Vector3.UP * 3.0
	add_child(pole)

	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.2, 0.12, 0.12)
	arm.mesh = arm_mesh
	arm.material_override = metal
	arm.position = position + Vector3.UP * 5.8 + Vector3(0.45, 0, 0)
	add_child(arm)

	var lamp := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.48, 0.18, 0.34)
	lamp.mesh = lamp_mesh
	lamp.material_override = lamp_glow
	lamp.position = position + Vector3(0.85, 5.7, 0)
	add_child(lamp)

	if int(absf(position.z) + absf(position.x)) % 32 == 0:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.72, 0.42)
		light.light_energy = 0.65
		light.omni_range = 9.0
		light.shadow_enabled = false
		light.position = position + Vector3.UP * 5.3
		add_child(light)


func _build_trees() -> void:
	for z in [-48.0, -31.0, -14.0, 14.0, 31.0, 48.0]:
		for side in [-1.0, 1.0]:
			_add_tree(Vector3(side * 34.5, 0, z))


func _add_tree(position: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 2.3
	trunk.mesh = trunk_mesh
	trunk.material_override = bark
	trunk.position = position + Vector3.UP * 1.15
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.2
	crown_mesh.height = 2.2
	crown_mesh.radial_segments = 7
	crown_mesh.rings = 4
	crown.mesh = crown_mesh
	crown.material_override = foliage
	crown.position = position + Vector3.UP * 3.0
	add_child(crown)


func _build_cars_and_barriers() -> void:
	_add_car(Vector3(-6.0, 0, 19.0), Color(0.37, 0.13, 0.10))
	_add_car(Vector3(6.0, 0, -16.0), Color(0.17, 0.24, 0.31))
	_add_solid_box(self, "RoadBarrier", Vector3(-6.7, 0.65, -1.0), Vector3(1.0, 1.3, 4.0), metal)
	_add_visual_box(self, Vector3(-6.7, 1.38, -1.0), Vector3(1.04, 0.16, 4.05), road_line)


func _add_car(position: Vector3, paint: Color) -> void:
	var body_size := Vector3(2.6, 1.15, 5.4)
	var car_material := _make_material(paint, 0.42)
	var car := _add_solid_box(self, "AbandonedCar", position + Vector3.UP * 0.62, body_size, car_material)
	_add_visual_box(car, Vector3(0, 0.8, -0.1), Vector3(2.1, 0.8, 2.8), glass)
	for side in [-1.0, 1.0]:
		for axle_z in [-1.65, 1.65]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.43
			wheel_mesh.bottom_radius = 0.43
			wheel_mesh.height = 0.28
			wheel.mesh = wheel_mesh
			wheel.material_override = metal
			wheel.position = Vector3(side * 1.28, -0.1, axle_z)
			wheel.rotation.z = PI * 0.5
			car.add_child(wheel)


func _add_solid_box(parent: Node3D, box_name: String, position: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_add_visual_box(body, Vector3.ZERO, size, material)
	return body


func _add_visual_box(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance
