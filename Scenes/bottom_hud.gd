extends PanelContainer

const TOWER_SCRIPT = preload("res://Scripts/Scenes/Towers.gd")

@onready var bones_label: Label = $HBoxContainer/ResourceContainer/ResourceList/BonesLabel
@onready var organs_label: Label = $HBoxContainer/ResourceContainer/ResourceList/OrgansLabel
@onready var eyeballs_label: Label = $HBoxContainer/ResourceContainer/ResourceList/EyeballsLabel
@onready var special_character_button: Button = $HBoxContainer/VBoxContainer/SpecialCharButton
@onready var special_timer_label: Label = $HBoxContainer/VBoxContainer/SpecialTimerContainer/SpecialTimerLabel
@onready var laser_button: Button = $HBoxContainer/TowerSelection/LaserButton
@onready var cannon_button: Button = $HBoxContainer/TowerSelection/CannonButton

var map: Node2D
var cooldown_fill: ProgressBar

func _ready() -> void:
	ResourceManager.inventory_changed.connect(update_resources)
	update_resources(
		ResourceManager.bones,
		ResourceManager.organs,
		ResourceManager.eyeballs
	)
	
	laser_button.pressed.connect(_on_laser_button_pressed)
	cannon_button.pressed.connect(_on_cannon_button_pressed)

	special_character_button.pressed.connect(_on_special_character_button_pressed)
	map = get_tree().current_scene.get_node("Map")
	_create_cooldown_fill()


# A pink fill rises over the special button while it recharges, and the
# button glows once it is ready: players could not read the timer text alone.
func _create_cooldown_fill() -> void:
	special_character_button.icon = preload("res://Assets/Sprites/hero_icon.png")

	cooldown_fill = ProgressBar.new()
	cooldown_fill.show_percentage = false
	cooldown_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_fill.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	cooldown_fill.max_value = 1.0
	cooldown_fill.step = 0.0

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(1, 0.45, 0.75, 0.4)
	cooldown_fill.add_theme_stylebox_override("fill", fill)
	cooldown_fill.add_theme_stylebox_override("background", StyleBoxEmpty.new())

	special_character_button.add_child(cooldown_fill)
	cooldown_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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


static func format_cost(cost: Dictionary) -> String:
	var parts = []

	if cost["bones"] > 0:
		parts.append("%d Bones" % cost["bones"])
	if cost["organs"] > 0:
		parts.append("%d Organs" % cost["organs"])
	if cost["eyeballs"] > 0:
		parts.append("%d Eyes" % cost["eyeballs"])

	return ", ".join(parts)

func _on_special_character_button_pressed() -> void:
	map.begin_special_placement()

func _update_special_timer_display() -> void:
	if not is_instance_valid(map):
		return

	_update_cooldown_fill()

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


func _update_cooldown_fill() -> void:
	var charge = 1.0

	if not map.can_deploy_special:
		charge = 0.0

		for timer in [map.deployment_start_timer, map.special_cooldown_timer]:
			if timer.time_left > 0.0:
				charge = 1.0 - timer.time_left / timer.wait_time

	cooldown_fill.value = charge
	cooldown_fill.visible = charge < 1.0
	special_character_button.disabled = not map.can_deploy_special

	var glow = 0.0

	if map.can_deploy_special and not map.choosing_deployment_location:
		glow = (sin(Time.get_ticks_msec() / 180.0) + 1.0) / 2.0

	special_character_button.modulate = Color.WHITE.lerp(Color(1.35, 1.2, 0.7), glow)


func _on_laser_button_pressed() -> void:
	if is_instance_valid(map):
		map.build_laser_on_selected_spot()


func _on_cannon_button_pressed() -> void:
	if is_instance_valid(map):
		map.build_cannon_on_selected_spot()
