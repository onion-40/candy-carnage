extends PathFollow2D

const BODY_PART_SCRIPT = preload("res://Scripts/Scenes/BodyPart.gd")

signal defeated(reward: int)
signal reached_base(damage: int)

@export var max_health: int = 75
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
		var bone_amount = randi_range(3, 8)
		_spawn_body_part(bone_amount, 0, 0)

	elif roll <= 95:
		var organ_amount = randi_range(1, 4)
		_spawn_body_part(0, organ_amount, 0)

	else:
		var eyeball_amount = randi_range(1, 2)
		_spawn_body_part(0, 0, eyeball_amount)


# The loot drops on the ground; the player clicks it to collect (BodyPart.gd).
func _spawn_body_part(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	var part = BODY_PART_SCRIPT.new()
	part.bones = bone_amount
	part.organs = organ_amount
	part.eyeballs = eyeball_amount

	# The Body polygon is drawn offset from the node origin, so drop the
	# part where the enemy is actually visible.
	var body: Polygon2D = $Body
	var center = Vector2.ZERO

	for point in body.polygon:
		center += point

	center /= body.polygon.size()

	var scene = get_tree().current_scene
	part.position = scene.to_local(body.to_global(center))
	scene.add_child.call_deferred(part)
