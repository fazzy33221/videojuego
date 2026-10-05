extends Control

signal new_game_requested
signal continue_requested
signal options_changed(master_volume: float, camera_sensitivity: float)

const SETTINGS_PATH := "user://settings.cfg"

@onready var menu_content: VBoxContainer = $CenterContainer/MenuContent

var _continue_button: Button
var _controls_page: Control
var _options_page: Control
var _volume_slider: HSlider
var _sensitivity_slider: HSlider
var master_volume_percent: float = 80.0
var camera_sensitivity: float = 0.0025


func _ready() -> void:
	$CenterContainer/MenuContent/NewGameButton.pressed.connect(_on_new_game_pressed)
	_load_settings()
	_add_menu_actions()
	_build_controls_page()
	_build_options_page()
	_apply_settings()
	set_continue_available(FileAccess.file_exists("user://continue.cfg"))


func set_continue_available(available: bool) -> void:
	if is_instance_valid(_continue_button):
		_continue_button.visible = available


func _add_menu_actions() -> void:
	_continue_button = _create_button("ContinueButton", "CONTINUAR")
	_continue_button.pressed.connect(_on_continue_pressed)
	menu_content.add_child(_continue_button)
	_continue_button.visible = false

	var options_button := _create_button("OptionsButton", "OPCIONES")
	options_button.pressed.connect(_show_options_page)
	menu_content.add_child(options_button)

	var controls_button := _create_button("ControlsButton", "CONTROLES")
	controls_button.pressed.connect(_show_controls_page)
	menu_content.add_child(controls_button)


func _build_controls_page() -> void:
	_controls_page = _create_page("ControlsPage")
	var content := _create_page_content(_controls_page)
	content.add_child(_create_heading("CONTROLES"))
	var instructions := Label.new()
	instructions.custom_minimum_size = Vector2(360, 170)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.add_theme_color_override("font_color", Color(0.84, 0.88, 0.86, 1))
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.text = "ANDROID\nPalanca izquierda: moverse\nArrastrar lado derecho: mirar\nBotones: correr, saltar y linterna\n\nPC\nWASD o flechas: moverse\nRatón: mirar | Shift: correr\nEspacio: saltar | F: linterna"
	content.add_child(instructions)
	var back_button := _create_button("ControlsBackButton", "VOLVER")
	back_button.pressed.connect(_show_main_page)
	content.add_child(back_button)
	add_child(_controls_page)


func _build_options_page() -> void:
	_options_page = _create_page("OptionsPage")
	var content := _create_page_content(_options_page)
	content.add_child(_create_heading("OPCIONES"))

	var volume_label := _create_option_label("Volumen")
	content.add_child(volume_label)
	_volume_slider = HSlider.new()
	_volume_slider.custom_minimum_size = Vector2(300, 36)
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 1
	_volume_slider.value = master_volume_percent
	_volume_slider.value_changed.connect(_on_volume_changed)
	content.add_child(_volume_slider)

	var sensitivity_label := _create_option_label("Sensibilidad de cámara")
	content.add_child(sensitivity_label)
	_sensitivity_slider = HSlider.new()
	_sensitivity_slider.custom_minimum_size = Vector2(300, 36)
	_sensitivity_slider.min_value = 0.001
	_sensitivity_slider.max_value = 0.006
	_sensitivity_slider.step = 0.0005
	_sensitivity_slider.value = camera_sensitivity
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	content.add_child(_sensitivity_slider)

	var back_button := _create_button("OptionsBackButton", "VOLVER")
	back_button.pressed.connect(_show_main_page)
	content.add_child(back_button)
	add_child(_options_page)


func _create_page(page_name: String) -> Control:
	var page := Control.new()
	page.name = page_name
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return page


func _create_page_content(page: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)
	return content


func _create_heading(value: String) -> Label:
	var heading := Label.new()
	heading.text = value
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.91, 0.82, 0.58, 1))
	heading.add_theme_font_size_override("font_size", 34)
	return heading


func _create_option_label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.86, 1))
	label.add_theme_font_size_override("font_size", 18)
	return label


func _create_button(button_name: String, button_text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	button.custom_minimum_size = Vector2(280, 58)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	master_volume_percent = float(settings.get_value("audio", "master_volume", 80.0))
	camera_sensitivity = float(settings.get_value("camera", "sensitivity", 0.0025))


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "master_volume", master_volume_percent)
	settings.set_value("camera", "sensitivity", camera_sensitivity)
	settings.save(SETTINGS_PATH)


func _apply_settings() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var volume := master_volume_percent / 100.0
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(volume, 0.0001)))
	options_changed.emit(master_volume_percent, camera_sensitivity)


func _on_volume_changed(value: float) -> void:
	master_volume_percent = value
	_save_settings()
	_apply_settings()


func _on_sensitivity_changed(value: float) -> void:
	camera_sensitivity = value
	_save_settings()
	_apply_settings()


func _show_controls_page() -> void:
	menu_content.hide()
	_options_page.hide()
	_controls_page.show()


func _show_options_page() -> void:
	menu_content.hide()
	_controls_page.hide()
	_options_page.show()


func _show_main_page() -> void:
	_controls_page.hide()
	_options_page.hide()
	menu_content.show()


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_continue_pressed() -> void:
	continue_requested.emit()
