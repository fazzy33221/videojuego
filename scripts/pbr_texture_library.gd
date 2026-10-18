extends Node
## Loads CC0 PBR maps from Poly Haven once and caches them in user:// for later runs.

const CACHE_DIRECTORY := "user://pbr_cache"
const POLYHAVEN_BASE := "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k"
const MAP_SUFFIXES := {
	"albedo": "diff",
	"normal": "nor_gl",
	"roughness": "rough",
}

var material_groups: Dictionary = {}


func configure(groups: Dictionary) -> void:
	material_groups = groups
	_load_missing_maps()


func _load_missing_maps() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIRECTORY))
	var http := HTTPRequest.new()
	http.timeout = 20.0
	add_child(http)

	for asset_id in material_groups:
		var maps: Dictionary = {}
		for map_kind in MAP_SUFFIXES:
			var file_name := "%s_%s_1k.jpg" % [asset_id, MAP_SUFFIXES[map_kind]]
			var bytes := _read_cached(file_name)
			if bytes.is_empty():
				var url := "%s/%s/%s" % [POLYHAVEN_BASE, asset_id, file_name]
				var error := http.request(url)
				if error != OK:
					push_warning("PBR texture request failed (%s): %s" % [file_name, error])
					continue
				var response: Array = await http.request_completed
				if response[1] != 200 or response[3].is_empty():
					push_warning("PBR texture download failed: %s (HTTP %s)" % [file_name, response[1]])
					continue
				bytes = response[3]
				_write_cached(file_name, bytes)

			var image := Image.new()
			if image.load_jpg_from_buffer(bytes) != OK:
				push_warning("Could not decode PBR texture: %s" % file_name)
				continue
			maps[map_kind] = ImageTexture.create_from_image(image)

		_apply_maps(material_groups[asset_id], maps)

	http.queue_free()


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


func _read_cached(file_name: String) -> PackedByteArray:
	var path := "%s/%s" % [CACHE_DIRECTORY, file_name]
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_buffer(file.get_length()) if file != null else PackedByteArray()


func _write_cached(file_name: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open("%s/%s" % [CACHE_DIRECTORY, file_name], FileAccess.WRITE)
	if file != null:
		file.store_buffer(bytes)

