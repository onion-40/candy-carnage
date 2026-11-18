extends Node2D

const MAX_LEVEL: int = 3

# Applied on top of the exported base stats below. Level 1 is the base character.
const LEVEL_STATS: Dictionary = {
	1: {"damage_mult": 1.0, "range_mult": 1.0, "lifetime_bonus": 0.0, "cooldown_reduction": 0.0},
	2: {"damage_mult": 1.5, "range_mult": 1.2, "lifetime_bonus": 0.0, "cooldown_reduction": 0.0},
	3: {"damage_mult": 2.0, "range_mult": 1.2, "lifetime_bonus": 5.0, "cooldown_reduction": 3.0},
}

# Sucream needed to reach each level. Upgrades are bought from the main menu
# (GameProgress.upgrade_special) and kept between runs.
const UPGRADE_COSTS: Dictionary = {
	2: 50,
	3: 100,
}

# Shown in the main menu upgrade screen.
const UPGRADE_SUMMARIES: Dictionary = {
	2: "+50% damage, +20% range",
	3: "x2 damage, +5 s duration, -3 s cooldown",
}

@export var attack_range: float = 150.0
@export var attack_damage: int = 10
@export var attack_interval: float = 1.5
@export var lifetime: float = 10.0

var level: int = 1
var is_active: bool = false
var attack_timer: float = 0.0


# Static so the Map and menus can read stats and prices without instancing a character.
static func stats_for_level(for_level: int) -> Dictionary:
	return LEVEL_STATS[clampi(for_level, 1, MAX_LEVEL)]


# 0 when there is no such level.
static func upgrade_cost_for(next_level: int) -> int:
	return UPGRADE_COSTS.get(next_level, 0)


# Call once on a fresh instance, before activate(): it scales the base stats.
func apply_level(new_level: int) -> void:
	level = clampi(new_level, 1, MAX_LEVEL)
	var stats := stats_for_level(level)

	attack_damage = roundi(attack_damage * stats["damage_mult"])
	attack_range *= stats["range_mult"]
	lifetime += stats["lifetime_bonus"]
	$AOEVisual.scale = Vector2.ONE * stats["range_mult"]


func activate() -> void:
	is_active = true
	attack_timer = 0.0

	await get_tree().create_timer(lifetime).timeout

	if is_instance_valid(self):
		queue_free()


func _process(delta: float) -> void:
	if not is_active:
		return

	attack_timer += delta

	if attack_timer >= attack_interval:
		attack_timer = 0.0
		attack_nearest_enemy()


func attack_nearest_enemy() -> void:
	var nearest_enemy: Node2D = null
	var nearest_distance: float = attack_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)

		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	if nearest_enemy != null:
		nearest_enemy.take_damage(attack_damage)
