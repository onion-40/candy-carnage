
extends Node2D

@export var attack_range: float = 150.0
@export var attack_damage: int = 10
@export var attack_interval: float = 1.5

var is_active: bool = false
var attack_timer: float = 0.0


@export var lifetime: float = 10.0

func activate() -> void: 
	is_active = true
	attack_timer = 0.0
	print("Special character activated!")

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
		print("Attacked enemy! Damage dealt: ", attack_damage)
		print("Enemy HP after attack: ", nearest_enemy.health)
