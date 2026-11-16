extends PanelContainer

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var tower_name_label: Label = $VBoxContainer/TowerName
@onready var tower_level_label: Label = $VBoxContainer/TowerLevel
@onready var tower_stats_label: Label = $VBoxContainer/TowerStats
@onready var upgrade_cost_label: Label = $VBoxContainer/UpgradeCost
@onready var upgrade_button: Button = $VBoxContainer/UpgradeButton
@onready var sell_button: Button = $VBoxContainer/SellButton
@onready var repair_button: Button = $VBoxContainer/RepairButton
@onready var repair_progress_bar: ProgressBar = $VBoxContainer/RepairProgressBar

var selected_tower: Node2D = null


func _ready() -> void:
	add_to_group("tower_selection")
	hide()

	close_button.pressed.connect(_on_close_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	repair_button.button_down.connect(_on_repair_button_down)
	repair_button.button_up.connect(_on_repair_button_up)

	# Loot picked up while the panel is open can make the upgrade affordable.
	ResourceManager.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed(_bones: int, _organs: int, _eyeballs: int) -> void:
	if visible:
		_refresh_panel()

func _on_close_pressed() -> void:
	_set_selected_tower(null)
	hide()

func select_tower(tower: Node2D) -> void:
	if not is_instance_valid(tower):
		return

	_set_selected_tower(tower)
	_refresh_panel()
	show()


# Only the selected tower shows its range circle.
func _set_selected_tower(tower: Node2D) -> void:
	if is_instance_valid(selected_tower) and selected_tower.has_method("set_range_visible"):
		selected_tower.set_range_visible(false)

	selected_tower = tower
	repair_progress_bar.value = 0
	repair_progress_bar.hide()
	repair_button.text = "HOLD TO REPAIR"

	if is_instance_valid(selected_tower) and selected_tower.has_method("set_range_visible"):
		selected_tower.set_range_visible(true)


func _refresh_panel() -> void:
	if not is_instance_valid(selected_tower):
		hide()
		return

	repair_button.disabled = (
		selected_tower.time_left >= selected_tower.max_lifetime
		or selected_tower.is_repairing
	)
	
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

	if selected_tower.level >= 3:
		upgrade_cost_label.text = "Max level reached"
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true
		return

	var cost = selected_tower.get_upgrade_cost()
	upgrade_cost_label.text = "Upgrade Cost:\n%d Bones, %d Organs, %d Eyeballs" % [
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	]

	# Greyed out when unaffordable, otherwise the click silently does nothing.
	var affordable = ResourceManager.can_afford(
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	)
	upgrade_button.text = "UPGRADE TOWER" if affordable else "NOT ENOUGH RESOURCES"
	upgrade_button.disabled = not affordable

func _process(_delta: float) -> void:
	if not is_instance_valid(selected_tower): return
	if selected_tower.is_repairing:
		var progress = (
			selected_tower.repair_held_time /
			selected_tower.repair_duration) * 100.0
		repair_progress_bar.value = clamp(progress, 0.0, 100.0)
		repair_progress_bar.show()
		repair_button.text = "REPAIRING..."
	else:
		repair_progress_bar.value = 0
		repair_progress_bar.hide()
		repair_button.text = "HOLD TO REPAIR"

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
		_set_selected_tower(null)
		hide()

func _on_repair_button_down() -> void:
	if is_instance_valid(selected_tower):
		selected_tower.begin_repair()


func _on_repair_button_up() -> void:
	if is_instance_valid(selected_tower):
		selected_tower.end_repair()

	repair_progress_bar.value = 0
	repair_progress_bar.hide()
	repair_button.text = "HOLD TO REPAIR"

	_refresh_panel()
