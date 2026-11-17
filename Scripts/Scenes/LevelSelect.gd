extends Control

@onready var level_1_button: Button = $CenterContainer/VBoxContainer/LevelButtons/Level1Button
@onready var level_2_button: Button = $CenterContainer/VBoxContainer/LevelButtons/Level2Button
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready() -> void:
	level_1_button.pressed.connect(_on_level_1_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Level 2 is not available yet.
	level_2_button.disabled = true


func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
