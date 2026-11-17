extends PanelContainer

const TOWER_SCRIPT = preload("res://Scripts/Scenes/Towers.gd")
const SPECIAL_CHARACTER_SCRIPT = preload("res://Scenes/special_characters.gd")

@onready var bones_label: Label = $HBoxContainer/ResourceContainer/ResourceList/BonesLabel
@onready var organs_label: Label = $HBoxContainer/ResourceContainer/ResourceList/OrgansLabel
@onready var eyeballs_label: Label = $HBoxContainer/ResourceContainer/ResourceList/EyeballsLabel
@onready var special_character_button: Button = $HBoxContainer/VBoxContainer/SpecialCharButton
@onready var special_timer_label: Label = $HBoxContainer/VBoxContainer/SpecialTimerContainer/SpecialTimerLabel
@onready var laser_button: Button = $HBoxContainer/TowerSelection/LaserButton
@onready var cannon_button: Button = $HBoxContainer/TowerSelection/CannonButton

var map: Node2D
var special_upgrade_button: Button

func _ready() -> void:
	map = get_tree().current_scene.get_node("Map")
	_create_special_upgrade_button()
	map.special_upgraded.connect(func(_level): _update_special_upgrade_button())

	ResourceManager.inventory_changed.connect(update_resources)
	update_resources(
		ResourceManager.bones,
		ResourceManager.organs,
		ResourceManager.eyeballs
	)
	
	laser_button.pressed.connect(_on_laser_button_pressed)
	cannon_button.pressed.connect(_on_cannon_button_pressed)

	special_character_button.pressed.connect(_on_special_character_button_pressed)

func _process(_delta: float) -> void:
	_update_special_timer_display()

func update_resources(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	bones_label.text = "Bones: %d" % bone_amount
	organs_label.text = "Organs: %d" % organ_amount
	eyeballs_label.text = "Eyeballs: %d" % eyeball_amount
	_update_build_button(laser_button, "Laser Tower", TOWER_SCRIPT.TowerType.LASER)
	_update_build_button(cannon_button, "Heavy Cannon", TOWER_SCRIPT.TowerType.HEAVY_CANNON)
	_update_special_upgrade_button()


# Shows the price on the button and greys it out when the player can't pay,
# otherwise a refused build looks like a broken button.
func _update_build_button(button: Button, title: String, type: int) -> void:
	var cost = TOWER_SCRIPT.build_cost_for(type)
	button.text = "%s\n%s" % [title, format_cost(cost)]
	button.disabled = not ResourceManager.can_afford(
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	)


static func format_cost(cost: Dictionary, separator: String = ", ") -> String:
	var parts = []

	if cost["bones"] > 0:
		parts.append("%d Bones" % cost["bones"])
	if cost["organs"] > 0:
		parts.append("%d Organs" % cost["organs"])
	if cost["eyeballs"] > 0:
		parts.append("%d Eyes" % cost["eyeballs"])

	return separator.join(parts)

# Built in code so both levels' HUDs get it without editing each scene.
func _create_special_upgrade_button() -> void:
	special_upgrade_button = Button.new()
	special_upgrade_button.custom_minimum_size = Vector2(120, 90)
	special_upgrade_button.add_theme_font_size_override("font_size", 13)
	special_upgrade_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	special_upgrade_button.pressed.connect(_on_special_upgrade_button_pressed)

	# Sits right after the special character column.
	var special_column = special_character_button.get_parent()
	var row = special_column.get_parent()
	row.add_child(special_upgrade_button)
	row.move_child(special_upgrade_button, special_column.get_index() + 1)

	# Make room for the extra button without pushing the bar off the left edge.
	row.add_theme_constant_override("separation", 10)
	grow_horizontal = Control.GROW_DIRECTION_END


func _update_special_upgrade_button() -> void:
	if special_upgrade_button == null or not is_instance_valid(map):
		return

	if map.is_special_max_level():
		special_upgrade_button.text = "Special\nMAX LEVEL"
		special_upgrade_button.tooltip_text = "Your special character is fully upgraded."
		special_upgrade_button.disabled = true
		return

	var next_level = map.special_level + 1
	var cost = map.get_special_upgrade_cost()
	special_upgrade_button.text = "Upgrade Lv %d\n%s" % [next_level, format_cost(cost, "\n")]
	special_upgrade_button.tooltip_text = "Level %d: %s\nApplies from the next deployment." % [
		next_level, SPECIAL_CHARACTER_SCRIPT.UPGRADE_SUMMARIES[next_level]
	]
	special_upgrade_button.disabled = not ResourceManager.can_afford(
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	)


func _on_special_upgrade_button_pressed() -> void:
	if is_instance_valid(map):
		map.upgrade_special()


func _on_special_character_button_pressed() -> void:
	map.begin_special_placement()

func _update_special_timer_display() -> void:
	if not is_instance_valid(map):
		return

	if map.choosing_deployment_location:
		special_timer_label.text = "DEPLOYING"

	elif map.can_deploy_special:
		special_timer_label.text = "READY!"

	elif map.deployment_start_timer.time_left > 0:
		var remaining = map.deployment_start_timer.time_left
		special_timer_label.text = "Initial Delay: %.1f s" % remaining

	elif map.special_cooldown_timer.time_left > 0:
		var remaining = map.special_cooldown_timer.time_left
		special_timer_label.text = "Cooldown: %.1f s" % remaining

	else:
		special_timer_label.text = "Special Character: NOT READY"


func _on_laser_button_pressed() -> void:
	if is_instance_valid(map):
		map.build_laser_on_selected_spot()


func _on_cannon_button_pressed() -> void:
	if is_instance_valid(map):
		map.build_cannon_on_selected_spot()
