extends Control

signal new_game_requested


func _ready() -> void:
	$CenterContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)


func _on_new_game_pressed() -> void:
	new_game_requested.emit()
