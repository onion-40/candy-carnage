
extends Node

const SAVE_PATH: String = "user://progress.cfg"

var level_2_unlocked: bool = false


func _ready() -> void:
	load_progress()


func unlock_level_2() -> void:
	level_2_unlocked = true
	save_progress()


func save_progress() -> void:
	var config := ConfigFile.new()

	config.set_value("Progress", "level_2_unlocked", level_2_unlocked)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_error("Failed to save game progress.")


func load_progress() -> void:
	var config := ConfigFile.new()

	var error := config.load(SAVE_PATH)

	if error == OK:
		level_2_unlocked = config.get_value(
			"Progress",
			"level_2_unlocked",
			false
		)
	else:
		level_2_unlocked = false
