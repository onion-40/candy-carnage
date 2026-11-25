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

const BONE_SPIKES = [
	preload("res://Assets/Sprites/bone_bite_1.png"),
	preload("res://Assets/Sprites/bone_bite_2.png"),
	preload("res://Assets/Sprites/bone_bite_3.png"),
	preload("res://Assets/Sprites/bone_bite_4.png"),
	preload("res://Assets/Sprites/bone_bite_5.png"),
]
const BONE_COLOR: Color = Color(1.0, 0.92, 0.7)

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
	_show_shockwave()

	# The area keeps breathing while the character is active.
	var aoe: Polygon2D = $AOEVisual
	var pulse = aoe.create_tween().set_loops()
	pulse.tween_property(aoe, "modulate:a", 0.45, 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(aoe, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	await get_tree().create_timer(lifetime).timeout

	if is_instance_valid(self):
		# Fade out instead of popping out of existence.
		is_active = false
		var fade = create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.4)
		fade.tween_callback(queue_free)


# A bone-colored ring sweeps out to the edge of the attack range on landing.
func _show_shockwave() -> void:
	var ring = Line2D.new()
	ring.name = "Shockwave"
	ring.width = 6.0
	ring.default_color = BONE_COLOR
	ring.closed = true

	for i in range(40):
		ring.add_point(Vector2.RIGHT.rotated(TAU * i / 40.0) * attack_range)

	ring.scale = Vector2(0.1, 0.1)
	add_child(ring)

	var tween = ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(ring.queue_free)


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
		# Read the position first: a killed enemy frees itself.
		var target_position = nearest_enemy.global_position
		nearest_enemy.take_damage(attack_damage)
		_lunge_toward(target_position)
		_bone_bite(target_position)


# The hero hops toward the target and back.
func _lunge_toward(target_position: Vector2) -> void:
	var body: Sprite2D = $Body
	var reach = (target_position - global_position).limit_length(30.0)
	var tween = body.create_tween()
	tween.tween_property(body, "position", reach, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK)


# Signature ability: three bone spikes burst out of the ground under the
# target like a jaw, then sink back. Added to the map so they outlive the hero.
func _bone_bite(target_position: Vector2) -> void:
	var bite = Node2D.new()
	bite.name = "BoneSpikes"
	bite.z_index = 6
	get_parent().add_child(bite)
	bite.global_position = target_position + Vector2(0, 22) # at the enemy's feet

	for i in range(3):
		var spike = Sprite2D.new()
		spike.texture = BONE_SPIKES.pick_random()
		spike.centered = false
		spike.offset = Vector2(-spike.texture.get_width() / 2.0, -spike.texture.get_height())
		spike.position = Vector2((i - 1) * 22.0, 0)
		spike.rotation = (i - 1) * 0.35 # outer spikes lean in
		spike.scale = Vector2(1.0, 0.0)
		bite.add_child(spike)

		var grow = spike.create_tween()
		grow.tween_interval(i * 0.04)
		grow.tween_property(spike, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade = bite.create_tween()
	fade.tween_interval(0.45)
	fade.tween_property(bite, "modulate:a", 0.0, 0.25)
	fade.tween_callback(bite.queue_free)
