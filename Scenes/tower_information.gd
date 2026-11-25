extends PanelContainer

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var tower_name_label: Label = $VBoxContainer/TowerName
@onready var tower_level_label: Label = $VBoxContainer/TowerLevel
@onready var tower_stats_label: Label = $VBoxContainer/TowerStats
@onready var upgrade_cost_container: VBoxContainer = $VBoxContainer/UpgradeCostContainer
@onready var upgrade_cost_title: Label = $VBoxContainer/UpgradeCostContainer/UpgradeCost
@onready var bones_container: HBoxContainer = $VBoxContainer/UpgradeCostContainer/ResourceList/BonesContainer
@onready var organs_container: HBoxContainer = $VBoxContainer/UpgradeCostContainer/ResourceList/OrgansContainer
@onready var eyeballs_container: HBoxContainer = $VBoxContainer/UpgradeCostContainer/ResourceList/EyeballsContainer
@onready var bones_amount: Label = $VBoxContainer/UpgradeCostContainer/ResourceList/BonesContainer/BonesAmount
@onready var organs_amount: Label = $VBoxContainer/UpgradeCostContainer/ResourceList/OrgansContainer/OrgansAmount
@onready var eyeballs_amount: Label = $VBoxContainer/UpgradeCostContainer/ResourceList/EyeballsContainer/EyeballsAmount
@onready var upgrade_button: Button = $VBoxContainer/UpgradeButton
@onready var sell_button: Button = $VBoxContainer/SellButton
@onready var repair_button: Button = $VBoxContainer/RepairButton
@onready var repair_progress_bar: ProgressBar = $VBoxContainer/RepairProgressBar

const REPAIR_TEXT: String = "REPAIR (6 s, no attacks)"

var selected_tower: Node2D = null


func _ready() -> void:
	add_to_group("tower_selection")
	hide()

	close_button.pressed.connect(_on_close_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	repair_button.pressed.connect(_on_repair_pressed)

	# Loot picked up while the panel is open can make the upgrade affordable.
	ResourceManager.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed(_bones: int, _organs: int, _eyeballs: int) -> void:
	if visible:
		_refresh_panel()

func _on_close_pressed() -> void:
	_set_selected_tower(null)
	hide()


# Any click outside the panel closes it (the panel itself eats its own clicks).
# Clicking another tower still works: it selects it again right after.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		_on_close_pressed()

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
	repair_button.text = REPAIR_TEXT

	if is_instance_valid(selected_tower) and selected_tower.has_method("set_range_visible"):
		selected_tower.set_range_visible(true)


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

	# Show what the next upgrade gives, next to the current values.
	if selected_tower.level < 3:
		var next = selected_tower.stats_for(selected_tower.tower_type, selected_tower.level + 1)
		tower_stats_label.text = "Damage: %d → %d\nRange: %d → %d\nAttack Interval: %.1fs" % [
			selected_tower.damage,
			next["damage"],
			selected_tower.attack_range,
			next["attack_range"],
			selected_tower.attack_interval
		]

	if selected_tower.level >= 3:
		upgrade_cost_title.text = "Max level reached"
		upgrade_cost_container.get_node("ResourceList").hide()
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true
		return

	var cost = selected_tower.get_upgrade_cost()
	upgrade_cost_container.get_node("ResourceList").show()
	_update_upgrade_cost_display(cost)

	# Greyed out when unaffordable, otherwise the click silently does nothing.
	var affordable = ResourceManager.can_afford(
		cost["bones"],
		cost["organs"],
		cost["eyeballs"]
	)
	upgrade_button.text = "UPGRADE TOWER" if affordable else "NOT ENOUGH RESOURCES"
	upgrade_button.disabled = not affordable

func _update_upgrade_cost_display(cost: Dictionary) -> void:
	upgrade_cost_title.text = "Upgrade Cost:"

	bones_amount.text = str(cost["bones"])
	organs_amount.text = str(cost["organs"])
	eyeballs_amount.text = str(cost["eyeballs"])

	# Hide resources that are not required.
	bones_container.visible = cost["bones"] > 0
	organs_container.visible = cost["organs"] > 0
	eyeballs_container.visible = cost["eyeballs"] > 0

func _process(_delta: float) -> void:
	if not is_instance_valid(selected_tower): return
	# Every frame: a repair ends on its own, and lifetime keeps dropping.
	repair_button.disabled = (
		selected_tower.is_repairing
		or selected_tower.time_left >= selected_tower.max_lifetime - 0.5
	)

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
		repair_button.text = REPAIR_TEXT

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

func _on_repair_pressed() -> void:
	if is_instance_valid(selected_tower):
		selected_tower.begin_repair()
