extends Node
## Loads bundled CC0 PBR maps synchronously so textures are present from the
## first rendered frame and never depend on HTTP, CORS, or player movement.

const TEXTURE_ROOT := "res://assets/textures/environment/"
const TEXTURE_SETS := {
	"asphalt_02": {
		"albedo": "asphalt_02_diff_1k.jpg",
		"normal": "asphalt_02_nor_gl_1k.jpg",
		"roughness": "asphalt_02_rough_1k.jpg",
	},
	"concrete_wall_009": {
		"albedo": "concrete_wall_009_diff_1k.jpg",
		"normal": "concrete_wall_009_nor_gl_1k.jpg",
		"roughness": "concrete_wall_009_rough_1k.jpg",
	},
	"rusty_metal_sheet": {
		"albedo": "rusty_metal_sheet_diff_1k.jpg",
		"normal": "rusty_metal_sheet_nor_gl_1k.jpg",
		"roughness": "rusty_metal_sheet_rough_1k.jpg",
	},
}

var material_groups: Dictionary = {}


func configure(groups: Dictionary) -> void:
	material_groups = groups
	_apply_bundled_maps()


func _apply_bundled_maps() -> void:
	for texture_set_name in TEXTURE_SETS:
		var map_paths: Dictionary = TEXTURE_SETS[texture_set_name]
		var maps: Dictionary = {}
		for map_kind in map_paths:
			var texture_path := TEXTURE_ROOT + map_paths[map_kind]
			var texture := load(texture_path) as Texture2D
			if texture == null:
				push_error("Could not load bundled PBR texture: %s" % texture_path)
				continue
			maps[map_kind] = texture
		_apply_maps(material_groups.get(texture_set_name, []), maps)


func _apply_maps(materials: Array, maps: Dictionary) -> void:
	for material in materials:
		if not is_instance_valid(material):
			continue
		if maps.has("albedo"):
			material.albedo_texture = maps["albedo"]
		if maps.has("normal"):
			material.normal_enabled = true
			material.normal_texture = maps["normal"]
		if maps.has("roughness"):
			material.roughness_texture = maps["roughness"]
			material.roughness = 1.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		material.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
