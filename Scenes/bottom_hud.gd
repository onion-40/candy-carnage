extends PanelContainer

@onready var bones_label: Label = $HBoxContainer/ResourceList/BonesLabel
@onready var organs_label: Label = $HBoxContainer/ResourceList/OrgansLabel
@onready var eyeballs_label: Label = $HBoxContainer/ResourceList/EyeballsLabel
@onready var special_character_button: Button = $HBoxContainer/SpecialCharButton
@onready var special_timer_label: Label = $HBoxContainer/SpecialTimerContainer/SpecialTimerLabel
@onready var laser_button: Button = $HBoxContainer/TowerSelection/LaserButton
@onready var cannon_button: Button = $HBoxContainer/TowerSelection/CannonButton

var map: Node2D

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

func _on_special_character_button_pressed() -> void:
	map.begin_special_placement()

func _update_special_timer_display() -> void:
	if not is_instance_valid(map):
		return

	if map.choosing_deployment_location:
		special_timer_label.text = "Choose Deployment Location"

	elif map.can_deploy_special:
		special_timer_label.text = "Special Character: READY!"

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
