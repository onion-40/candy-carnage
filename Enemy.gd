
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
	add_to_group("enemies")
	loop = false
	rotates = false

func _process(delta: float) -> void:
	progress += move_speed * delta

	if progress_ratio >= 1.0:
		reached_base.emit(base_damage)
		queue_free()

func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		defeated.emit(reward)
		queue_free()
