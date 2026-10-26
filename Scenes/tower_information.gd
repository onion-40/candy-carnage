extends PanelContainer

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var tower_name_label: Label = $VBoxContainer/TowerName
@onready var tower_level_label: Label = $VBoxContainer/TowerLevel
@onready var tower_stats_label: Label = $VBoxContainer/TowerStats
@onready var upgrade_cost_label: Label = $VBoxContainer/UpgradeCost
@onready var upgrade_button: Button = $VBoxContainer/UpgradeButton
@onready var sell_button: Button = $VBoxContainer/SellButton

var selected_tower: Node2D = null


func _ready() -> void:
	add_to_group("tower_selection")
	hide()

	close_button.pressed.connect(_on_close_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

func _on_close_pressed() -> void:
	selected_tower = null
	hide()

func select_tower(tower: Node2D) -> void:
	if not is_instance_valid(tower):
		return

	selected_tower = tower
	_refresh_panel()
	show()


func _refresh_panel() -> void:
	if not is_instance_valid(selected_tower):
		hide()
		return

	var tower_type_name = "Laser Tower"

	if selected_tower.tower_type == 1:
		tower_type_name = "Heavy Cannon"

	tower_name_label.text = tower_type_name
	tower_level_label.text = "Level %d / 3" % selected_tower.level
	tower_stats_label.text = "Damage: %d\nRange: %d\nAttack Interval: %.1fs" % [
		selected_tower.damage,
		selected_tower.attack_range,
		selected_tower.attack_interval
	]

	var cost = selected_tower.get_upgrade_cost()
	upgrade_cost_label.text = "Upgrade Cost:\n%d Bones, %d Organs, %d Eyeballs" % [
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	]

	upgrade_button.disabled = selected_tower.level >= 3


func _on_upgrade_pressed() -> void:
	if not is_instance_valid(selected_tower):
		return

	var map = get_tree().current_scene.get_node_or_null("Map")

	if map and map.has_method("upgrade_tower"):
		if map.upgrade_tower(selected_tower):
			_refresh_panel()


func _on_sell_pressed() -> void:
	if not is_instance_valid(selected_tower):
		return

	var map = get_tree().current_scene.get_node_or_null("Map")

	if map and map.has_method("sell_tower"):
		map.sell_tower(selected_tower)
		selected_tower = null
		hide()
