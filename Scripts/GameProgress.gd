extends Node

const SAVE_PATH: String = "user://progress.cfg"
const SPECIAL_CHARACTER_SCRIPT = preload("res://Scenes/special_characters.gd")

# Sucream earned each time a level is beaten, keyed by the level's scene.
const LEVEL_REWARDS: Dictionary = {
	"res://Scenes/main.tscn": 50,
	"res://Scenes/Level2.tscn": 75,
}
const DEFAULT_LEVEL_REWARD: int = 50

signal sucream_changed(amount: int)
signal special_upgraded(level: int)

var level_2_unlocked: bool = false
var sucream: int = 0
var special_level: int = 1


func _ready() -> void:
	load_progress()


func unlock_level_2() -> void:
	level_2_unlocked = true
	save_progress()


func reward_for_level(scene_path: String) -> int:
	return LEVEL_REWARDS.get(scene_path, DEFAULT_LEVEL_REWARD)


# Called by the victory screen. Returns the amount earned so it can be shown.
func award_level_reward(scene_path: String) -> int:
	var amount := reward_for_level(scene_path)
	sucream += amount
	save_progress()
	sucream_changed.emit(sucream)
	return amount


func is_special_max_level() -> bool:
	return special_level >= SPECIAL_CHARACTER_SCRIPT.MAX_LEVEL


# 0 when the special character is already at max level.
func special_upgrade_cost() -> int:
	return SPECIAL_CHARACTER_SCRIPT.upgrade_cost_for(special_level + 1)


func can_upgrade_special() -> bool:
	return not is_special_max_level() and sucream >= special_upgrade_cost()


func upgrade_special() -> bool:
	if not can_upgrade_special():
		return false

	sucream -= special_upgrade_cost()
	special_level += 1
	save_progress()
	sucream_changed.emit(sucream)
	special_upgraded.emit(special_level)
	return true


func save_progress() -> void:
	var config := ConfigFile.new()

	config.set_value("Progress", "level_2_unlocked", level_2_unlocked)
	config.set_value("Progress", "sucream", sucream)
	config.set_value("Progress", "special_level", special_level)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_error("Failed to save game progress.")


func load_progress() -> void:
	var config := ConfigFile.new()

	var error := config.load(SAVE_PATH)

	if error == OK:
		level_2_unlocked = config.get_value("Progress", "level_2_unlocked", false)
		sucream = config.get_value("Progress", "sucream", 0)
		special_level = clampi(
			config.get_value("Progress", "special_level", 1),
			1,
			SPECIAL_CHARACTER_SCRIPT.MAX_LEVEL
		)
	else:
		level_2_unlocked = false
		sucream = 0
		special_level = 1
