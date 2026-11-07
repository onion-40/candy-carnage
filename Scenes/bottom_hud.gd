
extends PanelContainer

@onready var bones_label: Label = $HBoxContainer/ResourceList/BonesLabel
@onready var organs_label: Label = $HBoxContainer/ResourceList/OrgansLabel
@onready var eyeballs_label: Label = $HBoxContainer/ResourceList/EyeballsLabel
@onready var hp_label: Label = $HBoxContainer/ResourceList/HPLabel
@onready var laser_button: Button = $HBoxContainer/TowerSelection/LaserButton
@onready var cannon_button: Button = $HBoxContainer/TowerSelection/CannonButton
@onready var special_button: Button = $HBoxContainer/TowerSelection/SpecialButton

var map: Node = null


func _ready() -> void:
	ResourceManager.inventory_changed.connect(update_resources)
	update_resources(
		ResourceManager.bones,
		ResourceManager.organs,
		ResourceManager.eyeballs
	)

	# Map is an earlier sibling of UI, so it is already ready here.
	map = owner.get_node_or_null("Map")

	# Laser / Cannon act as a radio group: the pressed one is what a spot click builds.
	var tower_group = ButtonGroup.new()

	for button in [laser_button, cannon_button]:
		button.toggle_mode = true
		button.button_group = tower_group

	laser_button.button_pressed = true
	laser_button.pressed.connect(_on_tower_button_pressed.bind(0))
	cannon_button.pressed.connect(_on_tower_button_pressed.bind(1))
	special_button.pressed.connect(_on_special_button_pressed)

	if map:
		map.player_health_changed.connect(update_hp)
		update_hp(map.player_hp, map.max_player_hp)


func _process(_delta: float) -> void:
	if map == null:
		return

	if map.choosing_deployment_location:
		special_button.disabled = true
		special_button.text = "Special\nClick the map"
	elif map.can_deploy_special:
		special_button.disabled = false
		special_button.text = "Special\nReady!"
	else:
		special_button.disabled = true
		special_button.text = "Special\n%ds" % ceili(_special_time_left())


func update_resources(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	bones_label.text = "Bones: %d" % bone_amount
	organs_label.text = "Organs: %d" % organ_amount
	eyeballs_label.text = "Eyeballs: %d" % eyeball_amount


func update_hp(current_hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]


func _on_tower_button_pressed(type: int) -> void:
	if map:
		map.set_build_type(type)


func _on_special_button_pressed() -> void:
	if map:
		map.begin_special_placement()


func _special_time_left() -> float:
	if not map.deployment_start_timer.is_stopped():
		return map.deployment_start_timer.time_left

	return map.special_cooldown_timer.time_left
