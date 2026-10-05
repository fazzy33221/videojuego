extends Node3D

@export var act_title: String = ""
@export var act_hint: String = ""
@export var next_level: PackedScene


func _ready() -> void:
	_create_map_collisions()
	$ExitTrigger.body_entered.connect(_on_exit_body_entered)
	_bake_navigation_if_needed()


func _create_map_collisions() -> void:
	var map_root := get_node_or_null("ReformaEnvironment/MapGeometry") as Node3D
	if map_root == null:
		return

	for node in map_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var shape := mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			continue

		var collision_body := StaticBody3D.new()
		collision_body.name = "GeneratedCollision"
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = shape
		collision_body.add_child(collision_shape)
		mesh_instance.add_child(collision_body)


func _bake_navigation_if_needed() -> void:
	var navigation_region := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if navigation_region == null or navigation_region.navigation_mesh == null:
		return
	if navigation_region.navigation_mesh.get_polygon_count() == 0:
		navigation_region.bake_navigation_mesh()


func _on_exit_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game_manager", "advance_to", next_level)