extends Node3D

@export var act_title: String = ""
@export var act_hint: String = ""
@export var next_level: PackedScene


func _ready() -> void:
	_create_map_collisions()
	$ExitTrigger.body_entered.connect(_on_exit_body_entered)
	await _bake_navigation_if_needed()


func _create_map_collisions() -> void:
	var map_root := get_node_or_null("MetroEnvironment/MapGeometry") as Node3D
	if map_root == null:
		return
	if map_root.has_node("GeneratedMapCollision"):
		return

	var collision_body := StaticBody3D.new()
	collision_body.name = "GeneratedMapCollision"
	collision_body.collision_layer = 1
	collision_body.collision_mask = 0
	map_root.add_child(collision_body)

	var inverse_map_transform := map_root.global_transform.affine_inverse()
	for node in map_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		if _has_static_body_ancestor(mesh_instance, map_root):
			continue
		var shape := mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			push_error("Could not create a static collision shape for map mesh: %s" % mesh_instance.get_path())
			continue

		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "MapCollisionShape"
		collision_shape.shape = shape
		collision_body.add_child(collision_shape)
		collision_shape.transform = inverse_map_transform * mesh_instance.global_transform


func _has_static_body_ancestor(node: Node, stop_node: Node) -> bool:
	var ancestor := node.get_parent()
	while ancestor != null and ancestor != stop_node:
		if ancestor is StaticBody3D:
			return true
		ancestor = ancestor.get_parent()
	return false


func _bake_navigation_if_needed() -> void:
	var navigation_region := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if navigation_region == null or navigation_region.navigation_mesh == null:
		return
	if navigation_region.navigation_mesh.get_polygon_count() == 0:
		await get_tree().physics_frame
		navigation_region.bake_navigation_mesh(true)
		await get_tree().physics_frame


func _on_exit_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game_manager", "advance_to", next_level)