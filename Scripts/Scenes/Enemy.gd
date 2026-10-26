
extends PathFollow2D

signal defeated(reward: int)
signal reached_base(damage: int)

@export var max_health: int = 30
@export var move_speed: float = 100.0
@export var reward: int = 5
@export var base_damage: int = 1

var health: int


func _ready() -> void:
	health = max_health

	# Allows towers to find enemies.
	add_to_group("enemies")

	# Keep the enemy facing the same direction.
	loop = false
	rotates = false


func _process(delta: float) -> void:
	progress += move_speed * delta

	if progress_ratio >= 1.0:
		reached_base.emit(base_damage)
		queue_free()


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount

	if health <= 0:
		drop_random_resource()
		defeated.emit(reward)
		queue_free()


func drop_random_resource() -> void:
	var roll = randi_range(1, 100)

	if roll <= 60:
		# Common: bones (60% chance)
		var bone_amount = randi_range(3, 8)

		ResourceManager.add_resources(
			bone_amount,
			0,
			0
		)

	elif roll <= 95:
		# Common: organs (35% chance)
		var organ_amount = randi_range(1, 4)

		ResourceManager.add_resources(
			0,
			organ_amount,
			0
		)

	else:
		# Rare: eyeballs (5% chance)
		var eyeball_amount = randi_range(1, 2)

		ResourceManager.add_resources(
			0,
			0,
			eyeball_amount
		)
