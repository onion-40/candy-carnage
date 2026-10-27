
extends Node2D

enum TowerType {
	LASER,
	HEAVY_CANNON
}

@export var tower_type: TowerType = TowerType.LASER

var level: int = 1
var attack_range: float
var damage: int
var attack_interval: float
var is_sold: bool = false
var build_spot: Area2D

@onready var attack_timer: Timer = $AttackTimer
@onready var body: Polygon2D = $Body


func _ready() -> void:
	if body.polygon.is_empty():
		body.polygon = PackedVector2Array([
			Vector2(-15, -15),
			Vector2(15, -15),
			Vector2(15, 15),
			Vector2(-15, 15)
		])

	apply_stats()

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()


func get_build_cost() -> Dictionary:
	var cost = {}

	match tower_type:
		TowerType.LASER:
			cost = {
				"bones": 15,
				"organs": 5,
				"eyeballs": 0
			}

		TowerType.HEAVY_CANNON:
			cost = {
				"bones": 25,
				"organs": 7,
				"eyeballs": 0
			}

	return cost


func get_upgrade_cost() -> Dictionary:
	var cost = {
		"bones": 0,
		"organs": 0,
		"eyeballs": 0
	}

	if level == 1:
		if tower_type == TowerType.LASER:
			cost = {
				"bones": 15,
				"organs": 10,
				"eyeballs": 0
			}
		else:
			cost = {
				"bones": 35,
				"organs": 12,
				"eyeballs": 0
			}

	elif level == 2:
		if tower_type == TowerType.LASER:
			cost = {
				"bones": 20,
				"organs": 15,
				"eyeballs": 0
			}
		else:
			cost = {
				"bones": 50,
				"organs": 18,
				"eyeballs": 2
			}

	return cost


func upgrade() -> bool:
	var success = false

	if level < 3:
		var cost = get_upgrade_cost()

		if ResourceManager.spend_resources(
			cost["bones"],
			cost["organs"],
			cost["eyeballs"]
		):
			level += 1
			apply_stats()
			success = true

	return success


func sell() -> void:
	if not is_sold:
		is_sold = true

		var cost = get_build_cost()

		ResourceManager.add_resources(
			int(cost["bones"] / 2),
			int(cost["organs"] / 2),
			int(cost["eyeballs"] / 2)
		)

		if is_instance_valid(build_spot):
			build_spot.set_meta("occupied", false)

		queue_free()


func apply_stats() -> void:
	if tower_type == TowerType.LASER:
		attack_range = 220.0 + (level - 1) * 20.0
		damage = 8 + (level - 1) * 5
		attack_interval = 0.6
		body.color = Color(0.1, 0.4, 1.0)

	elif tower_type == TowerType.HEAVY_CANNON:
		attack_range = 150.0 + (level - 1) * 10.0
		damage = 25 + (level - 1) * 15
		attack_interval = 1.5
		body.color = Color(1.0, 0.2, 0.1)
	else:
		return

	attack_timer.wait_time = attack_interval


func _on_attack_timer_timeout() -> void:
	var target = find_nearest_enemy()

	if target != null:
		target.take_damage(damage)


func find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance: float = attack_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(
			enemy.global_position
		)

		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

func _on_selection_area_input_event(
	viewport: Node,
	event: InputEvent,
	shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Tower clicked: ", name)

			get_tree().call_group("tower_selection", "select_tower", self)
